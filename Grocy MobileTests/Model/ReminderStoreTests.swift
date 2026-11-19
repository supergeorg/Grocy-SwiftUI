//
//  ReminderStoreTests.swift
//  Grocy MobileTests
//
//  Created by Georg Meißner on 19.11.26.
//

import EventKit
import Foundation
import SwiftData
import Testing

@testable import Grocy_Mobile

/// The EventKit half of the Reminders sync, against the real Reminders store, without a Grocy server:
/// the items come from SwiftData, and nothing is changed in Reminders that would have to be written to Grocy.
///
/// Needs full access to Reminders for the test host, on a simulator:
/// `xcrun simctl privacy <device> grant reminders georgappdev.Grocy` (run the tests with `-parallel-testing-enabled NO`,
/// because the clones of a simulator don't get the grant). Without it, the suite is skipped.
@MainActor
@Suite(
    "Reminders store (EventKit)",
    .serialized,
    .enabled(
        if: EKEventStore.authorizationStatus(for: .reminder) == .fullAccess,
        "Grant the test host full access to Reminders, e.g. `xcrun simctl privacy booted grant reminders georgappdev.Grocy`."
    )
)
struct ReminderStoreTests {
    let container: ModelContainer
    let profileContainer: ModelContainer
    let grocyVM: GrocyViewModel
    let reminderStore: ReminderStore

    init() throws {
        container = try ModelContainer(
            for: Schema(PreviewContainer.modelTypes),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        profileContainer = try ModelContainer(
            for: Schema([ServerProfile.self, LoginCustomHeader.self]),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        // The test host is the app: without this, the view model logs in to the app's server, and its first sync replaces the test items.
        // The view model reads the setting only in init, so it's restored right away.
        let wasLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        grocyVM = GrocyViewModel(modelContext: container.mainContext, profileModelContext: profileContainer.mainContext)
        UserDefaults.standard.set(wasLoggedIn, forKey: "isLoggedIn")
        let defaults = try #require(UserDefaults(suiteName: "ReminderStoreTests-\(UUID().uuidString)"))
        reminderStore = ReminderStore(defaults: defaults)
    }

    @Test("Creates a linked list, updates reminders in place and removes the ones of deleted items")
    func mirrorsItems() async throws {
        let context = container.mainContext
        let listID = 900_001
        let shoppingList = ShoppingListDescription(id: listID, name: "EventKit test \(UUID().uuidString.prefix(8))")
        let product = MDProduct(id: 900_001, name: "Milk", quIDPurchase: 900_001)
        let unit = MDQuantityUnit(id: 900_001, name: "Pack", namePlural: "Packs")
        let milk = ShoppingListItem(id: 900_001, productID: product.id, amount: 2, shoppingListID: listID, quID: unit.id)
        let bread = ShoppingListItem(id: 900_002, note: "Bread", shoppingListID: listID)
        context.insert(shoppingList)
        context.insert(product)
        context.insert(unit)
        context.insert(milk)
        context.insert(bread)
        try context.save()

        var calendar: EKCalendar?
        defer {
            if let calendar {
                try? reminderStore.ekStore.removeCalendar(calendar, commit: true)
            }
        }

        let first = try #require(try await reminderStore.sync(shoppingList: shoppingList, grocyVM: grocyVM, requestAccess: false))
        #expect(first.createdList)
        #expect(first.changesToReminders == 2)
        calendar = reminderStore.calendarIdentifiers[.shoppingList(id: listID)].flatMap { reminderStore.ekStore.calendar(withIdentifier: $0) }
        let linkedCalendar = try #require(calendar)
        #expect(linkedCalendar.title == "\(shoppingList.name) (Grocy Mobile)")
        #expect(reminderStore.lastSync(shoppingListID: listID) != nil)

        var reminders = try await fetchReminders(in: linkedCalendar)
        #expect(reminders.count == 2)
        let milkReminder = try #require(reminders.first { $0.title == "Milk" })
        #expect(milkReminder.notes == "\(2.0.formattedAmount) Packs")
        #expect(ReminderSyncTarget.shoppingList(id: listID).link.itemID(from: milkReminder.url) == milk.id)
        let milkReminderID = milkReminder.calendarItemIdentifier

        // Nothing changed: no writes.
        let unchanged = try #require(try await reminderStore.sync(shoppingList: shoppingList, grocyVM: grocyVM, requestAccess: false))
        #expect(unchanged.changesFromReminders == 0 && unchanged.changesToReminders == 0)
        #expect(!unchanged.createdList)

        // Changed in Grocy: the reminder is updated in place. Deleted in Grocy: the reminder is removed.
        milk.amount = 3
        milk.done = true
        context.delete(bread)
        try context.save()
        let changed = try #require(try await reminderStore.sync(shoppingList: shoppingList, grocyVM: grocyVM, requestAccess: false))
        #expect(changed.changesToReminders == 2)
        reminders = try await fetchReminders(in: linkedCalendar)
        #expect(reminders.map(\.calendarItemIdentifier) == [milkReminderID])
        #expect(reminders.first?.isCompleted == true)
        #expect(reminders.first?.notes == "\(3.0.formattedAmount) Packs")
    }

    @Test("Unlinking forgets the lists, so the next sync starts fresh")
    func unlink() async throws {
        let shoppingList = ShoppingListDescription(id: 900_002, name: "EventKit unlink \(UUID().uuidString.prefix(8))")
        container.mainContext.insert(shoppingList)
        try container.mainContext.save()

        try await reminderStore.sync(shoppingList: shoppingList, grocyVM: grocyVM, requestAccess: false)
        let calendarID = try #require(reminderStore.calendarIdentifiers[.shoppingList(id: shoppingList.id)])
        defer {
            if let calendar = reminderStore.ekStore.calendar(withIdentifier: calendarID) {
                try? reminderStore.ekStore.removeCalendar(calendar, commit: true)
            }
        }
        #expect(reminderStore.isLinked(shoppingListID: shoppingList.id))

        reminderStore.unlinkAll()
        #expect(!reminderStore.isLinked(shoppingListID: shoppingList.id))
        #expect(reminderStore.lastSync(shoppingListID: shoppingList.id) == nil)
        // The list itself stays in Reminders.
        #expect(reminderStore.ekStore.calendar(withIdentifier: calendarID) != nil)
    }

    @Test("Tasks get reminders with their due day; done tasks don't get new ones; nothing changes on the next sync")
    func mirrorsTasks() async throws {
        let context = container.mainContext
        let due = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 12, day: 24)))
        let open = GrocyTask(id: 900_001, name: "Wrap presents \(UUID().uuidString.prefix(8))", taskDescription: "In the attic", dueDate: due)
        let done = GrocyTask(id: 900_002, name: "Buy presents", done: true)
        context.insert(open)
        context.insert(done)
        try context.save()

