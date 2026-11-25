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

/// Mirrors Grocy shopping lists, tasks and chores into lists in Reminders, in both directions (see `ReminderSync` for the rules).
///
/// Each shopping list gets its own list in Reminders, and so do the tasks and the chores. Lists are linked by their calendar identifier,
/// so renaming a list in Reminders keeps the link.
/// There's one `EKEventStore` for the whole app, because EventKit objects belong to the store that loaded them.
@Observable
final class ReminderStore {
    static let shared = ReminderStore()

    private static let calendarIdentifiersKey = "reminderListIdentifiers"
    private static let lastSyncDatesKey = "reminderListLastSyncDates"

    @ObservationIgnored let ekStore: EKEventStore
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var changeObserver: Task<Void, Never>?
    @ObservationIgnored private var pendingAutomaticSyncs: [ReminderSyncTarget: Task<Void, Never>] = [:]

    private(set) var authorizationStatus: EKAuthorizationStatus
    /// Targets that are syncing right now.
    private(set) var syncingTargets: Set<ReminderSyncTarget> = []
    /// Target → calendar identifier of its list in Reminders.
    private(set) var calendarIdentifiers: [ReminderSyncTarget: String] {
        didSet {
            defaults.set(Dictionary(uniqueKeysWithValues: calendarIdentifiers.map { ($0.key.storageKey, $0.value) }), forKey: Self.calendarIdentifiersKey)
        }
    }
    /// Target → end of the last successful sync.
    private(set) var lastSyncDates: [ReminderSyncTarget: Date] {
        didSet { defaults.set(Dictionary(uniqueKeysWithValues: lastSyncDates.map { ($0.key.storageKey, $0.value) }), forKey: Self.lastSyncDatesKey) }
    }

    init(eventStore: EKEventStore = EKEventStore(), defaults: UserDefaults = .standard) {
        self.ekStore = eventStore
        self.defaults = defaults
        self.authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        let identifiers = defaults.dictionary(forKey: Self.calendarIdentifiersKey) as? [String: String] ?? [:]
        self.calendarIdentifiers = Dictionary(
            identifiers.compactMap { key, value in ReminderSyncTarget(storageKey: key).map { ($0, value) } },
            uniquingKeysWith: { first, _ in first }
        )
        let dates = defaults.dictionary(forKey: Self.lastSyncDatesKey) as? [String: Date] ?? [:]
        self.lastSyncDates = Dictionary(
            dates.compactMap { key, value in ReminderSyncTarget(storageKey: key).map { ($0, value) } },
            uniquingKeysWith: { first, _ in first }
        )
    }

    // MARK: - Access

    var hasFullAccess: Bool {
        authorizationStatus == .fullAccess
    }

