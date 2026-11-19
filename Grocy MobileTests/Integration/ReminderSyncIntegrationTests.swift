//
//  ReminderSyncIntegrationTests.swift
//  Grocy MobileTests
//
//  Created by Georg Meißner on 19.11.26.
//

import EventKit
import Foundation
import SwiftData
import Testing

@testable import Grocy_Mobile

/// Syncs a shopping list on a real Grocy server with the real Reminders store of the device or simulator.
///
/// Needs full access to Reminders for the test host, on a simulator:
/// `xcrun simctl privacy <device> grant reminders georgappdev.Grocy`.
/// The test creates its own shopping list and Reminders list, and deletes both afterwards.
@MainActor
@Suite(
    "Shopping list ↔ Reminders (Grocy server)",
    .tags(.integration),
    .serialized,
    .enabled(if: GrocyTestServer.isConfigured, GrocyTestServer.notConfiguredComment),
    .enabled(
        if: EKEventStore.authorizationStatus(for: .reminder) == .fullAccess,
        "Grant the test host full access to Reminders, e.g. `xcrun simctl privacy booted grant reminders georgappdev.Grocy`."
    )
)
struct ReminderSyncIntegrationTests {
    let grocyVM: GrocyViewModel
    let container: ModelContainer
    let profileContainer: ModelContainer
    let defaults: UserDefaults
    let reminderStore: ReminderStore

    init() async throws {
        (grocyVM, container, profileContainer) = try await GrocyTestServer.makeLoggedInViewModel()
        defaults = try #require(UserDefaults(suiteName: "ReminderSyncIntegrationTests-\(UUID().uuidString)"))
        reminderStore = ReminderStore(defaults: defaults)
    }

    @Test("Items go to Reminders; checking off and adding there comes back; deleted items disappear")
    func twoWaySync() async throws {
        var listID: Int?
        var calendar: EKCalendar?
        defer {
            if let calendar {
                try? reminderStore.ekStore.removeCalendar(calendar, commit: true)
            }
        }
        do {
            // A shopping list with two free-text items.
            await grocyVM.requestData(objects: [.shopping_lists, .shopping_list])
            let name = "Reminders test \(UUID().uuidString.prefix(8))"
            let list = ShoppingListDescription(id: try grocyVM.findNextID(.shopping_lists), name: name)
            listID = try await grocyVM.postMDObject(object: .shopping_lists, content: list).createdObjectID
            let milkID = try await postItem("Milk", listID: list.id)
            let breadID = try await postItem("Bread", listID: list.id)
            await grocyVM.requestData(objects: [.shopping_lists])
            let shoppingList = try #require(try container.mainContext.fetch(FetchDescriptor<ShoppingListDescription>()).first { $0.id == list.id })

            // First sync: creates the list in Reminders with one linked reminder per item.
            let first = try #require(try await reminderStore.sync(shoppingList: shoppingList, grocyVM: grocyVM, requestAccess: false))
            #expect(first.createdList)
            #expect(first.listTitle == "\(name) (Grocy Mobile)")
            let calendarID = try #require(reminderStore.calendarIdentifiers[list.id])
            calendar = try #require(reminderStore.ekStore.calendar(withIdentifier: calendarID))
            var reminders = try await fetchReminders(in: try #require(calendar))
            #expect(Set(reminders.map(\.title)) == ["Milk", "Bread"])
            #expect(Set(reminders.compactMap { ShoppingListReminderSync.itemID(from: $0.url, listID: list.id) }) == [milkID, breadID])

            // A second sync without changes changes nothing.
            let unchanged = try #require(try await reminderStore.sync(shoppingList: shoppingList, grocyVM: grocyVM, requestAccess: false))
            #expect(unchanged.changesFromReminders == 0 && unchanged.changesToReminders == 0)

            // Check off Milk and add Coffee in Reminders, after the last sync.
            try await Task.sleep(for: .seconds(1.5))
            let milk = try #require(reminders.first { $0.title == "Milk" })
            milk.isCompleted = true
            try reminderStore.ekStore.save(milk, commit: false)
            let coffee = EKReminder(eventStore: reminderStore.ekStore)
            coffee.title = "Coffee"
            coffee.calendar = calendar
            try reminderStore.ekStore.save(coffee, commit: false)
            try reminderStore.ekStore.commit()

            let second = try #require(try await reminderStore.sync(shoppingList: shoppingList, grocyVM: grocyVM, requestAccess: false))
            #expect(second.changesFromReminders == 2)
            var serverItems = try await itemsOnServer(listID: list.id)
            #expect(serverItems.first { $0.id == milkID }?.done == true)
            #expect(serverItems.first { $0.id == breadID }?.done == false)
            let coffeeItem = try #require(serverItems.first { $0.note == "Coffee" }, "The reminder added in Reminders wasn't added to Grocy")
            reminders = try await fetchReminders(in: try #require(calendar))
            #expect(reminders.count == 3, "Syncing must not duplicate reminders")
            #expect(ShoppingListReminderSync.itemID(from: reminders.first { $0.title == "Coffee" }?.url, listID: list.id) == coffeeItem.id)

            // Deleting an item in Grocy removes its reminder.
            try await grocyVM.deleteMDObject(object: .shopping_list, id: breadID)
            grocyVM.timeStampsObjects[.shopping_list] = nil
            try await reminderStore.sync(shoppingList: shoppingList, grocyVM: grocyVM, requestAccess: false)
            reminders = try await fetchReminders(in: try #require(calendar))
            #expect(Set(reminders.map(\.title)) == ["Milk", "Coffee"])
            #expect(reminders.first { $0.title == "Milk" }?.isCompleted == true)

            serverItems = try await itemsOnServer(listID: list.id)
            try await deleteList(listID: list.id, items: serverItems)
        } catch {
            if let listID {
                try? await deleteList(listID: listID, items: (try? await itemsOnServer(listID: listID)) ?? [])
            }
            throw error
        }
    }

    // MARK: - Helpers

    private func postItem(_ note: String, listID: Int) async throws -> Int {
        let item = ShoppingListNoteItemPOST(shoppingListID: listID, note: note, amount: 1, done: false)
        return try await grocyVM.postMDObject(object: .shopping_list, content: item).createdObjectID
    }

    private func itemsOnServer(listID: Int) async throws -> [ShoppingListItem] {
        let items: [ShoppingListItem] = try await grocyVM.grocyApi.getObject(object: .shopping_list)
        return items.filter { $0.shoppingListID == listID }
    }

    private func deleteList(listID: Int, items: [ShoppingListItem]) async throws {
        for item in items {
            try await grocyVM.deleteMDObject(object: .shopping_list, id: item.id)
        }
        try await grocyVM.deleteMDObject(object: .shopping_lists, id: listID)
    }

    private func fetchReminders(in calendar: EKCalendar) async throws -> [EKReminder] {
        let store = reminderStore.ekStore
        let predicate = store.predicateForReminders(in: [calendar])
        return try await withCheckedThrowingContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                if let reminders {
                    continuation.resume(returning: reminders)
                } else {
                    continuation.resume(throwing: ReminderSyncError.failedReadingReminders)
                }
            }
        }
    }
}
