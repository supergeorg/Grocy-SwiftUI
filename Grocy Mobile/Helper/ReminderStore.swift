//
//  ReminderStore.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 22.11.22.
//

import EventKit
import Foundation
import Observation
import SwiftData
import SwiftUI

#if os(iOS)
    import BackgroundTasks
#endif

nonisolated enum ReminderSyncError: LocalizedError, Equatable {
    case accessDenied
    case accessRestricted
    case noListSource
    case listReadOnly
    case failedReadingReminders

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return String(localized: "Grocy Mobile doesn't have access to Reminders.")
        case .accessRestricted:
            return String(localized: "This device doesn't allow access to Reminders.")
        case .noListSource:
            return String(localized: "There's no account in Reminders that can hold a new list.")
        case .listReadOnly:
            return String(localized: "The list in Reminders can't be changed.")
        case .failedReadingReminders:
            return String(localized: "Failed to read the reminders.")
        }
    }
}

/// The result of a sync, shown to the user.
struct ReminderSyncResult: Equatable {
    /// The name of the list in Reminders.
    var listTitle: String
    /// The list was created in Reminders by this sync.
    var createdList: Bool
    /// Items checked off, reopened or added in Reminders that changed Grocy.
    var changesFromReminders: Int
    /// Reminders created, updated or removed.
    var changesToReminders: Int
}

/// Mirrors Grocy shopping lists into lists in Reminders, in both directions (see `ShoppingListReminderSync` for the rules).
///
/// Each shopping list gets its own list in Reminders, linked by its calendar identifier, so renaming the list in Reminders keeps the link.
/// There's one `EKEventStore` for the whole app, because EventKit objects belong to the store that loaded them.
@Observable
final class ReminderStore {
    static let shared = ReminderStore()

    private static let calendarIdentifiersKey = "reminderListIdentifiers"
    private static let lastSyncDatesKey = "reminderListLastSyncDates"

    @ObservationIgnored let ekStore: EKEventStore
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var changeObserver: Task<Void, Never>?
    @ObservationIgnored private var pendingAutomaticSync: Task<Void, Never>?

    private(set) var authorizationStatus: EKAuthorizationStatus
    /// Shopping lists that are syncing right now.
    private(set) var syncingListIDs: Set<Int> = []
    /// Shopping list ID → calendar identifier of its list in Reminders.
    private(set) var calendarIdentifiers: [Int: String] {
        didSet { defaults.set(Dictionary(uniqueKeysWithValues: calendarIdentifiers.map { (String($0.key), $0.value) }), forKey: Self.calendarIdentifiersKey) }
    }
    /// Shopping list ID → end of the last successful sync.
    private(set) var lastSyncDates: [Int: Date] {
        didSet { defaults.set(Dictionary(uniqueKeysWithValues: lastSyncDates.map { (String($0.key), $0.value) }), forKey: Self.lastSyncDatesKey) }
    }

    init(eventStore: EKEventStore = EKEventStore(), defaults: UserDefaults = .standard) {
        self.ekStore = eventStore
        self.defaults = defaults
        self.authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        let identifiers = defaults.dictionary(forKey: Self.calendarIdentifiersKey) as? [String: String] ?? [:]
        self.calendarIdentifiers = Dictionary(uniqueKeysWithValues: identifiers.compactMap { key, value in Int(key).map { ($0, value) } })
        let dates = defaults.dictionary(forKey: Self.lastSyncDatesKey) as? [String: Date] ?? [:]
        self.lastSyncDates = Dictionary(uniqueKeysWithValues: dates.compactMap { key, value in Int(key).map { ($0, value) } })
    }

    // MARK: - Access

    var hasFullAccess: Bool {
        authorizationStatus == .fullAccess
    }

