//
//  ReminderSyncTests.swift
//  Grocy MobileTests
//
//  Created by Georg Meißner on 19.11.26.
//

import Foundation
import Testing

@testable import Grocy_Mobile

@Suite("Reminders sync rules")
struct ReminderSyncTests {
    typealias Sync = ReminderSync

    let lastSync = Date(timeIntervalSince1970: 1_000_000)
    var before: Date { lastSync.addingTimeInterval(-60) }
    var after: Date { lastSync.addingTimeInterval(60) }

    func entry(_ itemID: Int, _ title: String, done: Bool = false, notes: String? = nil) -> Sync.Entry {
        Sync.Entry(itemID: itemID, title: title, notes: notes, isDone: done)
    }

    func reminder(_ id: String, item: Int?, _ title: String, completed: Bool = false, notes: String? = nil, modified: Date? = nil) -> Sync.ExistingReminder {
        Sync.ExistingReminder(id: id, itemID: item, title: title, notes: notes, isCompleted: completed, lastModified: modified)
    }

    // MARK: - Reminders → Grocy

    @Test("A reminder checked off after the last sync marks the item done")
    func checkedOffInReminders() {
        let changes = Sync.grocyChanges(
            entries: [entry(1, "Milk"), entry(2, "Bread")],
            existing: [reminder("a", item: 1, "Milk", completed: true, modified: after), reminder("b", item: 2, "Bread", modified: after)],
            lastSync: lastSync
        )
        #expect(changes.doneChanges == [1: true])
        #expect(changes.newItems.isEmpty)
    }

    @Test("A reminder reopened after the last sync marks the item not done")
    func reopenedInReminders() {
        let changes = Sync.grocyChanges(
            entries: [entry(1, "Milk", done: true)],
            existing: [reminder("a", item: 1, "Milk", completed: false, modified: after)],
            lastSync: lastSync
        )
        #expect(changes.doneChanges == [1: false])
    }

    @Test("Reminders unchanged since the last sync don't override Grocy")
    func grocyWinsForOldReminders() {
        // Checked off in Grocy after the last sync: the reminder is still open, but wasn't touched.
        let changes = Sync.grocyChanges(
            entries: [entry(1, "Milk", done: true)],
            existing: [reminder("a", item: 1, "Milk", completed: false, modified: before)],
            lastSync: lastSync
        )
        #expect(changes.isEmpty)
    }

    @Test("A reminder added in Reminders becomes a new item; blank ones are ignored")
    func addedInReminders() {
        let added = reminder("c", item: nil, "Coffee", modified: after)
        let changes = Sync.grocyChanges(
            entries: [entry(1, "Milk")],
            existing: [reminder("a", item: 1, "Milk", modified: before), added, reminder("d", item: nil, "  ", modified: after)],
            lastSync: lastSync
        )
        #expect(changes.newItems == [added])
        #expect(changes.doneChanges.isEmpty)
    }

    @Test("The first sync takes nothing from Reminders")
    func firstSyncGrocyWins() {
        let changes = Sync.grocyChanges(
            entries: [entry(1, "Milk")],
            existing: [reminder("a", item: 1, "Milk", completed: true, modified: after), reminder("old", item: nil, "2x Milk")],
            lastSync: nil
        )
        #expect(changes.isEmpty)
    }

    @Test("Reminders of deleted items and duplicates don't change Grocy")
    func ignoresOrphansAndDuplicates() {
        let changes = Sync.grocyChanges(
            entries: [entry(1, "Milk")],
            existing: [
                reminder("a", item: 1, "Milk", modified: before),
                reminder("a2", item: 1, "Milk", completed: true, modified: after),
                reminder("x", item: 99, "Gone", completed: true, modified: after),
            ],
            lastSync: lastSync
        )
        #expect(changes.isEmpty)
    }

    // MARK: - Grocy → Reminders

    @Test("Missing reminders are created, changed ones updated, unchanged ones left alone")
    func createsAndUpdates() {
        let changes = Sync.reminderChanges(
            entries: [entry(1, "Milk", notes: "2 Packs"), entry(2, "Bread", done: true), entry(3, "Eggs")],
            existing: [reminder("a", item: 1, "Milk", notes: "2 Packs"), reminder("b", item: 2, "Bread")],
            removeUnlinked: false
        )
        #expect(changes.creates == [entry(3, "Eggs")])
        #expect(changes.updates == [Sync.ReminderUpdate(reminderID: "b", entry: entry(2, "Bread", done: true))])
        #expect(changes.removals.isEmpty)
    }

