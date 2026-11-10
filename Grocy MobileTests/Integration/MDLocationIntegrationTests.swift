//
//  MDLocationIntegrationTests.swift
//  Grocy MobileTests
//
//  Created by Georg Meißner on 11.11.26.
//

import Foundation
import SwiftData
import Testing

@testable import Grocy_Mobile

/// Exercises master data locations end to end against a real Grocy server:
/// `GrocyViewModel` → `GrocyApi` → Grocy REST API → `SwiftDataSynchronizer` → SwiftData.
///
/// Each test follows the same steps as `MDLocationsView` / `MDLocationFormView`:
/// write through the view model, then resync with `requestData(objects: [.locations])`.
@MainActor
@Suite(
    "Master data locations (Grocy server)",
    .tags(.integration),
    .serialized,
    .enabled(if: GrocyTestServer.isConfigured, GrocyTestServer.notConfiguredComment)
)
struct MDLocationIntegrationTests {
    let grocyVM: GrocyViewModel
    let container: ModelContainer
    let profileContainer: ModelContainer

    init() async throws {
        (grocyVM, container, profileContainer) = try await GrocyTestServer.makeLoggedInViewModel()
    }

    // MARK: - Connection & sync

    @Test("Logs in to a supported Grocy version")
    func connectsToSupportedServer() throws {
        let systemInfo = try #require(grocyVM.systemInfo)
        #expect(
            GrocyAPP.supportedVersions.contains(systemInfo.grocyVersion.version),
            "Grocy \(systemInfo.grocyVersion.version) is not in GrocyAPP.supportedVersions"
        )
    }

    @Test("Initial sync stores exactly the server's locations in SwiftData")
    func initialSyncMirrorsServer() async throws {
        try await syncLocations()

        let serverLocations: MDLocations = try await grocyVM.grocyApi.getObject(object: .locations)
        let stored = try storedLocations()

        #expect(stored.map(\.id) == serverLocations.map(\.id).sorted())
        #expect(grocyVM.mdLocations.map(\.id).sorted() == stored.map(\.id))
        for serverLocation in serverLocations {
            let storedLocation = try #require(stored.first { $0.id == serverLocation.id })
            #expect(storedLocation == serverLocation, "Location \(serverLocation.id) differs after sync")
        }
    }

    // MARK: - CRUD

    @Test("Creating a location stores it on the server and in SwiftData")
    func createLocation() async throws {
        try await withCleanup { cleanup in
            try await syncLocations()
            let location = MDLocation(
                id: try grocyVM.findNextID(.locations),
                name: uniqueName(),
                active: true,
                mdLocationDescription: "Created by MDLocationIntegrationTests",
                isFreezer: true
            )

            let response = try await grocyVM.postMDObject(object: .locations, content: location)
            cleanup.locationIDs.append(response.createdObjectID)
            #expect(response.createdObjectID == location.id)

            let serverLocation: MDLocation = try await grocyVM.grocyApi.getObjectWithID(object: .locations, id: location.id)
            expectSameContent(serverLocation, location)

            try await syncLocations()
            let stored = try #require(try storedLocation(id: location.id), "Created location was not synced into SwiftData")
            expectSameContent(stored, location)
            #expect(grocyVM.mdLocations.contains { $0.id == location.id })
        }
    }

    @Test("Editing a location updates it on the server and in SwiftData")
    func updateLocation() async throws {
        try await withCleanup { cleanup in
            let original = try await createLocationOnServer(cleanup: cleanup)
            let countBefore = try storedLocations().count

            let edited = MDLocation(
                id: original.id,
                name: uniqueName(),
                active: false,
                mdLocationDescription: "Edited by MDLocationIntegrationTests",
                isFreezer: !original.isFreezer,
                rowCreatedTimestamp: original.rowCreatedTimestamp
            )
            try await grocyVM.putMDObjectWithID(object: .locations, id: edited.id, content: edited)

            let serverLocation: MDLocation = try await grocyVM.grocyApi.getObjectWithID(object: .locations, id: edited.id)
            expectSameContent(serverLocation, edited)

            try await syncLocations()
            let stored = try #require(try storedLocation(id: edited.id))
            expectSameContent(stored, edited)
            #expect(try storedLocations().count == countBefore, "Editing must not insert a second row")
        }
    }

    @Test("Deleting a location removes it from the server and from SwiftData")
    func deleteLocation() async throws {
        let location = try await withCleanup { cleanup in
            try await createLocationOnServer(cleanup: cleanup)
        }
        // withCleanup already deleted the location; make sure that really happened through the VM.
        await #expect(throws: APIError.self) {
            let _: MDLocation = try await grocyVM.grocyApi.getObjectWithID(object: .locations, id: location.id)
        }

        try await syncLocations()
        #expect(try storedLocation(id: location.id) == nil, "Deleted location is still in SwiftData")
        #expect(!grocyVM.mdLocations.contains { $0.id == location.id })
    }

    @Test("The server rejects a second location with an existing name")
    func duplicateNameIsRejected() async throws {
        try await withCleanup { cleanup in
            let existing = try await createLocationOnServer(cleanup: cleanup)
            let duplicate = MDLocation(id: try grocyVM.findNextID(.locations), name: existing.name)

            await #expect(throws: APIError.self) {
                let response = try await grocyVM.postMDObject(object: .locations, content: duplicate)
                cleanup.locationIDs.append(response.createdObjectID)
            }

            try await syncLocations()
            #expect(try storedLocations().filter { $0.name == existing.name }.count == 1)
        }
    }

    // MARK: - Change detection

    /// `requestData` only reloads when `system/db-changed-time` differs from the last sync. Grocy derives it from
    /// the database file's mtime with one-second resolution, so a second write within the same second as the
    /// previous sync leaves the timestamp unchanged, and the app keeps showing stale data.
    @Test("A write in the same second as the last sync still reaches SwiftData")
    func writeInSameSecondAsLastSyncIsPickedUp() async throws {
        try await withCleanup { cleanup in
            // Retry until the second write lands in the same second as the first one, so the
            // scenario is reproduced deterministically instead of depending on timing.
            var renamed: MDLocation?
            for _ in 1...5 {
                let original = try await createLocationOnServer(cleanup: cleanup)  // write 1 + sync
                let changedTimeBefore = try await grocyVM.grocyApi.getSystemDBChangedTime()
                let candidate = MDLocation(
                    id: original.id,
                    name: uniqueName(),
                    mdLocationDescription: original.mdLocationDescription,
                    isFreezer: original.isFreezer,
                    rowCreatedTimestamp: original.rowCreatedTimestamp
                )
                try await grocyVM.putMDObjectWithID(object: .locations, id: candidate.id, content: candidate)  // write 2
                if try await grocyVM.grocyApi.getSystemDBChangedTime() == changedTimeBefore {
                    renamed = candidate
                    break
                }
            }
            let edited = try #require(renamed, "Could not land two writes within the same second")

            try await syncLocations(forceReload: false)  // exactly what the views do

            let stored = try storedLocation(id: edited.id)
            withKnownIssue("db-changed-time has one-second resolution, so same-second writes are not detected") {
                #expect(stored?.name == edited.name)
            }
        }
    }

    // MARK: - Helpers

    /// Locations created by a test, deleted again when it ends (also on failure).
    final class Cleanup {
        var locationIDs: [Int] = []
    }

    private func withCleanup<T>(_ body: (Cleanup) async throws -> T) async throws -> T {
        let cleanup = Cleanup()
        do {
            let result = try await body(cleanup)
            try await deleteLocations(cleanup.locationIDs)
            return result
        } catch {
            try? await deleteLocations(cleanup.locationIDs)
            throw error
        }
    }

    private func deleteLocations(_ ids: [Int]) async throws {
        for id in ids {
            try await grocyVM.deleteMDObject(object: .locations, id: id)
        }
    }

    /// Creates a location the same way `MDLocationFormView` does and syncs it into SwiftData.
    private func createLocationOnServer(cleanup: Cleanup) async throws -> MDLocation {
        try await syncLocations()
        let location = MDLocation(
            id: try grocyVM.findNextID(.locations),
            name: uniqueName(),
            mdLocationDescription: "Fixture",
            isFreezer: false
        )
        let response = try await grocyVM.postMDObject(object: .locations, content: location)
        cleanup.locationIDs.append(response.createdObjectID)
        try await syncLocations()
        return try #require(try storedLocation(id: response.createdObjectID), "Fixture location was not synced into SwiftData")
    }

    /// Runs the refresh that location views trigger in `.task` / `.refreshable`.
    ///
    /// By default, the cached `db-changed-time` for locations is dropped first so the reload always happens.
    /// Grocy reports that timestamp with one-second resolution, so writes that land in the same second as the
    /// previous sync would otherwise be skipped (see `writeInSameSecondAsLastSyncIsPickedUp`).
    private func syncLocations(forceReload: Bool = true, sourceLocation: SourceLocation = #_sourceLocation) async throws {
        if forceReload {
            grocyVM.timeStampsObjects[.locations] = nil
        }
        await grocyVM.requestData(objects: [.locations])
        try #require(!grocyVM.failedToLoadObjects.contains(.locations), "Loading locations failed", sourceLocation: sourceLocation)
    }

    private func storedLocations() throws -> [MDLocation] {
        try container.mainContext.fetch(FetchDescriptor<MDLocation>(sortBy: [SortDescriptor(\.id)]))
    }

    private func storedLocation(id: Int) throws -> MDLocation? {
        var descriptor = FetchDescriptor<MDLocation>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try container.mainContext.fetch(descriptor).first
    }

    private func uniqueName() -> String {
        "IT Location \(UUID().uuidString.prefix(8))"
    }

    /// Compares the user-editable fields; `rowCreatedTimestamp` is set by the server.
    private func expectSameContent(_ actual: MDLocation, _ expected: MDLocation, sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(actual.id == expected.id, sourceLocation: sourceLocation)
        #expect(actual.name == expected.name, sourceLocation: sourceLocation)
        #expect(actual.active == expected.active, sourceLocation: sourceLocation)
        #expect(actual.mdLocationDescription == expected.mdLocationDescription, sourceLocation: sourceLocation)
        #expect(actual.isFreezer == expected.isFreezer, sourceLocation: sourceLocation)
    }
}
