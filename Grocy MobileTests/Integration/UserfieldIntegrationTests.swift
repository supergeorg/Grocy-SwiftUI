//
//  UserfieldIntegrationTests.swift
//  Grocy MobileTests
//
//  Created by Georg Meissner on 20.11.26.
//

import Foundation
import SwiftData
import Testing

@testable import Grocy_Mobile

/// Userfield values of objects and the records of user entities, against a real Grocy server.
/// Part of the serialized userfield suite: run side by side, both would create user entities with the same next ID.
extension UserManagementIntegrationTests {
    private func uniqueValueName(_ prefix: String) -> String {
        "\(prefix)\(UUID().uuidString.prefix(8).lowercased())"
    }

    /// Objects to delete after a test, also when it fails.
    private final class Cleanup {
        var objects: [(ObjectEntities, Int)] = []
    }

    private func withCleanup(_ body: (Cleanup) async throws -> Void) async throws {
        await grocyVM.requestData(objects: [.userfields, .userentities, .locations])
        let cleanup = Cleanup()
        do {
            try await body(cleanup)
        } catch {
            for (object, id) in cleanup.objects.reversed() { try? await grocyVM.deleteMDObject(object: object, id: id) }
            throw error
        }
        for (object, id) in cleanup.objects.reversed() { try await grocyVM.deleteMDObject(object: object, id: id) }
    }

    private func createField(entity: String, type: UserFieldType, cleanup: Cleanup) async throws -> MDUserField {
        let field = MDUserField(
            id: try grocyVM.findNextID(.userfields),
            name: uniqueValueName("field"),
            entity: entity,
            caption: "Field",
            type: type.rawValue,
            showAsColumnInTables: true,
            config: type == .presetChecklist ? "Red\nGreen\nBlue" : nil
        )
        let id = try await grocyVM.postMDObject(object: .userfields, content: field).createdObjectID
        cleanup.objects.append((.userfields, id))
        grocyVM.timeStampsObjects[.userfields] = nil
        await grocyVM.requestData(objects: [.userfields])
        return try #require(grocyVM.mdUserFields.first(where: { $0.id == id }))
    }

    @Test("An entity without userfields has no values")
    func noUserfields() async throws {
        // Grocy answers with an empty JSON array instead of an object here.
        let values = try await grocyVM.getUserfieldValues(entity: "shopping_lists", objectID: 1)
        #expect(values.values.isEmpty)
    }

    @Test("Userfield values of a location are saved, and only changed fields are sent")
    func locationValues() async throws {
        try await withCleanup { cleanup in
            let text = try await createField(entity: "locations", type: .textSingleLine, cleanup: cleanup)
            let checklist = try await createField(entity: "locations", type: .presetChecklist, cleanup: cleanup)
            #expect(checklist.options == ["Red", "Green", "Blue"])
            #expect(grocyVM.userfields(for: "locations").contains(where: { $0.id == text.id }))

            let location = MDLocation(id: try grocyVM.findNextID(.locations), name: uniqueValueName("Location "))
            _ = try await grocyVM.postMDObject(object: .locations, content: location)
            cleanup.objects.insert((.locations, location.id), at: 0)

            try await grocyVM.putUserfieldValues(entity: "locations", objectID: location.id, values: [text.name: "Hello", checklist.name: "Red,Blue"])
            try await grocyVM.putUserfieldValues(entity: "locations", objectID: location.id, values: [text.name: "Changed"])

            let values = try await grocyVM.getUserfieldValues(entity: "locations", objectID: location.id).values
            #expect(values[text.name] == "Changed")
            #expect(values[checklist.name] == "Red,Blue")
        }
    }

    @Test("A record of a user entity is created with its values and deleted")
    func userObject() async throws {
        try await withCleanup { cleanup in
            let entity = MDUserEntity(id: try grocyVM.findNextID(.userentities), name: uniqueValueName("entity"), caption: "Entity")
            let entityID = try await grocyVM.postMDObject(object: .userentities, content: entity).createdObjectID
            cleanup.objects.append((.userentities, entityID))
            let field = try await createField(entity: entity.userfieldEntity, type: .textSingleLine, cleanup: cleanup)

            let objectID = try await grocyVM.postMDObject(object: .userobjects, content: MDUserObject(userentityID: entityID)).createdObjectID
            try await grocyVM.putUserfieldValues(entity: entity.userfieldEntity, objectID: objectID, values: [field.name: "Record"])

            grocyVM.timeStampsObjects[.userobjects] = nil
            await grocyVM.requestData(objects: [.userobjects])
            #expect(grocyVM.mdUserObjects.first(where: { $0.id == objectID })?.userentityID == entityID)
            #expect(try await grocyVM.getUserfieldValues(entity: entity.userfieldEntity, objectID: objectID).values[field.name] == "Record")

            try await grocyVM.deleteMDObject(object: .userobjects, id: objectID)
            grocyVM.timeStampsObjects[.userobjects] = nil
            await grocyVM.requestData(objects: [.userobjects])
            #expect(!grocyVM.mdUserObjects.contains(where: { $0.id == objectID }))
        }
    }
}