    @Test("Reminders of deleted items and duplicates are removed; unlinked ones stay")
    func removesOrphansAndDuplicates() {
        let changes = Sync.reminderChanges(
            entries: [entry(1, "Milk")],
            existing: [reminder("a", item: 1, "Milk"), reminder("a2", item: 1, "Milk"), reminder("x", item: 99, "Gone"), reminder("u", item: nil, "Mine")],
            removeUnlinked: false
        )
        #expect(changes.removals == ["a2", "x"])
        #expect(changes.isEmpty == false)
        #expect(changes.creates.isEmpty && changes.updates.isEmpty)
    }

    @Test("The first sync replaces the reminders of the old one-way export")
    func firstSyncRemovesLegacyReminders() {
        let changes = Sync.reminderChanges(entries: [entry(1, "Milk")], existing: [reminder("old", item: nil, "2x Milk")], removeUnlinked: true)
        #expect(changes.removals == ["old"])
        #expect(changes.creates == [entry(1, "Milk")])
    }

    @Test("A reminder linked to a new item gets its link, even if nothing else changed")
    func linksNewItems() {
        var added = reminder("c", item: 5, "Coffee")
        added.needsLink = true
        let changes = Sync.reminderChanges(entries: [entry(5, "Coffee")], existing: [added])
        #expect(changes.updates == [Sync.ReminderUpdate(reminderID: "c", entry: entry(5, "Coffee"))])
    }

    @Test("Empty notes and missing notes are the same")
    func notesNilEqualsEmpty() {
        let changes = Sync.reminderChanges(entries: [entry(1, "Milk", notes: nil)], existing: [reminder("a", item: 1, "Milk", notes: "")])
        #expect(changes.isEmpty)
    }

    // MARK: - Links and entries

    @MainActor
    @Test("The shopping list link round-trips, opens the shopping list, and belongs to one list")
    func itemLink() throws {
        let link = ReminderSyncTarget.shoppingList(id: 3).link
        let url = try #require(link.url(itemID: 42))
        #expect(url.absoluteString == "grocy://shoppinglist/list/3?item=42")
        #expect(link.itemID(from: url) == 42)
        #expect(ReminderSyncTarget.shoppingList(id: 4).link.itemID(from: url) == nil)
        #expect(ReminderSyncTarget.tasks.link.itemID(from: url) == nil)
        #expect(link.itemID(from: URL(string: "https://example.com/list/3?item=42")) == nil)
        #expect(link.itemID(from: nil) == nil)
        #expect(GrocyDeepLink(url: url) == .shoppingList(id: 3))
    }

    @MainActor
    @Test("Product items show the name, with the amount, unit and note below")
    func productEntry() {
        let item = ShoppingListItem(id: 7, productID: 1, note: "the organic one", amount: 2, shoppingListID: 1, done: true, quID: 1)
        let product = MDProduct(id: 1, name: "Milk")
        let unit = MDQuantityUnit(id: 1, name: "Pack", namePlural: "Packs")
        let entry = Sync.entry(for: item, product: product, quantityUnit: unit, roundUp: false)
        #expect(entry == Sync.Entry(itemID: 7, title: "Milk", notes: "\(2.0.formattedAmount) Packs\nthe organic one", isDone: true))
    }

    @MainActor
    @Test("Free-text items use the note as the name, and show the amount only when it isn't one")
    func noteEntry() {
        let single = ShoppingListItem(id: 8, productID: nil, note: "Coffee", amount: 1, shoppingListID: 1)
        #expect(Sync.entry(for: single, product: nil, quantityUnit: nil, roundUp: false) == Sync.Entry(itemID: 8, title: "Coffee", notes: nil, isDone: false))

        let several = ShoppingListItem(id: 9, productID: nil, note: "Lemons", amount: 2.4, shoppingListID: 1)
        #expect(Sync.entry(for: several, product: nil, quantityUnit: nil, roundUp: true).notes == 3.0.formattedAmount)
    }

    @MainActor
    @Test("Task and chore links open their screens and don't match each other")
    func taskAndChoreLinks() throws {
        let taskURL = try #require(ReminderSyncTarget.tasks.link.url(itemID: 7))
        #expect(taskURL.absoluteString == "grocy://tasks?task=7")
        #expect(ReminderSyncTarget.tasks.link.itemID(from: taskURL) == 7)
        #expect(ReminderSyncTarget.chores.link.itemID(from: taskURL) == nil)
        #expect(GrocyDeepLink(url: taskURL) == .tasks(filter: .all))

        let choreURL = try #require(ReminderSyncTarget.chores.link.url(itemID: 3))
        #expect(choreURL.absoluteString == "grocy://chores?chore=3")
        #expect(GrocyDeepLink(url: choreURL) == .chores(filter: .all))
    }

