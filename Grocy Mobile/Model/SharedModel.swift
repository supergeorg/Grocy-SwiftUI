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
