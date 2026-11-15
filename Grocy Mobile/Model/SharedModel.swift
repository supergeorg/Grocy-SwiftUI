//
//  SharedModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

import Foundation

enum DueType: Int, Codable {
    case bestBefore = 1
    case expires = 2
}

// MARK: - Widget stock summary

/// The counts shown by the stock widget.
///
/// The app writes them to the App Group's `UserDefaults` after each volatile stock sync, and the widget reads them from there.
/// The widget must not open the SwiftData store: a `ModelContainer` with a different schema migrates the shared store to that schema,
/// which drops the app's other tables.
nonisolated struct WidgetStockSummary: Codable, Equatable {
    static let appGroupID = "group.georgappdev.Grocy"
    static let defaultsKey = "widgetStockSummary"
    static let widgetKind = "Grocy_Widget"

    var dueSoon: Int
    var overdue: Int
    var expired: Int
    var belowMinStock: Int
    var updated: Date

    static func load() -> WidgetStockSummary? {
        guard let data = UserDefaults(suiteName: appGroupID)?.data(forKey: defaultsKey) else { return nil }
        return try? JSONDecoder().decode(WidgetStockSummary.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults(suiteName: Self.appGroupID)?.set(data, forKey: Self.defaultsKey)
    }

    static func clear() {
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: defaultsKey)
    }
}

// MARK: - Widget shared store

/// Reads and writes the data the widgets show in the App Group's `UserDefaults`.
///
/// Like ``WidgetStockSummary``, the widgets never open the SwiftData store. The app writes small summaries after each sync.
nonisolated enum WidgetSharedStore {
    static let shoppingListKind = "Grocy_ShoppingListWidget"
    static let choresKind = "Grocy_ChoresWidget"
    static let tasksKind = "Grocy_TasksWidget"

    static let shoppingListKey = "widgetShoppingListSummary"
    static let choresKey = "widgetChoresSummary"
    static let tasksKey = "widgetTasksSummary"
    /// The app's language override (`@AppStorage("localizationKey")`), so the widgets use the same language as the app.
    static let localizationKey = "widgetLocalizationKey"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: WidgetStockSummary.appGroupID)
    }

    static func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults?.set(data, forKey: key)
    }

    static func remove(forKey key: String) {
        defaults?.removeObject(forKey: key)
    }

    static var locale: Locale {
        if let identifier = defaults?.string(forKey: localizationKey) {
            return Locale(identifier: identifier)
        }
        return .current
    }

    static func saveLocalization(_ identifier: String) {
        defaults?.set(identifier, forKey: localizationKey)
    }
}

/// The shopping lists shown by the shopping list widget. Only items that aren't done are included.
nonisolated struct WidgetShoppingListSummary: Codable, Equatable {
    struct Item: Codable, Equatable, Identifiable {
        var id: Int
        var name: String
        var amount: String
    }

    struct List: Codable, Equatable, Identifiable {
        var id: Int
        var name: String
        var items: [Item]
    }

    var lists: [List]
    var updated: Date
}

/// The chores or tasks shown by the chores and tasks widgets.
///
/// The due dates are stored instead of precomputed states, so the widget can work out "overdue" and "due today" when it renders.
nonisolated struct WidgetDueSummary: Codable, Equatable {
    struct Item: Codable, Equatable, Identifiable {
        var id: Int
        var name: String
        var dueDate: Date?
        var assignedToMe: Bool
    }

    var items: [Item]
    var dueSoonDays: Int
    var updated: Date
}

/// The deep links the widgets open. `GrocyDeepLink` parses them in the app.
nonisolated enum WidgetDeepLink {
    static func stock(filter: String) -> URL {
        url("grocy://stock/filter/\(filter)")
    }

    static func shoppingList(id: Int?) -> URL {
        if let id {
            return url("grocy://shoppinglist/list/\(id)")
        }
        return url("grocy://shoppinglist")
    }

    static func chores(filter: String) -> URL {
        url("grocy://chores/filter/\(filter)")
    }

    static func tasks(filter: String) -> URL {
        url("grocy://tasks/filter/\(filter)")
    }

    private static func url(_ string: String) -> URL {
        URL(string: string) ?? URL(filePath: "/")
    }
}