    @Test("Targets keep their storage keys; shopping lists use their ID as before")
    func storageKeys() {
        for target in [ReminderSyncTarget.shoppingList(id: 5), .tasks, .chores] {
            #expect(ReminderSyncTarget(storageKey: target.storageKey) == target)
        }
        #expect(ReminderSyncTarget.shoppingList(id: 5).storageKey == "5")
        #expect(ReminderSyncTarget(storageKey: "nonsense") == nil)
        #expect(!ReminderSyncTarget.chores.acceptsNewItems && ReminderSyncTarget.tasks.acceptsNewItems)
    }

    // MARK: - Due dates

    @Test("A changed due date updates the reminder; the same date doesn't")
    func dueDateChanges() {
        let day = DateComponents(year: 2026, month: 11, day: 20)
        let entry = Sync.Entry(itemID: 1, title: "Clean", notes: nil, isDone: false, dueDate: day)
        var existing = reminder("a", item: 1, "Clean")
        existing.dueDate = day
        #expect(Sync.reminderChanges(entries: [entry], existing: [existing]).isEmpty)

        existing.dueDate = DateComponents(year: 2026, month: 11, day: 19)
        #expect(Sync.reminderChanges(entries: [entry], existing: [existing]).updates.map(\.reminderID) == ["a"])
    }

    @Test("Due dates from EventKit are compared without their calendar and time zone")
    func normalizedDueDates() {
        var fromEventKit = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: .gmt, year: 2026, month: 11, day: 20)
        #expect(Sync.normalized(fromEventKit) == DateComponents(year: 2026, month: 11, day: 20))
        fromEventKit.hour = 18
        #expect(Sync.normalized(fromEventKit) == DateComponents(year: 2026, month: 11, day: 20, hour: 18, minute: 0))
        #expect(Sync.normalized(DateComponents(month: 11, day: 20)) == nil)
        #expect(Sync.normalized(nil) == nil)
    }

    // MARK: - Tasks and chores

    @MainActor
    @Test("Tasks show their description and due day")
    func taskEntry() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let due = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 20)))
        let task = GrocyTask(id: 4, name: "Taxes", taskDescription: "Before Friday", dueDate: due, done: true)
        #expect(
            Sync.entry(for: task, calendar: calendar)
                == Sync.Entry(itemID: 4, title: "Taxes", notes: "Before Friday", isDone: true, dueDate: DateComponents(year: 2026, month: 11, day: 20))
        )
        #expect(Sync.entry(for: GrocyTask(id: 5, name: "Call"), calendar: calendar).notes == nil)
    }

    @MainActor
    @Test("Chores are never done, and have a time unless they track the date only")
    func choreEntry() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let next = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 20, hour: 9, minute: 30)))
        let timed = Chore(id: 1, choreID: 8, choreName: "Vacuum", nextEstimatedExecutionTime: next)
        #expect(
            Sync.entry(for: timed, calendar: calendar)
                == Sync.Entry(
                    itemID: 8,
                    title: "Vacuum",
                    notes: nil,
                    isDone: false,
                    dueDate: DateComponents(year: 2026, month: 11, day: 20, hour: 9, minute: 30)
                )
        )
        let dateOnly = Chore(id: 2, choreID: 9, choreName: "Water plants", nextEstimatedExecutionTime: next, trackDateOnly: true)
        #expect(Sync.entry(for: dateOnly, calendar: calendar).dueDate == DateComponents(year: 2026, month: 11, day: 20))
        #expect(Sync.entry(for: Chore(id: 3, choreID: 10, choreName: "Descale"), calendar: calendar).dueDate == nil)
    }

    @Test("A chore checked off in Reminders is tracked, and its reminder reopens afterwards")
    func choreCheckedOff() {
        let entry = Sync.Entry(itemID: 8, title: "Vacuum", notes: nil, isDone: false, dueDate: DateComponents(year: 2026, month: 11, day: 20))
        var checked = reminder("a", item: 8, "Vacuum", completed: true, modified: after)
        checked.dueDate = entry.dueDate
        #expect(Sync.grocyChanges(entries: [entry], existing: [checked], lastSync: lastSync).doneChanges == [8: true])

        // After tracking, Grocy has the next due date, and the chore is still not done.
        let next = Sync.Entry(itemID: 8, title: "Vacuum", notes: nil, isDone: false, dueDate: DateComponents(year: 2026, month: 11, day: 27))
        let update = Sync.reminderChanges(entries: [next], existing: [checked]).updates
        #expect(update == [Sync.ReminderUpdate(reminderID: "a", entry: next)])
    }
}
