//
//  AppCommands.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

extension FocusedValues {
    /// The sidebar's selection, so menu commands can open a place.
    @Entry var sidebarSelection: Binding<NavigationItem?>?
    /// The server's feature flags (`nil` before the first sync), so the commands match the sidebar.
    @Entry var sidebarSystemConfig: SystemConfig?
    @Entry var sidebarFeatures: GrocyFeatures?
}

/// The "Go" menu: opens the places of the sidebar with the keyboard (macOS and iPad with a keyboard).
struct AppCommands: Commands {
    @FocusedValue(\.sidebarSelection) private var selection
    @FocusedValue(\.sidebarSystemConfig) private var systemConfig
    @FocusedValue(\.sidebarFeatures) private var features

    private func button(_ title: LocalizedStringKey, systemImage: String, item: NavigationItem, isEnabled: Bool = true) -> some View {
        Button {
            selection?.wrappedValue = item
        } label: {
            Label(title, systemImage: systemImage)
        }
        .disabled(selection == nil || !isEnabled)
    }

    var body: some Commands {
        CommandMenu("Go") {
            button("Stock overview", systemImage: MySymbols.stockOverview, item: .stockOverview, isEnabled: systemConfig?.featureFlagStock != false)
                .keyboardShortcut("1")
            button("Shopping list", systemImage: MySymbols.shoppingList, item: .shoppingList, isEnabled: systemConfig?.featureFlagShoppinglist != false)
                .keyboardShortcut("2")
            button("Recipes", systemImage: MySymbols.recipe, item: .recipes, isEnabled: systemConfig?.featureFlagRecipes != false)
                .keyboardShortcut("3")
            button(
                "Meal plan",
                systemImage: MySymbols.mealPlan,
                item: .mealPlan,
                isEnabled: systemConfig?.featureFlagRecipes != false && systemConfig?.featureFlagRecipesMealplan != false
            )
            .keyboardShortcut("4")
            button("Chores overview", systemImage: MySymbols.chores, item: .choresOverview, isEnabled: systemConfig?.featureFlagChores != false)
                .keyboardShortcut("5")
            button("Tasks", systemImage: MySymbols.tasks, item: .tasks, isEnabled: systemConfig?.featureFlagTasks != false)
                .keyboardShortcut("6")
            button("Batteries overview", systemImage: MySymbols.batteries, item: .batteriesOverview, isEnabled: systemConfig?.featureFlagBatteries != false)
                .keyboardShortcut("7")
            button("Equipment", systemImage: MySymbols.equipment, item: .equipment, isEnabled: systemConfig?.featureFlagEquipment != false)
                .keyboardShortcut("8")

            Divider()

            let stockEnabled = systemConfig?.featureFlagStock != false
            button("Purchase", systemImage: MySymbols.purchase, item: .purchase, isEnabled: stockEnabled)
                .keyboardShortcut("p", modifiers: [.command, .option])
            button("Consume", systemImage: MySymbols.consume, item: .consume, isEnabled: stockEnabled)
                .keyboardShortcut("c", modifiers: [.command, .option])
            button("Transfer", systemImage: MySymbols.transfer, item: .transfer, isEnabled: stockEnabled && features?.locationTracking != false)
                .keyboardShortcut("t", modifiers: [.command, .option])
            button("Inventory", systemImage: MySymbols.inventory, item: .inventory, isEnabled: stockEnabled)
                .keyboardShortcut("i", modifiers: [.command, .option])
        }
    }
}
