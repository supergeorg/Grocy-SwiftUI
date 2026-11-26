//
//  DueBadgeCount.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 26.11.26.
//

import SwiftData
import SwiftUI

/// The badge of the due agenda (a tab or a sidebar row): what is expired, overdue or due today.
/// "Due soon" and "below min. stock" don't need attention yet. Kinds hidden from the agenda aren't counted.
///
/// Counted on every update of the tab bar or sidebar, so without the products below min. stock (never counted, and they
/// need all products) and without sorting.
@propertyWrapper
struct DueBadgeCount: DynamicProperty {
    @AppStorage(DueKind.hiddenKindsStorageKey) private var hiddenDueKinds: String = ""
    @Query(filter: #Predicate<StockElement> { $0.amountAggregated > 0 }) private var stock: Stock
    @Query private var volatileStockList: [VolatileStock]
    @Query private var chores: Chores
    @Query(filter: #Predicate<GrocyTask> { !$0.done }) private var openTasks: GrocyTasks
    @Query private var batteries: Batteries
    @Query private var userSettingsList: GrocyUserSettingsList
    @Query private var systemConfigList: [SystemConfig]

    var wrappedValue: Int {
        DueItem.items(
            stock: stock,
            volatileStock: volatileStockList.first,
            mdProducts: [],
            chores: chores,
            tasks: openTasks,
            batteries: batteries,
            userSettings: userSettingsList.first,
            systemConfig: systemConfigList.first,
            hiddenKinds: DueKind.hiddenKinds(from: hiddenDueKinds).union([.belowMinStock]),
            sorted: false
        )
        .count(where: { $0.urgency.needsAttention })
    }
}
