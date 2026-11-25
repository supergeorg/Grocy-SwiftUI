//
//  WatchSyncModelTests.swift
//  Grocy Mobile
//

import Foundation
import Testing

@testable import Grocy_Mobile

@Suite("Watch sync")
struct WatchSyncModelTests {
    private func snapshot(handled: [UUID]) -> WatchSnapshot {
        WatchSnapshot(
            isLoggedIn: true,
            localizationKey: "de",
            shoppingList: WidgetShoppingListSummary(
                lists: [.init(id: 1, name: "Groceries", items: [.init(id: 7, name: "Milk", amount: "2 Packs")])],
                updated: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            tasks: WidgetDueSummary(
                items: [.init(id: 3, name: "Clean fridge", dueDate: Date(timeIntervalSince1970: 1_700_100_000), assignedToMe: true)],
                dueSoonDays: 5,
                updated: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            chores: WidgetDueSummary(
                items: [.init(id: 4, name: "Water plants", dueDate: nil, assignedToMe: false)],
                dueSoonDays: 5,
                updated: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            handledActionIDs: handled,
            updated: Date(timeIntervalSince1970: 1_700_000_500)
        )
    }

    @Test("A snapshot survives the trip through the application context")
    func snapshotRoundTrip() throws {
        let original = snapshot(handled: [UUID()])
        let decoded = try #require(WatchSnapshot(applicationContext: try original.applicationContext()))
        #expect(decoded == original)
    }

    @Test("An action survives the trip through the user info")
    func actionRoundTrip() throws {
        for kind in [WatchAction.Kind.shoppingListItemDone(itemID: 7), .taskDone(taskID: 3), .choreDone(choreID: 4)] {
            let original = WatchAction(kind: kind, date: Date(timeIntervalSince1970: 1_700_000_000))
            let decoded = try #require(WatchAction(userInfo: try original.userInfo()))
            #expect(decoded == original)
        }
    }

    @Test("A snapshot from before chores were on the watch still decodes")
    func snapshotWithoutChores() throws {
        var original = snapshot(handled: [])
        original.chores = nil
        var json = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        json.removeValue(forKey: "chores")
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoded = try #require(WatchSnapshot(applicationContext: [WatchSnapshot.contextKey: data]))
        #expect(decoded == original)
    }

    @Test("Other dictionaries aren't read as a snapshot or an action")
    func unrelatedDictionaries() {
        #expect(WatchSnapshot(applicationContext: [:]) == nil)
        #expect(WatchSnapshot(applicationContext: [WatchSnapshot.contextKey: Data("{}".utf8)]) == nil)
        #expect(WatchAction(userInfo: ["other": 1]) == nil)
        #expect(WatchRefreshMessage.isRefresh(WatchRefreshMessage.message))
        #expect(!WatchRefreshMessage.isRefresh(["other": true]))
    }

    @Test("Only the actions the iPhone hasn't handled stay pending")
    func pendingActions() {
        let handled = WatchAction(kind: .shoppingListItemDone(itemID: 7))
        let open = WatchAction(kind: .taskDone(taskID: 3))
        let remaining = WatchActionLog.pending([handled, open], after: snapshot(handled: [handled.id]))
        #expect(remaining == [open])
    }

    @Test("The handled IDs keep the newest ones, each once")
    func handledLimit() {
        let ids = (0..<5).map { _ in UUID() }
        var log: [UUID] = []
        for id in ids {
            log = WatchActionLog.appendingHandled(id, to: log, limit: 3)
        }
        #expect(log == Array(ids.suffix(3)))
        // Handling an ID again moves it to the end instead of adding it twice.
        log = WatchActionLog.appendingHandled(ids[2], to: log, limit: 3)
        #expect(log == [ids[3], ids[4], ids[2]])
    }
}
