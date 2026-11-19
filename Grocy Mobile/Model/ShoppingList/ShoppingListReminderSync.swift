//
//  ShoppingListReminderSync.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 19.11.26.
//

import Foundation

/// The rules of the two-way sync between a Grocy shopping list and a list in Reminders.
///
/// Grocy is the source of truth for the items, their names, amounts and notes. Reminders may change two things:
/// - **Checking off:** a reminder checked off or reopened since the last sync changes the item's done state in Grocy.
/// - **Adding:** a reminder added in Reminders (for example with Siri) becomes a new Grocy item, with its title as the note.
///
/// Each reminder the app created carries the item's link in its URL (`grocy://shoppinglist/list/<list>?item=<item>`),
/// so it's updated in place instead of being deleted and created again.
/// The planner has no EventKit dependency, so the rules can be tested without the Reminders store.
nonisolated enum ShoppingListReminderSync {
    /// A Grocy shopping list item, as it's shown in Reminders.
    struct Entry: Equatable, Sendable {
        var itemID: Int
        var title: String
        var notes: String?
        var isDone: Bool
    }

    /// A reminder of the synced list in Reminders.
    struct ExistingReminder: Equatable, Sendable {
        /// `calendarItemIdentifier` of the reminder.
        var id: String
        /// The linked Grocy item, read from the reminder's URL. `nil` for reminders added in Reminders.
        var itemID: Int?
        var title: String
        var notes: String?
        var isCompleted: Bool
        var lastModified: Date?
        /// The reminder was just linked to a new Grocy item, so its URL still has to be set.
        var needsLink: Bool = false
    }

    /// What has to change in Grocy, before the reminders are updated.
    struct GrocyChanges: Equatable, Sendable {
        /// Done state per item ID, for reminders checked off or reopened in Reminders since the last sync.
        var doneChanges: [Int: Bool] = [:]
        /// Reminders added in Reminders that become new Grocy items.
        var newItems: [ExistingReminder] = []

        var isEmpty: Bool { doneChanges.isEmpty && newItems.isEmpty }
    }

    /// What has to change in Reminders, once Grocy is up to date.
    struct ReminderChanges: Equatable, Sendable {
        var creates: [Entry] = []
        /// The reminder ID and the entry it has to show.
        var updates: [ReminderUpdate] = []
        /// Reminders whose Grocy item doesn't exist anymore, and duplicates.
        var removals: [String] = []

        var isEmpty: Bool { creates.isEmpty && updates.isEmpty && removals.isEmpty }
        var count: Int { creates.count + updates.count + removals.count }
    }

    struct ReminderUpdate: Equatable, Sendable {
        var reminderID: String
        var entry: Entry
    }

    // MARK: - Planning

    /// The changes Reminders brings into Grocy.
    /// - Parameter lastSync: The end of the last sync of this list. Without one (the first sync), Grocy wins: done states aren't taken over,
    ///   and reminders without a link aren't added, because they're left over from the old one-way export.
    static func grocyChanges(entries: [Entry], existing: [ExistingReminder], lastSync: Date?) -> GrocyChanges {
        var changes = GrocyChanges()
        guard let lastSync else { return changes }
        let entriesByItem = Dictionary(entries.map { ($0.itemID, $0) }, uniquingKeysWith: { first, _ in first })
        var seenItems: Set<Int> = []

        for reminder in existing {
            guard let itemID = reminder.itemID else {
                // Added in Reminders. Empty titles are left alone, the item would have no name.
                if !reminder.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    changes.newItems.append(reminder)
                }
                continue
            }
            // Only the first reminder of an item counts, duplicates are removed later.
            guard seenItems.insert(itemID).inserted, let entry = entriesByItem[itemID] else { continue }
            guard let lastModified = reminder.lastModified, lastModified > lastSync else { continue }
            if reminder.isCompleted != entry.isDone {
                changes.doneChanges[itemID] = reminder.isCompleted
            }
        }
        return changes
    }

    /// The changes that make the reminders match the Grocy entries.
    /// Call it after the Grocy changes are applied, with the new items linked (`itemID` and `needsLink` set) in `existing`.
    /// - Parameter removeUnlinked: Remove the reminders without a link, on the first sync (see `grocyChanges`).
    static func reminderChanges(entries: [Entry], existing: [ExistingReminder], removeUnlinked: Bool = false) -> ReminderChanges {
        var changes = ReminderChanges()
        var remindersByItem: [Int: ExistingReminder] = [:]

        for reminder in existing {
            guard let itemID = reminder.itemID else {
                if removeUnlinked {
                    changes.removals.append(reminder.id)
                }
                continue
            }
            if remindersByItem[itemID] == nil {
                remindersByItem[itemID] = reminder
            } else {
                changes.removals.append(reminder.id)
            }
        }

        let itemIDs = Set(entries.map(\.itemID))
        for (itemID, reminder) in remindersByItem where !itemIDs.contains(itemID) {
            changes.removals.append(reminder.id)
        }

        for entry in entries {
            if let reminder = remindersByItem[entry.itemID] {
                if reminder.needsLink || reminder.title != entry.title || (reminder.notes ?? "") != (entry.notes ?? "") || reminder.isCompleted != entry.isDone
                {
                    changes.updates.append(ReminderUpdate(reminderID: reminder.id, entry: entry))
                }
            } else {
                changes.creates.append(entry)
            }
        }
        changes.removals.sort()
        return changes
    }

    // MARK: - Links

    /// The URL a reminder carries to link it to its Grocy item. It opens the shopping list in the app.
    static func url(listID: Int, itemID: Int) -> URL? {
        var components = URLComponents()
        components.scheme = "grocy"
        components.host = "shoppinglist"
        components.path = "/list/\(listID)"
        components.queryItems = [URLQueryItem(name: "item", value: String(itemID))]
        return components.url
    }

    /// The linked item ID, if the URL links to an item of this list.
    static func itemID(from url: URL?, listID: Int) -> Int? {
        guard let url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            components.scheme == "grocy", components.host == "shoppinglist", components.path == "/list/\(listID)",
            let value = components.queryItems?.first(where: { $0.name == "item" })?.value
        else { return nil }
        return Int(value)
    }

    // MARK: - Entries

    /// The entry of a shopping list item: the product name (or the note) as title, the amount and the note below it.
    @MainActor
    static func entry(for item: ShoppingListItem, product: MDProduct?, quantityUnit: MDQuantityUnit?, roundUp: Bool) -> Entry {
        let amount = item.displayAmount(roundUp: roundUp)
        var amountText = amount.formattedAmount
        if let quantityUnit {
            amountText += " \(quantityUnit.getName(amount: amount))"
        }
        let title: String
        var notes: [String] = []
        if let product {
            title = product.name
            notes.append(amountText)
            if !item.note.isEmpty {
                notes.append(item.note)
            }
        } else {
            // A free-text item: the note is its name. Its amount is only worth showing when it isn't one.
            title = item.note
            if amount != 1 || quantityUnit != nil {
                notes.append(amountText)
            }
        }
        return Entry(itemID: item.id, title: title, notes: notes.isEmpty ? nil : notes.joined(separator: "\n"), isDone: item.done)
    }
}
