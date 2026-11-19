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

/// Syncs shopping lists, tasks and chores on a real Grocy server with the real Reminders store of the device or simulator.
///
/// Needs full access to Reminders for the test host, on a simulator:
/// `xcrun simctl privacy <device> grant reminders georgappdev.Grocy`.
/// The test creates its own shopping list and Reminders list, and deletes both afterwards.
@MainActor
@Suite(
    "Reminders sync (Grocy server)",
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
            let calendarID = try #require(reminderStore.calendarIdentifiers[.shoppingList(id: list.id)])
            calendar = try #require(reminderStore.ekStore.calendar(withIdentifier: calendarID))
            var reminders = try await fetchReminders(in: try #require(calendar))
            #expect(Set(reminders.map(\.title)) == ["Milk", "Bread"])
            #expect(Set(reminders.compactMap { ReminderSyncTarget.shoppingList(id: list.id).link.itemID(from: $0.url) }) == [milkID, breadID])

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
            #expect(ReminderSyncTarget.shoppingList(id: list.id).link.itemID(from: reminders.first { $0.title == "Coffee" }?.url) == coffeeItem.id)

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

    @Test("Tasks: checking off and adding in Reminders comes back to Grocy, with the due date")
    func tasksTwoWay() async throws {
        var taskIDs: [Int] = []
        var calendar: EKCalendar?
        defer {
            if let calendar {
                try? reminderStore.ekStore.removeCalendar(calendar, commit: true)
            }
        }
        do {
            await grocyVM.requestData(objects: [.tasks])
            let name = "Reminders task \(UUID().uuidString.prefix(8))"
            let due = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 12, day: 24)))
            let task = GrocyTask(id: try grocyVM.findNextID(.tasks), name: name, dueDate: due)
            let taskID = try await grocyVM.postMDObject(object: .tasks, content: task).createdObjectID
            taskIDs.append(taskID)
            // Grocy's db-changed-time has one-second resolution, so the reload after a write in the same second is forced.
            grocyVM.timeStampsObjects[.tasks] = nil

            try await reminderStore.sync(.tasks, grocyVM: grocyVM, requestAccess: false)
            calendar = reminderStore.calendarIdentifiers[.tasks].flatMap { reminderStore.ekStore.calendar(withIdentifier: $0) }
            let linkedCalendar = try #require(calendar)
            var reminders = try await fetchReminders(in: linkedCalendar)
            let reminder = try #require(reminders.first { ReminderSyncTarget.tasks.link.itemID(from: $0.url) == taskID })
            #expect(reminder.title == name)
            #expect(ReminderSync.normalized(reminder.dueDateComponents) == DateComponents(year: 2026, month: 12, day: 24))

            // Check it off and add a task with a due day in Reminders.
            try await Task.sleep(for: .seconds(1.5))
            reminder.isCompleted = true
            try reminderStore.ekStore.save(reminder, commit: false)
            let added = EKReminder(eventStore: reminderStore.ekStore)
            added.title = "Call plumber \(UUID().uuidString.prefix(8))"
            added.dueDateComponents = DateComponents(year: 2026, month: 12, day: 2)
            added.calendar = linkedCalendar
            try reminderStore.ekStore.save(added, commit: false)
            try reminderStore.ekStore.commit()

            let second = try #require(try await reminderStore.sync(.tasks, grocyVM: grocyVM, requestAccess: false))
            #expect(second.changesFromReminders == 2)
            let serverTasks: [GrocyTask] = try await grocyVM.grocyApi.getObject(object: .tasks)
            #expect(serverTasks.first { $0.id == taskID }?.done == true)
            let addedTask = try #require(serverTasks.first { $0.name == added.title }, "The reminder added in Reminders wasn't added to Grocy")
            taskIDs.append(addedTask.id)
            #expect(
                addedTask.dueDate.map { Calendar.current.dateComponents([.year, .month, .day], from: $0) } == DateComponents(year: 2026, month: 12, day: 2)
            )

            reminders = try await fetchReminders(in: linkedCalendar)
            #expect(ReminderSyncTarget.tasks.link.itemID(from: reminders.first { $0.title == added.title }?.url) == addedTask.id)
            let unchanged = try #require(try await reminderStore.sync(.tasks, grocyVM: grocyVM, requestAccess: false))
            #expect(unchanged.changesFromReminders == 0 && unchanged.changesToReminders == 0)
        } catch {
            await deleteObjects(.tasks, ids: taskIDs)
            throw error
        }
        await deleteObjects(.tasks, ids: taskIDs)
    }

    @Test("Chores: checking off in Reminders tracks the chore, and the reminder comes back with the next due date")
    func choresTrackedFromReminders() async throws {
        var choreID: Int?
        var calendar: EKCalendar?
        defer {
            if let calendar {
                try? reminderStore.ekStore.removeCalendar(calendar, commit: true)
            }
        }
        do {
            await grocyVM.requestData(objects: [.chores])
            let name = "Reminders chore \(UUID().uuidString.prefix(8))"
            let chore = MDChore(id: try grocyVM.findNextID(.chores), name: name, periodType: .daily, trackDateOnly: true)
            choreID = try await grocyVM.postMDObject(object: .chores, content: chore).createdObjectID
            grocyVM.timeStampsAdditionalObjects[.chores] = nil
            let id = try #require(choreID)

            let first = try #require(try await reminderStore.sync(.chores, grocyVM: grocyVM, requestAccess: false))
            #expect(first.listTitle.hasSuffix("(Grocy Mobile)"))
            calendar = reminderStore.calendarIdentifiers[.chores].flatMap { reminderStore.ekStore.calendar(withIdentifier: $0) }
            let linkedCalendar = try #require(calendar)
            let reminder = try #require(try await fetchReminders(in: linkedCalendar).first { ReminderSyncTarget.chores.link.itemID(from: $0.url) == id })
            #expect(reminder.title == name)
            let dueBefore = ReminderSync.normalized(reminder.dueDateComponents)

            try await Task.sleep(for: .seconds(1.5))
            reminder.isCompleted = true
            try reminderStore.ekStore.save(reminder, commit: true)

            let second = try #require(try await reminderStore.sync(.chores, grocyVM: grocyVM, requestAccess: false))
            #expect(second.changesFromReminders == 1)
            let serverChore = try #require(try await grocyVM.grocyApi.getChores().first { $0.choreID == id })
            #expect(serverChore.lastTrackedTime != nil, "Checking off in Reminders didn't track the chore")

            let after = try #require(try await fetchReminders(in: linkedCalendar).first { ReminderSyncTarget.chores.link.itemID(from: $0.url) == id })
            #expect(!after.isCompleted, "The chore's reminder has to reopen for the next execution")
            #expect(ReminderSync.normalized(after.dueDateComponents) == ReminderSync.dueDate(serverChore.nextEstimatedExecutionTime, dateOnly: true))
            #expect(ReminderSync.normalized(after.dueDateComponents) != dueBefore || dueBefore == nil)
        } catch {
            await deleteObjects(.chores, ids: choreID.map { [$0] } ?? [])
            throw error
        }
        await deleteObjects(.chores, ids: choreID.map { [$0] } ?? [])
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

    /// Best-effort cleanup; the test server's database is thrown away anyway.
    private func deleteObjects(_ object: ObjectEntities, ids: [Int]) async {
        for id in ids {
            try? await grocyVM.deleteMDObject(object: object, id: id)
        }
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
