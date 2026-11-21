//
//  GrocyAppShortcuts.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 21.11.26.
//

import AppIntents

/// The Siri phrases that work without setting up a shortcut first. Each phrase must name the app.
///
/// The product in the phrases comes from `ProductEntityQuery.suggestedEntities()`. Call
/// `updateAppShortcutParameters()` when the products change, so Siri knows the new names.
///
/// The symbol names are literals, not `MySymbols`: the App Intents metadata is extracted at build time and needs
/// compile-time constants. Keep them equal to `MySymbols.stockOverview`, `open`, `consume` and `addToShoppingList`.
struct GrocyAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetProductStockIntent(),
            phrases: [
                "How much \(\.$product) do I have in \(.applicationName)",
                "How much \(\.$product) is left in \(.applicationName)",
                "Check \(\.$product) stock in \(.applicationName)",
                "Check stock in \(.applicationName)",
            ],
            shortTitle: "Stock Amount",
            systemImageName: "archivebox"
        )
        AppShortcut(
            intent: OpenProductIntent(),
            phrases: [
                "Open \(\.$product) in \(.applicationName)",
                "I opened \(\.$product) in \(.applicationName)",
                "Open a product in \(.applicationName)",
            ],
            shortTitle: "Open Product",
            systemImageName: "envelope.open"
        )
        AppShortcut(
            intent: ConsumeProductIntent(),
            phrases: [
                "Consume \(\.$product) in \(.applicationName)",
                "I used up \(\.$product) in \(.applicationName)",
                "Consume a product in \(.applicationName)",
            ],
            shortTitle: "Consume Product",
            systemImageName: "fork.knife"
        )
        AppShortcut(
            intent: AddProductToShoppingListIntent(),
            phrases: [
                "Add \(\.$product) to the shopping list in \(.applicationName)",
                "Put \(\.$product) on my \(.applicationName) shopping list",
                "Add to the shopping list in \(.applicationName)",
            ],
            shortTitle: "Add to Shopping List",
            systemImageName: "cart.fill.badge.plus"
        )
    }

    static let shortcutTileColor: ShortcutTileColor = .lime
}
