//
//  AppIntent.swift
//  Grocy Widget
//
//  Created by Georg Meißner on 06.12.25.
//

import AppIntents
import WidgetKit

// MARK: - Stock

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Stock overview" }
    static var description: IntentDescription { "Shows how many products are due soon, overdue, expired or below their minimum stock amount." }

    enum StockFilter: String, AppEnum {
        case expiringSoon
        case overdue
        case expired
        case belowMinStock
        case all

        static var typeDisplayRepresentation: TypeDisplayRepresentation { "Stock filter" }

        static let caseDisplayRepresentations: [StockFilter: DisplayRepresentation] = [
            .expiringSoon: "Due soon",
            .overdue: "Overdue",
            .expired: "Expired",
            .belowMinStock: "Below min. stock amount",
            .all: "All",
        ]

        /// The `ProductStatus` case name used in the deep link.
        var caseName: String {
            rawValue
        }
    }

    /// The filter the stock overview opens with when the small widget is tapped.
    @Parameter(title: "Opens filter", default: .all)
    var defaultFilter: StockFilter
}

// MARK: - Shopping list

struct ShoppingListWidgetEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Shopping list" }
    static let defaultQuery = ShoppingListWidgetEntityQuery()

    let id: Int
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

/// Offers the shopping lists the app last wrote to the App Group.
struct ShoppingListWidgetEntityQuery: EntityQuery {
    private var allLists: [ShoppingListWidgetEntity] {
        let summary = WidgetSharedStore.load(WidgetShoppingListSummary.self, forKey: WidgetSharedStore.shoppingListKey)
        return (summary?.lists ?? []).map { ShoppingListWidgetEntity(id: $0.id, name: $0.name) }
    }

    func entities(for identifiers: [Int]) async throws -> [ShoppingListWidgetEntity] {
        allLists.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [ShoppingListWidgetEntity] {
        allLists
    }

    func defaultResult() async -> ShoppingListWidgetEntity? {
        allLists.first
    }
}

struct ShoppingListWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Shopping list" }
    static var description: IntentDescription { "Shows the items still to buy on a shopping list." }

    @Parameter(title: "Shopping list")
    var shoppingList: ShoppingListWidgetEntity?
}

// MARK: - Chores and tasks

struct DueWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Filter" }
    static var description: IntentDescription { "Choose which entries the widget shows." }

    @Parameter(title: "Only assigned to me", default: false)
    var onlyAssignedToMe: Bool
}
