//
//  WatchStore.swift
//  Grocy Watch Watch App
//
//  Created by Georg Meißner on 25.11.26.
//

import Foundation
import Observation
import WatchConnectivity

/// The data the watch shows, and the check-offs that wait for the iPhone.
///
/// The watch gets its data from the iPhone app through WatchConnectivity (see `WatchSync` in the iOS app). It keeps the last
/// snapshot and the pending check-offs in files, so they are there after a restart and when the iPhone isn't nearby.
@Observable
final class WatchStore: NSObject {
    static let shared = WatchStore()

    private(set) var snapshot: WatchSnapshot?
    private(set) var pendingActions: [WatchAction] = []
    private(set) var isPhoneReachable = false

    private static let snapshotURL = URL.documentsDirectory.appending(path: "watchSnapshot.json")
    private static let pendingActionsURL = URL.documentsDirectory.appending(path: "watchPendingActions.json")

    override init() {
        super.init()
        snapshot = Self.load(WatchSnapshot.self, from: Self.snapshotURL)
        pendingActions = Self.load([WatchAction].self, from: Self.pendingActionsURL) ?? []
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Asks the iPhone for fresh data. Only works while the iPhone is reachable; otherwise the watch keeps its last data.
    func requestRefresh() {
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else { return }
        session.sendMessage(WatchRefreshMessage.message, replyHandler: nil, errorHandler: nil)
    }

    func isPending(shoppingListItemID: Int) -> Bool {
        pendingActions.contains { $0.kind == .shoppingListItemDone(itemID: shoppingListItemID) }
    }

    func isPending(taskID: Int) -> Bool {
        pendingActions.contains { $0.kind == .taskDone(taskID: taskID) }
    }

    func isPending(choreID: Int) -> Bool {
        pendingActions.contains { $0.kind == .choreDone(choreID: choreID) }
    }

    func checkOff(shoppingListItemID: Int) {
        perform(WatchAction(kind: .shoppingListItemDone(itemID: shoppingListItemID)))
    }

    func complete(taskID: Int) {
        perform(WatchAction(kind: .taskDone(taskID: taskID)))
    }

    func trackChore(choreID: Int) {
        perform(WatchAction(kind: .choreDone(choreID: choreID)))
    }

    private func perform(_ action: WatchAction) {
        guard !pendingActions.contains(where: { $0.kind == action.kind }) else { return }
        pendingActions.append(action)
        savePendingActions()
        transfer(action)
        // Wakes the iPhone app if it's reachable, so it carries out the check-off right away.
        requestRefresh()
    }

    private func transfer(_ action: WatchAction) {
        let session = WCSession.default
        guard session.activationState == .activated, let userInfo = try? action.userInfo() else { return }
        session.transferUserInfo(userInfo)
    }

    /// Sends the pending actions that aren't queued in WatchConnectivity anymore, for example ones made before the session was
    /// activated. The iPhone carries out each action only once, so sending one twice does no harm.
    private func transferUnsentActions(outstanding: [WatchAction]) {
        let outstandingIDs = Set(outstanding.map(\.id))
        for action in pendingActions where !outstandingIDs.contains(action.id) {
            transfer(action)
        }
    }

    private func receive(_ snapshot: WatchSnapshot) {
        self.snapshot = snapshot
        Self.save(snapshot, to: Self.snapshotURL)
        pendingActions = WatchActionLog.pending(pendingActions, after: snapshot)
        savePendingActions()
    }

    private func savePendingActions() {
        Self.save(pendingActions, to: Self.pendingActionsURL)
    }

    private static func load<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func save<T: Encodable>(_ value: T, to url: URL) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

extension WatchStore: nonisolated WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let snapshot = WatchSnapshot(applicationContext: session.receivedApplicationContext)
        let outstanding = session.outstandingUserInfoTransfers.compactMap { WatchAction(userInfo: $0.userInfo) }
        let isReachable = session.isReachable
        Task { @MainActor in
            if let snapshot {
                self.receive(snapshot)
            }
            self.isPhoneReachable = isReachable
            if activationState == .activated {
                self.transferUnsentActions(outstanding: outstanding)
                self.requestRefresh()
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let snapshot = WatchSnapshot(applicationContext: applicationContext) else { return }
        Task { @MainActor in self.receive(snapshot) }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let isReachable = session.isReachable
        Task { @MainActor in
            self.isPhoneReachable = isReachable
            if isReachable {
                self.requestRefresh()
            }
        }
    }
}