    /// Access was refused (or limited to adding reminders), so only the Settings app can grant it.
    var isAccessDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .writeOnly
    }

    var isAccessRestricted: Bool {
        authorizationStatus == .restricted
    }

    /// The privacy settings where the user grants access to Reminders.
    static var privacySettingsURL: URL? {
        #if os(macOS)
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders")
        #else
            URL(string: UIApplication.openSettingsURLString)
        #endif
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

    func isSyncing(_ target: ReminderSyncTarget) -> Bool {
        syncingTargets.contains(target)
    }

    func isLinked(_ target: ReminderSyncTarget) -> Bool {
        calendarIdentifiers[target] != nil
    }

    func lastSync(_ target: ReminderSyncTarget) -> Date? {
        lastSyncDates[target]
    }

    func isLinked(shoppingListID: Int) -> Bool {
        isLinked(.shoppingList(id: shoppingListID))
    }

    func lastSync(shoppingListID: Int) -> Date? {
        lastSync(.shoppingList(id: shoppingListID))
    }

    /// Whether any list of this kind is linked.
    func hasLinkedList(of kind: ReminderSyncTarget.Kind) -> Bool {
        calendarIdentifiers.keys.contains { $0.kind == kind }
    }

    /// Forgets the links of this kind and turns its automatic sync off. The lists and their reminders stay in Reminders.
    func unlink(_ kind: ReminderSyncTarget.Kind) {
        calendarIdentifiers = calendarIdentifiers.filter { $0.key.kind != kind }
        lastSyncDates = lastSyncDates.filter { $0.key.kind != kind }
        defaults.set(false, forKey: ReminderSyncTarget.settingKey(for: kind))
    }

    /// Forgets all links and turns the automatic syncs off, for example when logging out.
    func unlinkAll() {
        unlink(.shoppingList)
        unlink(.tasks)
        unlink(.chores)
    }

    private func linkedCalendar(_ target: ReminderSyncTarget) -> EKCalendar? {
        guard let identifier = calendarIdentifiers[target] else { return nil }
        return ekStore.calendar(withIdentifier: identifier)
    }

    /// The name of the target's list in Reminders.
    private func listTitle(for target: ReminderSyncTarget, grocyVM: GrocyViewModel) -> String {
        let name: String
        switch target {
        case .shoppingList(let id):
            let descriptor = FetchDescriptor<ShoppingListDescription>(predicate: #Predicate { $0.id == id })
            name = (try? grocyVM.modelContext.fetch(descriptor).first?.name) ?? String(localized: "Shopping list")
        case .tasks:
            name = String(localized: "Tasks")
        case .chores:
            name = String(localized: "Chores")
        }
        return "\(name) (Grocy Mobile)"
    }

    private func listColor(for target: ReminderSyncTarget) -> Color {
        switch target.kind {
        case .shoppingList: Color(.GrocyColors.grocyBlue)
        case .tasks: Color(.GrocyColors.grocyGreen)
        case .chores: Color(.GrocyColors.grocyTurquoise)
        }
    }

    /// The linked list in Reminders, or a new one. Returns whether it was created.
    private func calendar(for target: ReminderSyncTarget, title: String) throws -> (calendar: EKCalendar, created: Bool) {
        if let calendar = linkedCalendar(target) {
            guard calendar.allowsContentModifications else { throw ReminderSyncError.listReadOnly }
            return (calendar, false)
        }
        // The link is new or its list was deleted in Reminders, so the next sync starts fresh.
        lastSyncDates[target] = nil

        // Older versions exported to a list with this name, without remembering it. Reuse it instead of adding a second one.
        if let existing = ekStore.calendars(for: .reminder).first(where: { $0.title == title && $0.allowsContentModifications }) {
            calendarIdentifiers[target] = existing.calendarIdentifier
            return (existing, false)
        }

        let calendar = EKCalendar(for: .reminder, eventStore: ekStore)
        calendar.title = title
        calendar.cgColor = listColor(for: target).resolve(in: EnvironmentValues()).cgColor
        // The account new reminders go to (usually iCloud), so the list shows up on the user's other devices.
        guard let source = ekStore.defaultCalendarForNewReminders()?.source ?? ekStore.sources.first(where: { $0.sourceType == .local }) else {
            throw ReminderSyncError.noListSource
        }
        calendar.source = source
        try ekStore.saveCalendar(calendar, commit: true)
        calendarIdentifiers[target] = calendar.calendarIdentifier
        GrocyLogger.info("Created the Reminders list \"\(title)\".")
        return (calendar, true)
    }

    // MARK: - Reading and writing reminders

    private func fetchReminders(in calendar: EKCalendar, link: ReminderLink) async throws -> [ReminderSync.ExistingReminder] {
        try await Self.fetchSnapshots(store: ekStore, predicate: ekStore.predicateForReminders(in: [calendar]), link: link)
    }

    /// The completion handler runs on a background queue, so the reminders are turned into `Sendable` snapshots there.
    private nonisolated static func fetchSnapshots(
        store: EKEventStore,
        predicate: NSPredicate,
        link: ReminderLink
    ) async throws -> [ReminderSync.ExistingReminder] {
        try await withCheckedThrowingContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                guard let reminders else {
                    continuation.resume(throwing: ReminderSyncError.failedReadingReminders)
                    return
                }
                let snapshots = reminders.map { reminder in
                    ReminderSync.ExistingReminder(
                        id: reminder.calendarItemIdentifier,
                        itemID: link.itemID(from: reminder.url),
                        title: reminder.title ?? "",
                        notes: reminder.notes,
                        isCompleted: reminder.isCompleted,
                        lastModified: reminder.lastModifiedDate,
                        dueDate: ReminderSync.normalized(reminder.dueDateComponents),
                        completionDate: reminder.completionDate
                    )
                }
                continuation.resume(returning: snapshots)
            }
        }
    }

    /// Saves all changes in one commit. On failure nothing is saved.
    private func apply(_ changes: ReminderSync.ReminderChanges, in calendar: EKCalendar, link: ReminderLink) throws {
        guard !changes.isEmpty else { return }
        do {
            for reminderID in changes.removals {
                if let reminder = ekStore.calendarItem(withIdentifier: reminderID) as? EKReminder {
                    try ekStore.remove(reminder, commit: false)
                }
            }
            for update in changes.updates {
                guard let reminder = ekStore.calendarItem(withIdentifier: update.reminderID) as? EKReminder else { continue }
                configure(reminder, with: update.entry, link: link)
                try ekStore.save(reminder, commit: false)
            }
            for entry in changes.creates {
                let reminder = EKReminder(eventStore: ekStore)
                reminder.calendar = calendar
                configure(reminder, with: entry, link: link)
                try ekStore.save(reminder, commit: false)
            }
            try ekStore.commit()
        } catch {
            ekStore.reset()
            throw error
        }
    }

    private func configure(_ reminder: EKReminder, with entry: ReminderSync.Entry, link: ReminderLink) {
        reminder.title = entry.title
        reminder.notes = entry.notes
        reminder.url = link.url(itemID: entry.itemID)
        if ReminderSync.normalized(reminder.dueDateComponents) != entry.dueDate {
            reminder.dueDateComponents = entry.dueDate
        }
        if reminder.isCompleted != entry.isDone {
            reminder.isCompleted = entry.isDone
        }
    }

    // MARK: - Sync

    /// Syncs a shopping list with its list in Reminders, which is created on the first sync.
    @discardableResult
    func sync(shoppingList: ShoppingListDescription, grocyVM: GrocyViewModel, requestAccess: Bool) async throws -> ReminderSyncResult? {
        try await sync(.shoppingList(id: shoppingList.id), grocyVM: grocyVM, requestAccess: requestAccess)
    }

    /// Syncs a target with its list in Reminders, which is created on the first sync.
    /// - Parameter requestAccess: Ask for access to Reminders if the user hasn't decided yet. Only for syncs the user started.
    /// - Returns: `nil` if the target is already syncing.
    @discardableResult
    func sync(_ target: ReminderSyncTarget, grocyVM: GrocyViewModel, requestAccess: Bool) async throws -> ReminderSyncResult? {
        guard !syncingTargets.contains(target) else { return nil }
        syncingTargets.insert(target)
        defer { syncingTargets.remove(target) }

        if requestAccess {
            try await self.requestAccess()
        } else {
            refreshAuthorizationStatus()
            guard hasFullAccess else { throw ReminderSyncError.accessDenied }
        }

        // Start from the server's state, so new items get free IDs and nothing is synced from an old cache.
        switch target {
        case .shoppingList:
            await grocyVM.requestData(objects: [.shopping_list, .products, .quantity_units])
        case .tasks:
            await grocyVM.requestData(objects: [.tasks])
        case .chores:
            await grocyVM.requestData(additionalObjects: [.chores])
        }

        let (calendar, createdList) = try calendar(for: target, title: listTitle(for: target, grocyVM: grocyVM))
        let lastSync = lastSyncDates[target]
        var existing = try await fetchReminders(in: calendar, link: target.link)

        // Reminders → Grocy
        var grocyChanges = ReminderSync.grocyChanges(
            entries: try entries(for: target, existing: existing, grocyVM: grocyVM),
            existing: existing,
            lastSync: lastSync
        )
        if !target.acceptsNewItems {
            grocyChanges.newItems = []
        }
        if !grocyChanges.isEmpty {
            existing = try await applyToGrocy(grocyChanges, existing: existing, target: target, grocyVM: grocyVM)
        }

        // Grocy → Reminders
        let reminderChanges = ReminderSync.reminderChanges(
            entries: try entries(for: target, existing: existing, grocyVM: grocyVM),
            existing: existing,
            removeUnlinked: lastSync == nil
        )
        try apply(reminderChanges, in: calendar, link: target.link)
        lastSyncDates[target] = Date()

        let changesFromReminders = grocyChanges.doneChanges.count + grocyChanges.newItems.count
        GrocyLogger.info(
            "Syncing \(target.logName) with Reminders was successful. \(changesFromReminders) changes from Reminders, \(reminderChanges.count) to Reminders."
        )
        return ReminderSyncResult(
            listTitle: calendar.title,
            createdList: createdList,
            changesFromReminders: changesFromReminders,
            changesToReminders: reminderChanges.count
        )
    }

    /// The entries of the target's items, from SwiftData.
    private func entries(for target: ReminderSyncTarget, existing: [ReminderSync.ExistingReminder], grocyVM: GrocyViewModel) throws
        -> [ReminderSync.Entry]
    {
        let context = grocyVM.modelContext
        switch target {
        case .shoppingList(let listID):
            let items = try context.fetch(
                FetchDescriptor<ShoppingListItem>(predicate: #Predicate { $0.shoppingListID == listID }, sortBy: [SortDescriptor(\.id)])
            )
            let products = Dictionary(try context.fetch(FetchDescriptor<MDProduct>()).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            let quantityUnits = Dictionary(
                try context.fetch(FetchDescriptor<MDQuantityUnit>()).map { ($0.id, $0) },
                uniquingKeysWith: { first, _ in first }
            )
            let roundUp = try context.fetch(FetchDescriptor<GrocyUserSettings>()).first?.shoppingListRoundUp ?? false
            let conversions = try context.fetch(FetchDescriptor<MDQuantityUnitConversion>())
            return items.map { item in
                ReminderSync.entry(
                    for: item,
                    product: item.productID.flatMap { products[$0] },
                    quantityUnit: item.quID.flatMap { quantityUnits[$0] },
                    roundUp: roundUp,
                    conversions: conversions
                )
            }
        case .tasks:
            // Done tasks only stay as completed reminders, they don't get new ones. Otherwise the list fills up with every task ever done.
            let linkedTaskIDs = Set(existing.compactMap(\.itemID))
            let tasks = try context.fetch(FetchDescriptor<GrocyTask>(sortBy: [SortDescriptor(\.id)]))
            return tasks.filter { !$0.done || linkedTaskIDs.contains($0.id) }.map { ReminderSync.entry(for: $0) }
        case .chores:
            let chores = try context.fetch(FetchDescriptor<Chore>(sortBy: [SortDescriptor(\.choreID)]))
            return chores.map { ReminderSync.entry(for: $0) }
        }
    }

    /// Writes the changes from Reminders to Grocy and resyncs. Returns the reminders with the new items linked.
    private func applyToGrocy(
        _ changes: ReminderSync.GrocyChanges,
        existing: [ReminderSync.ExistingReminder],
        target: ReminderSyncTarget,
        grocyVM: GrocyViewModel
    ) async throws -> [ReminderSync.ExistingReminder] {
        var existing = existing
        let completionDates = Dictionary(
            existing.compactMap { reminder in reminder.itemID.map { ($0, reminder.completionDate ?? Date()) } },
            uniquingKeysWith: { first, _ in first }
        )
        func link(_ reminder: ReminderSync.ExistingReminder, to itemID: Int) {
            if let index = existing.firstIndex(where: { $0.id == reminder.id }) {
                existing[index].itemID = itemID
                existing[index].needsLink = true
            }
        }

        // Writes in the same second as the last sync don't change Grocy's db-changed-time, so the reloads are forced.
        switch target {
        case .shoppingList(let listID):
            for (itemID, done) in changes.doneChanges.sorted(by: { $0.key < $1.key }) {
                try await grocyVM.putMDObjectWithID(object: .shopping_list, id: itemID, content: ShoppingListItemDonePUT(done: done))
            }
            for reminder in changes.newItems {
                let item = ShoppingListNoteItemPOST(shoppingListID: listID, note: reminder.title, amount: 1, done: reminder.isCompleted)
                link(reminder, to: try await grocyVM.postMDObject(object: .shopping_list, content: item).createdObjectID)
            }
            grocyVM.timeStampsObjects[.shopping_list] = nil
            await grocyVM.requestData(objects: [.shopping_list])

        case .tasks:
            for (taskID, done) in changes.doneChanges.sorted(by: { $0.key < $1.key }) {
                if done {
                    let doneTime = (completionDates[taskID] ?? Date()).grocyDateTimeString
                    try await grocyVM.executeTask(taskID: taskID, content: TaskExecuteModel(doneTime: doneTime))
                } else {
                    try await grocyVM.undoTask(taskID: taskID)
                }
            }
            for reminder in changes.newItems {
                let task = GrocyTask(
                    id: try grocyVM.findNextID(.tasks),
                    name: reminder.title,
                    taskDescription: reminder.notes ?? "",
                    dueDate: reminder.dueDate.flatMap { DateComponents(year: $0.year, month: $0.month, day: $0.day) }.flatMap {
                        Calendar.current.date(from: $0)
                    }
                )
                let taskID = try await grocyVM.postMDObject(object: .tasks, content: task).createdObjectID
                if reminder.isCompleted {
                    let doneTime = (reminder.completionDate ?? Date()).grocyDateTimeString
                    try await grocyVM.executeTask(taskID: taskID, content: TaskExecuteModel(doneTime: doneTime))
                }
                link(reminder, to: taskID)
            }
            grocyVM.timeStampsObjects[.tasks] = nil
            await grocyVM.requestData(objects: [.tasks])

        case .chores:
            // A chore can't be undone from Reminders: its reminder reopens with the next due date right away.
            for (choreID, done) in changes.doneChanges.sorted(by: { $0.key < $1.key }) where done {
                let trackedTime = (completionDates[choreID] ?? Date()).grocyDateTimeString
                _ = try await grocyVM.executeChore(id: choreID, content: ChoreExecuteModel(trackedTime: trackedTime, doneBy: nil, skipped: false))
            }
            grocyVM.timeStampsAdditionalObjects[.chores] = nil
            await grocyVM.requestData(additionalObjects: [.chores])
        }
        return existing
    }

    // MARK: - Automatic sync

    /// The identifier of the background refresh task, also listed in `BGTaskSchedulerPermittedIdentifiers`.
    static let backgroundTaskIdentifier = "georgappdev.Grocy.reminderSync"
    /// How often the lists are synced while the app is open. A sync without changes only asks Grocy for its `db-changed-time`, so it's cheap.
    static let foregroundSyncInterval: Duration = .seconds(5 * 60)
    /// The earliest time for the next background sync. iOS decides when it actually runs.
    static let backgroundSyncInterval: TimeInterval = 15 * 60

    @ObservationIgnored private var periodicSync: Task<Void, Never>?
    /// The app's view model, for the syncs the system starts in the background.
    @ObservationIgnored private weak var grocyVM: GrocyViewModel?

    /// The targets whose automatic sync is on: the shopping list chosen in the settings, the tasks and the chores.
    var automaticSyncTargets: [ReminderSyncTarget] {
        var targets: [ReminderSyncTarget] = []
        let shoppingListID = defaults.integer(forKey: "shoppingListToSyncID")
        if defaults.bool(forKey: ReminderSyncTarget.settingKey(for: .shoppingList)), shoppingListID > 0 {
            targets.append(.shoppingList(id: shoppingListID))
        }
        if defaults.bool(forKey: ReminderSyncTarget.settingKey(for: .tasks)) {
            targets.append(.tasks)
        }
        if defaults.bool(forKey: ReminderSyncTarget.settingKey(for: .chores)) {
            targets.append(.chores)
        }
        return targets
    }

    /// Syncs the targets whose automatic sync is on, if the app has access. It never asks for access.
    /// Called after Grocy data was reloaded (only for that kind), when Reminders changed, and periodically while the app is open.
    func syncAutomaticallyIfEnabled(grocyVM: GrocyViewModel, only kind: ReminderSyncTarget.Kind? = nil) {
        let targets = automaticSyncTargets.filter { (kind == nil || $0.kind == kind) && !syncingTargets.contains($0) }
        guard !targets.isEmpty else { return }
        refreshAuthorizationStatus()
        guard hasFullAccess else { return }
        for target in targets {
            pendingAutomaticSyncs[target]?.cancel()
            pendingAutomaticSyncs[target] = Task { [weak self, weak grocyVM] in
                // Reminders posts several change notifications in a row, so wait for them to settle.
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self, let grocyVM else { return }
                await self.syncAutomatically(target, grocyVM: grocyVM)
            }
        }
    }

    private func syncAutomatically(_ target: ReminderSyncTarget, grocyVM: GrocyViewModel) async {
        // Right after launch, the server isn't set up yet.
        await grocyVM.waitForLogin()
        do {
            try await sync(target, grocyVM: grocyVM, requestAccess: false)
        } catch {
            GrocyLogger.error("Syncing \(target.logName) with Reminders automatically failed. \(error)")
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
        /// Asks iOS to wake the app in the background for the next sync, or cancels the request when no automatic sync is on.
        func scheduleBackgroundSync() {
            guard !automaticSyncTargets.isEmpty else {
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

    /// The background refresh task: syncs the lists once and schedules the next run.
    func syncInBackground() async {
        #if os(iOS)
            scheduleBackgroundSync()
        #endif
        guard let grocyVM else { return }
        refreshAuthorizationStatus()
        guard hasFullAccess else { return }
        for target in automaticSyncTargets where !syncingTargets.contains(target) {
            await syncAutomatically(target, grocyVM: grocyVM)
        }
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