    /// Access was refused (or limited to adding reminders), so only the Settings app can grant it.
    var isAccessDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .writeOnly
    }

    /// The privacy settings where the user grants access to Reminders.
    static var privacySettingsURL: URL? {
        #if os(macOS)
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders")
        #else
            URL(string: UIApplication.openSettingsURLString)
        #endif
    }

    var isAccessRestricted: Bool {
        authorizationStatus == .restricted
    }

    func refreshAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        if status != authorizationStatus {
            authorizationStatus = status
        }
    }

    /// Asks for full access to Reminders when the user hasn't decided yet. Reminders have no write-only access.
    func requestAccess() async throws {
        refreshAuthorizationStatus()
        switch authorizationStatus {
        case .fullAccess:
            return
        case .notDetermined:
            let granted = try await ekStore.requestFullAccessToReminders()
            refreshAuthorizationStatus()
            guard granted else { throw ReminderSyncError.accessDenied }
        case .restricted:
            throw ReminderSyncError.accessRestricted
        default:
            throw ReminderSyncError.accessDenied
        }
    }

    // MARK: - Linked lists

    func isLinked(shoppingListID: Int) -> Bool {
        calendarIdentifiers[shoppingListID] != nil
    }

    func lastSync(shoppingListID: Int) -> Date? {
        lastSyncDates[shoppingListID]
    }

    /// Forgets the links to the lists in Reminders. The lists and their reminders stay in Reminders.
    func unlinkAll() {
        calendarIdentifiers = [:]
        lastSyncDates = [:]
    }

    private func linkedCalendar(shoppingListID: Int) -> EKCalendar? {
        guard let identifier = calendarIdentifiers[shoppingListID] else { return nil }
        return ekStore.calendar(withIdentifier: identifier)
    }

    /// The linked list in Reminders, or a new one. Returns whether it was created.
    private func calendar(for shoppingList: ShoppingListDescription) throws -> (calendar: EKCalendar, created: Bool) {
        if let calendar = linkedCalendar(shoppingListID: shoppingList.id) {
            guard calendar.allowsContentModifications else { throw ReminderSyncError.listReadOnly }
            return (calendar, false)
        }
        // The link is new or its list was deleted in Reminders, so the next sync starts fresh.
        lastSyncDates[shoppingList.id] = nil

        // Older versions exported to a list with this name, without remembering it. Reuse it instead of adding a second one.
        let title = "\(shoppingList.name) (Grocy Mobile)"
        if let existing = ekStore.calendars(for: .reminder).first(where: { $0.title == title && $0.allowsContentModifications }) {
            calendarIdentifiers[shoppingList.id] = existing.calendarIdentifier
            return (existing, false)
        }

        let calendar = EKCalendar(for: .reminder, eventStore: ekStore)
        calendar.title = title
        calendar.cgColor = Color(.GrocyColors.grocyBlue).resolve(in: EnvironmentValues()).cgColor
        // The account new reminders go to (usually iCloud), so the list shows up on the user's other devices.
        guard let source = ekStore.defaultCalendarForNewReminders()?.source ?? ekStore.sources.first(where: { $0.sourceType == .local }) else {
            throw ReminderSyncError.noListSource
        }
        calendar.source = source
        try ekStore.saveCalendar(calendar, commit: true)
        calendarIdentifiers[shoppingList.id] = calendar.calendarIdentifier
        GrocyLogger.info("Created the Reminders list \"\(title)\".")
        return (calendar, true)
    }

    // MARK: - Reading and writing reminders

    private func fetchReminders(in calendar: EKCalendar, listID: Int) async throws -> [ShoppingListReminderSync.ExistingReminder] {
        try await Self.fetchSnapshots(store: ekStore, predicate: ekStore.predicateForReminders(in: [calendar]), listID: listID)
    }

    /// The completion handler runs on a background queue, so the reminders are turned into `Sendable` snapshots there.
    private nonisolated static func fetchSnapshots(
        store: EKEventStore,
        predicate: NSPredicate,
        listID: Int
    ) async throws -> [ShoppingListReminderSync.ExistingReminder] {
        try await withCheckedThrowingContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                guard let reminders else {
                    continuation.resume(throwing: ReminderSyncError.failedReadingReminders)
                    return
                }
                let snapshots = reminders.map { reminder in
                    ShoppingListReminderSync.ExistingReminder(
                        id: reminder.calendarItemIdentifier,
                        itemID: ShoppingListReminderSync.itemID(from: reminder.url, listID: listID),
                        title: reminder.title ?? "",
                        notes: reminder.notes,
                        isCompleted: reminder.isCompleted,
                        lastModified: reminder.lastModifiedDate
                    )
                }
                continuation.resume(returning: snapshots)
            }
        }
    }

    /// Saves all changes in one commit. On failure nothing is saved.
    private func apply(_ changes: ShoppingListReminderSync.ReminderChanges, in calendar: EKCalendar, listID: Int) throws {
        guard !changes.isEmpty else { return }
        do {
            for reminderID in changes.removals {
                if let reminder = ekStore.calendarItem(withIdentifier: reminderID) as? EKReminder {
                    try ekStore.remove(reminder, commit: false)
                }
            }
            for update in changes.updates {
                guard let reminder = ekStore.calendarItem(withIdentifier: update.reminderID) as? EKReminder else { continue }
                configure(reminder, with: update.entry, listID: listID)
                try ekStore.save(reminder, commit: false)
            }
            for entry in changes.creates {
                let reminder = EKReminder(eventStore: ekStore)
                reminder.calendar = calendar
                configure(reminder, with: entry, listID: listID)
                try ekStore.save(reminder, commit: false)
            }
            try ekStore.commit()
        } catch {
            ekStore.reset()
            throw error
        }
    }

    private func configure(_ reminder: EKReminder, with entry: ShoppingListReminderSync.Entry, listID: Int) {
        reminder.title = entry.title
        reminder.notes = entry.notes
        reminder.url = ShoppingListReminderSync.url(listID: listID, itemID: entry.itemID)
        if reminder.isCompleted != entry.isDone {
            reminder.isCompleted = entry.isDone
        }
    }

    // MARK: - Sync

    /// Syncs a shopping list with its list in Reminders, which is created on the first sync.
    /// - Parameter requestAccess: Ask for access to Reminders if the user hasn't decided yet. Only for syncs the user started.
    /// - Returns: `nil` if the list is already syncing.
    @discardableResult
    func sync(shoppingList: ShoppingListDescription, grocyVM: GrocyViewModel, requestAccess: Bool) async throws -> ReminderSyncResult? {
        let listID = shoppingList.id
        guard !syncingListIDs.contains(listID) else { return nil }
        syncingListIDs.insert(listID)
        defer { syncingListIDs.remove(listID) }

        if requestAccess {
            try await self.requestAccess()
        } else {
            refreshAuthorizationStatus()
            guard hasFullAccess else { throw ReminderSyncError.accessDenied }
        }

        // Start from the server's state, so new items get free IDs and nothing is synced from an old cache.
        await grocyVM.requestData(objects: [.shopping_list, .products, .quantity_units])

        let (calendar, createdList) = try calendar(for: shoppingList)
        let lastSync = lastSyncDates[listID]
        var existing = try await fetchReminders(in: calendar, listID: listID)

        // Reminders → Grocy
        let grocyChanges = ShoppingListReminderSync.grocyChanges(entries: try entries(listID: listID, grocyVM: grocyVM), existing: existing, lastSync: lastSync)
        if !grocyChanges.isEmpty {
            existing = try await applyToGrocy(grocyChanges, existing: existing, listID: listID, grocyVM: grocyVM)
        }

        // Grocy → Reminders
        let reminderChanges = ShoppingListReminderSync.reminderChanges(
            entries: try entries(listID: listID, grocyVM: grocyVM),
            existing: existing,
            removeUnlinked: lastSync == nil
        )
        try apply(reminderChanges, in: calendar, listID: listID)
        lastSyncDates[listID] = Date()

        let changesFromReminders = grocyChanges.doneChanges.count + grocyChanges.newItems.count
        GrocyLogger.info(
            "Syncing shopping list \(listID) with Reminders was successful. \(changesFromReminders) changes from Reminders, \(reminderChanges.count) to Reminders."
        )
        return ReminderSyncResult(
            listTitle: calendar.title,
            createdList: createdList,
            changesFromReminders: changesFromReminders,
            changesToReminders: reminderChanges.count
        )
    }

    /// The entries of the list's items, from SwiftData.
    private func entries(listID: Int, grocyVM: GrocyViewModel) throws -> [ShoppingListReminderSync.Entry] {
        let context = grocyVM.modelContext
        let items = try context.fetch(FetchDescriptor<ShoppingListItem>(predicate: #Predicate { $0.shoppingListID == listID }, sortBy: [SortDescriptor(\.id)]))
        let products = Dictionary(try context.fetch(FetchDescriptor<MDProduct>()).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let quantityUnits = Dictionary(try context.fetch(FetchDescriptor<MDQuantityUnit>()).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let roundUp = try context.fetch(FetchDescriptor<GrocyUserSettings>()).first?.shoppingListRoundUp ?? false
        return items.map { item in
            ShoppingListReminderSync.entry(
                for: item,
                product: item.productID.flatMap { products[$0] },
                quantityUnit: item.quID.flatMap { quantityUnits[$0] },
                roundUp: roundUp
            )
        }
    }

    /// Writes the changes from Reminders to Grocy and resyncs. Returns the reminders with the new items linked.
    private func applyToGrocy(
        _ changes: ShoppingListReminderSync.GrocyChanges,
        existing: [ShoppingListReminderSync.ExistingReminder],
        listID: Int,
        grocyVM: GrocyViewModel
    ) async throws -> [ShoppingListReminderSync.ExistingReminder] {
        var existing = existing
        for (itemID, done) in changes.doneChanges.sorted(by: { $0.key < $1.key }) {
            try await grocyVM.putMDObjectWithID(object: .shopping_list, id: itemID, content: ShoppingListItemDonePUT(done: done))
        }
        for reminder in changes.newItems {
            let item = ShoppingListNoteItemPOST(shoppingListID: listID, note: reminder.title, amount: 1, done: reminder.isCompleted)
            let created = try await grocyVM.postMDObject(object: .shopping_list, content: item)
            if let index = existing.firstIndex(where: { $0.id == reminder.id }) {
                existing[index].itemID = created.createdObjectID
                existing[index].needsLink = true
            }
        }
        // Writes in the same second as the last sync don't change Grocy's db-changed-time, so force the reload.
        grocyVM.timeStampsObjects[.shopping_list] = nil
        await grocyVM.requestData(objects: [.shopping_list])
        return existing
    }

    // MARK: - Automatic sync

    /// The identifier of the background refresh task, also listed in `BGTaskSchedulerPermittedIdentifiers`.
    static let backgroundTaskIdentifier = "georgappdev.Grocy.reminderSync"
    /// How often the list is synced while the app is open. A sync without changes only asks Grocy for its `db-changed-time`, so it's cheap.
    static let foregroundSyncInterval: Duration = .seconds(5 * 60)
    /// The earliest time for the next background sync. iOS decides when it actually runs.
    static let backgroundSyncInterval: TimeInterval = 15 * 60

    @ObservationIgnored private var periodicSync: Task<Void, Never>?
    /// The app's view model, for the syncs the system starts in the background.
    @ObservationIgnored private weak var grocyVM: GrocyViewModel?

    /// The shopping list chosen in the settings for the automatic sync, if it's on.
    var automaticSyncListID: Int? {
        guard defaults.bool(forKey: "syncShoppingListToReminders") else { return nil }
        let listID = defaults.integer(forKey: "shoppingListToSyncID")
        return listID > 0 ? listID : nil
    }

    /// Syncs the shopping list chosen in the settings, if the automatic sync is on and the app has access.
    /// Called after the shopping list was reloaded, when Reminders changed, and periodically while the app is open. It never asks for access.
    func syncAutomaticallyIfEnabled(grocyVM: GrocyViewModel) {
        guard let listID = automaticSyncListID, !syncingListIDs.contains(listID) else { return }
        refreshAuthorizationStatus()
        guard hasFullAccess else { return }
        pendingAutomaticSync?.cancel()
        pendingAutomaticSync = Task { [weak self, weak grocyVM] in
            // Reminders posts several change notifications in a row, so wait for them to settle.
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled, let self, let grocyVM else { return }
            await self.syncAutomaticList(listID: listID, grocyVM: grocyVM)
        }
    }

    private func syncAutomaticList(listID: Int, grocyVM: GrocyViewModel) async {
        // Right after launch, the server isn't set up yet.
        await grocyVM.waitForLogin()
        let descriptor = FetchDescriptor<ShoppingListDescription>(predicate: #Predicate { $0.id == listID })
        guard let shoppingList = try? grocyVM.modelContext.fetch(descriptor).first else { return }
        do {
            try await sync(shoppingList: shoppingList, grocyVM: grocyVM, requestAccess: false)
        } catch {
            GrocyLogger.error("Syncing shopping list \(listID) with Reminders automatically failed. \(error)")
        }
    }

    /// Syncs automatically when the reminders change, for example after checking items off in Reminders.
    func observeChanges(grocyVM: GrocyViewModel) {
        self.grocyVM = grocyVM
        guard changeObserver == nil else { return }
        changeObserver = Task { [weak self, weak grocyVM] in
            for await _ in NotificationCenter.default.notifications(named: .EKEventStoreChanged) {
                guard let self, let grocyVM else { return }
                self.syncAutomaticallyIfEnabled(grocyVM: grocyVM)
            }
        }
    }

    /// Syncs now and then every few minutes, while the app is in the foreground.
    /// Covers changes made on the server by someone else, which the app doesn't otherwise notice.
    func startPeriodicSync() {
        periodicSync?.cancel()
        periodicSync = Task { [weak self] in
            while !Task.isCancelled {
                if let self, let grocyVM = self.grocyVM {
                    self.syncAutomaticallyIfEnabled(grocyVM: grocyVM)
                } else {
                    return
                }
                try? await Task.sleep(for: Self.foregroundSyncInterval)
            }
        }
    }

    func stopPeriodicSync() {
        periodicSync?.cancel()
        periodicSync = nil
    }

    #if os(iOS)
        /// Asks iOS to wake the app in the background for the next sync, or cancels the request when the automatic sync is off.
        func scheduleBackgroundSync() {
            guard automaticSyncListID != nil else {
                BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.backgroundTaskIdentifier)
                return
            }
            let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
            request.earliestBeginDate = Date(timeIntervalSinceNow: Self.backgroundSyncInterval)
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                // Fails on the simulator, and when Background App Refresh is off.
                GrocyLogger.warning("Scheduling the background sync with Reminders failed. \(error)")
            }
        }
    #endif

    /// The background refresh task: syncs the list once and schedules the next run.
    func syncInBackground() async {
        #if os(iOS)
            scheduleBackgroundSync()
        #endif
        guard let listID = automaticSyncListID, let grocyVM, !syncingListIDs.contains(listID) else { return }
        refreshAuthorizationStatus()
        guard hasFullAccess else { return }
        await syncAutomaticList(listID: listID, grocyVM: grocyVM)
    }
}

/// Marks a shopping list item as done or not done.
struct ShoppingListItemDonePUT: Codable {
    let done: Bool

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(done ? 1 : 0, forKey: .done)
    }
}

/// A free-text shopping list item, added from Reminders.
struct ShoppingListNoteItemPOST: Codable {
    let shoppingListID: Int
    let note: String
    let amount: Double
    let done: Bool

    enum CodingKeys: String, CodingKey {
        case shoppingListID = "shopping_list_id"
        case note, amount, done
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(shoppingListID, forKey: .shoppingListID)
        try container.encode(note, forKey: .note)
        try container.encode(amount, forKey: .amount)
        try container.encode(done ? 1 : 0, forKey: .done)
    }
}
