//
//  MacSettingsView.swift
//  Grocy Mobile
//

import SwiftData
import SwiftUI

#if os(macOS)
    /// The Mac's settings window (Grocy Mobile > Settings…, ⌘,): one pane per page in the window's toolbar,
    /// like the settings of Mail or Safari, instead of the iPhone's list that pushes pages.
    ///
    /// The panes are the pages of the iPhone's settings: General, one per area the server has turned on, and the account.
    /// The app log and the information about the app are windows of their own, like in other Mac apps
    /// (Window menu, and "About Grocy Mobile" in the app menu).
    struct MacSettingsView: View {
        @Environment(GrocyViewModel.self) private var grocyVM

        @Query private var systemConfigList: [SystemConfig]
        private var systemConfig: SystemConfig? { systemConfigList.first }

        var body: some View {
            TabView {
                Tab("General", systemImage: MySymbols.settings) {
                    pane { SettingsAppView() }
                }
                // Like Grocy's own settings, an area the server turned off has no settings pane.
                if systemConfig?.featureFlagStock != false {
                    Tab("Stock", systemImage: MySymbols.stockOverview) {
                        pane { SettingsStockView() }
                    }
                }
                if systemConfig?.featureFlagShoppinglist != false {
                    Tab("Shopping list", systemImage: MySymbols.shoppingList) {
                        pane { SettingsShoppingListView() }
                    }
                }
                if systemConfig?.featureFlagChores != false {
                    Tab("Chores", systemImage: MySymbols.chores) {
                        pane { SettingsChoresView() }
                    }
                }
                if systemConfig?.featureFlagTasks != false {
                    Tab("Tasks", systemImage: MySymbols.tasks) {
                        pane { SettingsTasksView() }
                    }
                }
                if systemConfig?.featureFlagBatteries != false {
                    Tab("Batteries", systemImage: MySymbols.batteries) {
                        pane { SettingsBatteriesView() }
                    }
                }
                if systemConfig?.featureFlagRecipes != false {
                    Tab("Recipes", systemImage: MySymbols.recipe) {
                        pane { SettingsRecipesView() }
                    }
                }
                if systemConfig?.featureFlagRecipes != false && systemConfig?.featureFlagRecipesMealplan != false {
                    Tab("Meal plan", systemImage: MySymbols.mealPlan) {
                        pane { SettingsMealPlanView() }
                    }
                }
                Tab("Account", systemImage: MySymbols.user) {
                    pane { SettingsAccountView() }
                }
            }
            .task {
                await grocyVM.requestData(additionalObjects: [.system_config, .system_info, .current_user])
            }
        }

        /// A pane of a fixed size, so the window doesn't jump between panes. In its own navigation stack,
        /// so a page that opens a detail (the server information, the user) pushes it inside the pane.
        private func pane<Content: View>(@ViewBuilder content: () -> Content) -> some View {
            NavigationStack {
                content()
                    .settingsDestinations()
            }
            .frame(width: Constants.macOSSettingsWidth, height: Constants.macOSSettingsHeight)
        }
    }

    #Preview(traits: .previewData) {
        MacSettingsView()
    }
#endif
