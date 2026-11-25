//
//  WatchSync.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 25.11.26.
//

#if os(iOS)
    import Foundation
    import WatchConnectivity

    /// Shares the shopping lists, tasks and chores with the Watch app, and carries out the check-offs made on the watch.
    ///
    /// The watch has no connection to the Grocy server. The iPhone sends it a ``WatchSnapshot`` after each sync of the
    /// shopping list, the tasks or the chores, and the watch sends back ``WatchAction``s, which this class carries out with the app's login.
    final class WatchSync: NSObject {
        static let shared = WatchSync()

        private weak var grocyVM: GrocyViewModel?
        private var sendTask: Task<Void, Never>?
        private var actionsInProgress: Set<UUID> = []

        private static let handledActionIDsKey = "watchHandledActionIDs"

        private var handledActionIDs: [UUID] {
            get {
                guard let data = UserDefaults.standard.data(forKey: Self.handledActionIDsKey) else { return [] }
                return (try? JSONDecoder().decode([UUID].self, from: data)) ?? []
            }
            set {
                UserDefaults.standard.set(try? JSONEncoder().encode(newValue), forKey: Self.handledActionIDsKey)
            }
        }

        func start(grocyVM: GrocyViewModel) {
            self.grocyVM = grocyVM
            guard WCSession.isSupported() else { return }
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }

        /// Sends the current shopping lists, tasks and chores to the watch. Calls within half a second are combined into one.
        func sendSnapshot() {
            guard WCSession.isSupported() else { return }
            sendTask?.cancel()
            sendTask = Task {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                self.sendSnapshotNow()
            }
        }

        private func sendSnapshotNow() {
            let session = WCSession.default
            guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
            let isLoggedIn = grocyVM?.isLoggedIn ?? false
            let snapshot = WatchSnapshot(
                isLoggedIn: isLoggedIn,
                localizationKey: grocyVM?.localizationKey ?? "en",
                shoppingList: isLoggedIn ? WidgetSharedStore.load(WidgetShoppingListSummary.self, forKey: WidgetSharedStore.shoppingListKey) : nil,
                tasks: isLoggedIn ? WidgetSharedStore.load(WidgetDueSummary.self, forKey: WidgetSharedStore.tasksKey) : nil,
                chores: isLoggedIn ? WidgetSharedStore.load(WidgetDueSummary.self, forKey: WidgetSharedStore.choresKey) : nil,
                handledActionIDs: handledActionIDs,
                updated: Date()
            )
            do {
                try session.updateApplicationContext(try snapshot.applicationContext())
            } catch {
                GrocyLogger.error("Sending the data to the watch failed. \(error)")
            }
        }

        private func handle(_ action: WatchAction) async {
            guard let grocyVM else { return }
            // The watch can send an action again after a restart. Carry out each one only once.
            guard !handledActionIDs.contains(action.id), !actionsInProgress.contains(action.id) else {
                sendSnapshot()
                return
            }
            actionsInProgress.insert(action.id)
            defer { actionsInProgress.remove(action.id) }

            await grocyVM.waitForLogin()
            if grocyVM.isLoggedIn {
                do {
                    switch action.kind {
                    case .shoppingListItemDone(let itemID):
                        try await grocyVM.putMDObjectWithID(object: .shopping_list, id: itemID, content: ShoppingListItemDonePUT(done: true))
                    case .taskDone(let taskID):
                        try await grocyVM.executeTask(taskID: taskID, content: TaskExecuteModel(doneTime: action.date.grocyDateTimeString))
                    case .choreDone(let choreID):
                        _ = try await grocyVM.executeChore(
                            id: choreID,
                            content: ChoreExecuteModel(trackedTime: action.date.grocyDateTimeString, doneBy: nil, skipped: false)
                        )
                    }
                    GrocyLogger.info("Carried out the check-off from the watch.")
                } catch {
                    // The item stays on the list, so it shows up on the watch again with the next snapshot.
                    GrocyLogger.error("Carrying out the check-off from the watch failed. \(error)")
                }
            }
            handledActionIDs = WatchActionLog.appendingHandled(action.id, to: handledActionIDs)

            if grocyVM.isLoggedIn {
                // The server's change time has a resolution of one second, so a change right after the last sync could be
                // missed. Clearing the timestamp makes the reload happen in any case.
                switch action.kind {
                case .shoppingListItemDone:
                    grocyVM.timeStampsObjects[.shopping_list] = nil
                    await grocyVM.requestData(objects: [.shopping_list])
                case .taskDone:
                    grocyVM.timeStampsObjects[.tasks] = nil
                    await grocyVM.requestData(objects: [.tasks])
                case .choreDone:
                    grocyVM.timeStampsAdditionalObjects[.chores] = nil
                    await grocyVM.requestData(additionalObjects: [.chores])
                }
            }
            sendSnapshot()
        }

        private func refresh() async {
            guard let grocyVM else { return }
            await grocyVM.waitForLogin()
            if grocyVM.isLoggedIn {
                await grocyVM.requestData(
                    objects: [.shopping_list, .shopping_lists, .products, .quantity_units, .tasks],
                    additionalObjects: [.chores]
                )
            }
            sendSnapshot()
        }
    }

    extension WatchSync: nonisolated WCSessionDelegate {
        nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
            if let error {
                let message = "\(error)"
                Task { @MainActor in GrocyLogger.error("Connecting to the watch failed. \(message)") }
                return
            }
            Task { @MainActor in self.sendSnapshot() }
        }

        nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

        nonisolated func sessionDidDeactivate(_ session: WCSession) {
            // The person switched to another watch. Activate again to connect to it.
            session.activate()
        }

        nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
            Task { @MainActor in self.sendSnapshot() }
        }

        nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
            guard let action = WatchAction(userInfo: userInfo) else { return }
            Task { @MainActor in await self.handle(action) }
        }

        nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
            guard WatchRefreshMessage.isRefresh(message) else { return }
            Task { @MainActor in await self.refresh() }
        }
    }
#endif
