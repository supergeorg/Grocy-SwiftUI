//
//  WatchSyncModel.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 25.11.26.
//

import Foundation

// This file belongs to the iOS app and the Watch app: the iPhone and the watch exchange these types through WatchConnectivity.

/// The data the iPhone shares with the Watch app, sent as the WatchConnectivity application context.
///
/// The watch never talks to the Grocy server. It shows the last snapshot it received, also when the iPhone isn't nearby.
/// The shopping lists and tasks are the summaries the widgets show, so they only include what isn't done yet.
nonisolated struct WatchSnapshot: Codable, Equatable {
    static let contextKey = "snapshot"

    var isLoggedIn: Bool
    /// The app's language override, so the watch uses the same language as the app.
    var localizationKey: String
    var shoppingList: WidgetShoppingListSummary?
    var tasks: WidgetDueSummary?
    /// The watch actions the iPhone has carried out or tried to, oldest first. The watch stops showing them as pending.
    var handledActionIDs: [UUID]
    var updated: Date

    func applicationContext() throws -> [String: Any] {
        [Self.contextKey: try JSONEncoder().encode(self)]
    }

    init(
        isLoggedIn: Bool,
        localizationKey: String,
        shoppingList: WidgetShoppingListSummary?,
        tasks: WidgetDueSummary?,
        handledActionIDs: [UUID],
        updated: Date
    ) {
        self.isLoggedIn = isLoggedIn
        self.localizationKey = localizationKey
        self.shoppingList = shoppingList
        self.tasks = tasks
        self.handledActionIDs = handledActionIDs
        self.updated = updated
    }

    init?(applicationContext: [String: Any]) {
        guard let data = applicationContext[Self.contextKey] as? Data,
            let snapshot = try? JSONDecoder().decode(WatchSnapshot.self, from: data)
        else { return nil }
        self = snapshot
    }
}

/// A check-off made on the watch. The watch sends it with `transferUserInfo`, so it reaches the iPhone even when the
/// iPhone isn't nearby at the moment, and the iPhone carries it out on the Grocy server.
nonisolated struct WatchAction: Codable, Equatable, Identifiable {
    static let userInfoKey = "action"

    enum Kind: Codable, Equatable {
        case shoppingListItemDone(itemID: Int)
        case taskDone(taskID: Int)
    }

    var id: UUID
    var kind: Kind
    /// When the check-off was made on the watch. Used as the task's done time.
    var date: Date

    init(id: UUID = UUID(), kind: Kind, date: Date = Date()) {
        self.id = id
        self.kind = kind
        self.date = date
    }

    func userInfo() throws -> [String: Any] {
        [Self.userInfoKey: try JSONEncoder().encode(self)]
    }

    init?(userInfo: [String: Any]) {
        guard let data = userInfo[Self.userInfoKey] as? Data,
            let action = try? JSONDecoder().decode(WatchAction.self, from: data)
        else { return nil }
        self = action
    }
}

/// The message the watch sends to ask the iPhone for fresh data. Sending it while the iPhone is reachable also wakes the app
/// in the background, so it receives the queued check-offs.
nonisolated enum WatchRefreshMessage {
    static let key = "refresh"
    static var message: [String: Any] { [key: true] }

    static func isRefresh(_ message: [String: Any]) -> Bool {
        message[key] != nil
    }
}

nonisolated enum WatchActionLog {
    /// How many handled action IDs the iPhone keeps. The watch only has a few pending at a time.
    static let handledLimit = 100

    /// The pending actions the iPhone hasn't handled yet, according to the snapshot.
    static func pending(_ actions: [WatchAction], after snapshot: WatchSnapshot) -> [WatchAction] {
        let handled = Set(snapshot.handledActionIDs)
        return actions.filter { !handled.contains($0.id) }
    }

    /// Adds a handled action ID and drops the oldest ones over the limit.
    static func appendingHandled(_ id: UUID, to ids: [UUID], limit: Int = handledLimit) -> [UUID] {
        var ids = ids.filter { $0 != id }
        ids.append(id)
        return Array(ids.suffix(limit))
    }
}