        let calendar = try await syncAndFetchCalendar(.tasks)
        defer { try? reminderStore.ekStore.removeCalendar(calendar, commit: true) }

        let reminders = try await fetchReminders(in: calendar)
        let reminder = try #require(reminders.first)
        #expect(reminders.count == 1)
        #expect(reminder.title == open.name)
        #expect(reminder.notes == "In the attic")
        #expect(ReminderSync.normalized(reminder.dueDateComponents) == DateComponents(year: 2026, month: 12, day: 24))
        #expect(ReminderSyncTarget.tasks.link.itemID(from: reminder.url) == open.id)

        let unchanged = try #require(try await reminderStore.sync(.tasks, grocyVM: grocyVM, requestAccess: false))
        #expect(unchanged.changesToReminders == 0, "The due date has to compare equal after a round trip through EventKit")

        // Done in Grocy: the reminder is kept, checked off.
        open.done = true
        try context.save()
        try await reminderStore.sync(.tasks, grocyVM: grocyVM, requestAccess: false)
        let afterDone = try await fetchReminders(in: calendar)
        #expect(afterDone.map(\.isCompleted) == [true])
    }

    @Test("Chores get reminders with their next due time, or the day only")
    func mirrorsChores() async throws {
        let context = container.mainContext
        let next = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 12, day: 1, hour: 18, minute: 15)))
        let timed = Chore(id: 900_001, choreID: 900_001, choreName: "Vacuum \(UUID().uuidString.prefix(8))", nextEstimatedExecutionTime: next)
        let dateOnly = Chore(id: 900_002, choreID: 900_002, choreName: "Water plants", nextEstimatedExecutionTime: next, trackDateOnly: true)
        context.insert(timed)
        context.insert(dateOnly)
        try context.save()

        let calendar = try await syncAndFetchCalendar(.chores)
        defer { try? reminderStore.ekStore.removeCalendar(calendar, commit: true) }

        let reminders = try await fetchReminders(in: calendar)
        #expect(reminders.count == 2)
        let timedReminder = try #require(reminders.first { $0.title == timed.choreName })
        #expect(ReminderSync.normalized(timedReminder.dueDateComponents) == DateComponents(year: 2026, month: 12, day: 1, hour: 18, minute: 15))
        let dateOnlyReminder = try #require(reminders.first { $0.title == "Water plants" })
        #expect(ReminderSync.normalized(dateOnlyReminder.dueDateComponents) == DateComponents(year: 2026, month: 12, day: 1))

        let unchanged = try #require(try await reminderStore.sync(.chores, grocyVM: grocyVM, requestAccess: false))
        #expect(unchanged.changesToReminders == 0)
    }

    @Test("Unlinking one kind keeps the others and turns its setting off")
    func unlinkOneKind() async throws {
        let shoppingList = ShoppingListDescription(id: 900_003, name: "EventKit kinds \(UUID().uuidString.prefix(8))")
        container.mainContext.insert(shoppingList)
        try container.mainContext.save()
        let defaults = try #require(UserDefaults(suiteName: "ReminderStoreTests-unlink-\(UUID().uuidString)"))
        let store = ReminderStore(defaults: defaults)
        defaults.set(true, forKey: ReminderSyncTarget.settingKey(for: .tasks))

        try await store.sync(shoppingList: shoppingList, grocyVM: grocyVM, requestAccess: false)
        try await store.sync(.tasks, grocyVM: grocyVM, requestAccess: false)
        defer {
            for identifier in store.calendarIdentifiers.values {
                if let calendar = store.ekStore.calendar(withIdentifier: identifier) {
                    try? store.ekStore.removeCalendar(calendar, commit: true)
                }
            }
        }

        store.unlink(.tasks)
        #expect(!store.isLinked(.tasks))
        #expect(!defaults.bool(forKey: ReminderSyncTarget.settingKey(for: .tasks)))
        #expect(store.isLinked(shoppingListID: shoppingList.id))
        // Stored under the same keys as before, so links survive an update.
        #expect((defaults.dictionary(forKey: "reminderListIdentifiers") as? [String: String])?.keys.contains(String(shoppingList.id)) == true)
    }

    private func syncAndFetchCalendar(_ target: ReminderSyncTarget) async throws -> EKCalendar {
        let result = try #require(try await reminderStore.sync(target, grocyVM: grocyVM, requestAccess: false))
        #expect(result.changesToReminders > 0)
        let identifier = try #require(reminderStore.calendarIdentifiers[target])
        return try #require(reminderStore.ekStore.calendar(withIdentifier: identifier))
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
