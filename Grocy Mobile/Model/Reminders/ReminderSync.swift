//
//  ReminderSync.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 19.11.26.
//

import Foundation

/// What syncs with a list in Reminders: a shopping list, the tasks or the chores.
nonisolated enum ReminderSyncTarget: Hashable, Sendable {
    case shoppingList(id: Int)
    case tasks
    case chores

    enum Kind: Sendable {
        case shoppingList, tasks, chores
    }

    var kind: Kind {
        switch self {
        case .shoppingList: .shoppingList
        case .tasks: .tasks
        case .chores: .chores
        }
    }

    /// The key the link and the last sync are stored under. Shopping lists use their ID, as in the first version.
    var storageKey: String {
        switch self {
        case .shoppingList(let id): String(id)
        case .tasks: "tasks"
        case .chores: "chores"
        }
    }

    /// The target in log messages.
    var logName: String {
        switch self {
        case .shoppingList(let id): "shopping list \(id)"
        case .tasks: "the tasks"
        case .chores: "the chores"
        }
    }

    init?(storageKey: String) {
        switch storageKey {
        case "tasks": self = .tasks
        case "chores": self = .chores
        default:
            guard let id = Int(storageKey) else { return nil }
            self = .shoppingList(id: id)
        }
    }

    /// The `@AppStorage` key of the automatic sync setting.
    static func settingKey(for kind: Kind) -> String {
        switch kind {
        case .shoppingList: "syncShoppingListToReminders"
        case .tasks: "syncTasksToReminders"
        case .chores: "syncChoresToReminders"
        }
    }

    /// The link each reminder carries to its Grocy object. It opens the matching screen in the app.
    var link: ReminderLink {
        switch self {
        case .shoppingList(let id): ReminderLink(host: "shoppinglist", path: "/list/\(id)", queryName: "item")
        case .tasks: ReminderLink(host: "tasks", path: "", queryName: "task")
        case .chores: ReminderLink(host: "chores", path: "", queryName: "chore")
        }
    }

    /// Reminders added in Reminders become new Grocy objects. Chores need a schedule, so they can't be added that way.
    var acceptsNewItems: Bool {
        kind != .chores
    }
}

/// The URL that links a reminder to its Grocy object, for example `grocy://shoppinglist/list/3?item=42` or `grocy://tasks?task=7`.
nonisolated struct ReminderLink: Equatable, Sendable {
    var host: String
    var path: String
    var queryName: String

    func url(itemID: Int) -> URL? {
        var components = URLComponents()
        components.scheme = "grocy"
        components.host = host
        components.path = path
        components.queryItems = [URLQueryItem(name: queryName, value: String(itemID))]
        return components.url
    }

    /// The linked object's ID, if the URL is a link of this kind.
    func itemID(from url: URL?) -> Int? {
        guard let url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            components.scheme == "grocy", components.host == host, components.path == path,
            let value = components.queryItems?.first(where: { $0.name == queryName })?.value
        else { return nil }
        return Int(value)
    }
}

/// The rules of the two-way sync between Grocy and a list in Reminders.
///
/// Grocy is the source of truth for the items, their names, notes and due dates. Reminders may change two things:
/// - **Checking off:** a reminder checked off or reopened since the last sync changes the item's done state in Grocy
///   (for a chore, checking off tracks an execution, and the reminder reopens with the next due date).
/// - **Adding:** a reminder added in Reminders (for example with Siri) becomes a new Grocy item.
///
/// Each reminder the app created carries a link to its Grocy object in its URL (see `ReminderLink`),
/// so it's updated in place instead of being deleted and created again.
/// The planner has no EventKit dependency, so the rules can be tested without the Reminders store.
nonisolated enum ReminderSync {
    /// A Grocy item, as it's shown in Reminders.
    struct Entry: Equatable, Sendable {
        var itemID: Int
        var title: String
        var notes: String?
        var isDone: Bool
        /// Year, month and day, plus hour and minute if the item has a time.
        var dueDate: DateComponents? = nil
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
        var dueDate: DateComponents? = nil
        var completionDate: Date? = nil
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
                if reminder.needsLink || reminder.title != entry.title || (reminder.notes ?? "") != (entry.notes ?? "")
                    || reminder.isCompleted != entry.isDone || reminder.dueDate != entry.dueDate
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

    // MARK: - Due dates

    /// Due date components as they're compared and stored: year, month and day, and hour and minute if there's a time.
    /// EventKit adds a calendar and a time zone to the components it returns, which would make every comparison fail.
    static func normalized(_ components: DateComponents?) -> DateComponents? {
        guard let components, let year = components.year, let month = components.month, let day = components.day else { return nil }
        var normalized = DateComponents(year: year, month: month, day: day)
        if let hour = components.hour {
            normalized.hour = hour
            normalized.minute = components.minute ?? 0
        }
        return normalized
    }

    /// The due date components of a date, with or without its time.
    static func dueDate(_ date: Date?, dateOnly: Bool, calendar: Calendar = .current) -> DateComponents? {
        guard let date else { return nil }
        let fields: Set<Calendar.Component> = dateOnly ? [.year, .month, .day] : [.year, .month, .day, .hour, .minute]
        return normalized(calendar.dateComponents(fields, from: date))
    }

    // MARK: - Entries

    /// The entry of a shopping list item: the product name (or the note) as title, the amount and the note below it.
    @MainActor
    static func entry(
        for item: ShoppingListItem,
        product: MDProduct?,
        quantityUnit: MDQuantityUnit?,
        roundUp: Bool,
        conversions: MDQuantityUnitConversions = []
    ) -> Entry {
        let amount = item.displayAmount(roundUp: roundUp, product: product, conversions: conversions)
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

    /// The entry of a task: its name, its description as notes, and its due day (Grocy's tasks have no time).
    @MainActor
    static func entry(for task: GrocyTask, calendar: Calendar = .current) -> Entry {
        Entry(
            itemID: task.id,
            title: task.name,
            notes: task.taskDescription.isEmpty ? nil : task.taskDescription,
            isDone: task.done,
            dueDate: dueDate(task.dueDate, dateOnly: true, calendar: calendar)
        )
    }

    /// The entry of a chore: never done, because checking it off tracks an execution and moves it to its next due date.
    @MainActor
    static func entry(for chore: Chore, calendar: Calendar = .current) -> Entry {
        Entry(
            itemID: chore.choreID,
            title: chore.choreName,
            notes: nil,
            isDone: false,
            dueDate: dueDate(chore.nextEstimatedExecutionTime, dateOnly: chore.trackDateOnly, calendar: calendar)
        )
    }
}
