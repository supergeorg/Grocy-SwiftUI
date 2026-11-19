//
//  SettingsView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 28.10.20.
//

import SwiftData
import SwiftUI

enum SettingsNavigationItem: Hashable {
    case serverInfo
    case userInfo
    case appSettings
    case stockSettings
    case shoppingListSettings
    case choresSettings
    case tasksSettings
    case batteriesSettings
    case recipesSettings
    case mealPlanSettings
    case appLog
    case aboutApp
    /// The tab editor of the "own tabs" iPhone navigation, opened from the app settings.
    case phoneTabs
}

struct SettingsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Environment(\.dismiss) var dismiss

    @State private var selection: SettingsNavigationItem? = nil

    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false

    @Query private var systemConfigList: [SystemConfig]

    /// The server's feature flags. Until the config is loaded, every area is shown.
    private var systemConfig: SystemConfig? { systemConfigList.first }

    var body: some View {
        List {
            if isLoggedIn {
                Section("Grocy") {
                    NavigationLink(value: SettingsNavigationItem.serverInfo) {
                        Label("Information about Grocy Server", systemImage: MySymbols.info)
                            .foregroundStyle(.primary)
                    }
                    if let currentUser = grocyVM.currentUser {
                        NavigationLink(value: SettingsNavigationItem.userInfo) {
                            Label("Logged in as user \(currentUser.displayName)", systemImage: MySymbols.user)
                                .foregroundStyle(.primary)
                        }
                    }
                    Button(
                        action: {
                            grocyVM.deleteAllCachedData()
                        },
                        label: {
                            Label("Reset cache", systemImage: MySymbols.delete)
                                .foregroundStyle(.primary)
                        }
                    )
                    // The destructive role colors the button, instead of a hard-coded red label.
                    Button(
                        role: .destructive,
                        action: {
                            grocyVM.logout()
                        },
                        label: {
                            Label("Logout", systemImage: MySymbols.logout)
                        }
                    )
                }
            }

            Section("Grocy settings") {
                NavigationLink(value: SettingsNavigationItem.appSettings) {
                    Label("App settings", systemImage: MySymbols.app)
                        .foregroundStyle(.primary)
                }
                // Like Grocy's own settings, an area the server turned off has no settings page.
                if systemConfig?.featureFlagStock != false {
                    NavigationLink(value: SettingsNavigationItem.stockSettings) {
                        Label("Stock settings", systemImage: MySymbols.stockOverview)
                            .foregroundStyle(.primary)
                    }
                }
                if systemConfig?.featureFlagShoppinglist != false {
                    NavigationLink(value: SettingsNavigationItem.shoppingListSettings) {
                        Label("Shopping list settings", systemImage: MySymbols.shoppingList)
                            .foregroundStyle(.primary)
                    }
                }
                if systemConfig?.featureFlagChores != false {
                    NavigationLink(value: SettingsNavigationItem.choresSettings) {
                        Label("Chores settings", systemImage: MySymbols.chores)
                            .foregroundStyle(.primary)
                    }
                }
                if systemConfig?.featureFlagTasks != false {
                    NavigationLink(value: SettingsNavigationItem.tasksSettings) {
                        Label("Tasks settings", systemImage: MySymbols.tasks)
                            .foregroundStyle(.primary)
                    }
                }
                if systemConfig?.featureFlagBatteries != false {
                    NavigationLink(value: SettingsNavigationItem.batteriesSettings) {
                        Label("Batteries settings", systemImage: MySymbols.batteries)
                            .foregroundStyle(.primary)
                    }
                }
                if systemConfig?.featureFlagRecipes != false {
                    NavigationLink(value: SettingsNavigationItem.recipesSettings) {
                        Label("Recipes settings", systemImage: MySymbols.recipe)
                            .foregroundStyle(.primary)
                    }
                }
                if systemConfig?.featureFlagRecipes != false && systemConfig?.featureFlagRecipesMealplan != false {
                    NavigationLink(value: SettingsNavigationItem.mealPlanSettings) {
                        Label("Meal plan settings", systemImage: MySymbols.mealPlan)
                            .foregroundStyle(.primary)
                    }
                }
            }

            Section("App") {
                NavigationLink(value: SettingsNavigationItem.appLog) {
                    Label("App log", systemImage: MySymbols.logFile)
                        .foregroundStyle(.primary)
                }
                NavigationLink(value: SettingsNavigationItem.aboutApp) {
                    Label("About this app", systemImage: MySymbols.info)
                        .foregroundStyle(.primary)
                }
            }
        }
        .navigationDestination(for: SettingsNavigationItem.self) { destination in
            switch destination {
            case .serverInfo:
                GrocyInfoView(systemInfo: grocyVM.systemInfo)
            case .userInfo:
                GrocyUserInfoView(grocyUser: grocyVM.currentUser)
            case .appSettings:
                SettingsAppView()
            case .stockSettings:
                SettingsStockView()
            case .shoppingListSettings:
                SettingsShoppingListView()
            case .choresSettings:
                SettingsChoresView()
            case .tasksSettings:
                SettingsTasksView()
            case .batteriesSettings:
                SettingsBatteriesView()
            case .recipesSettings:
                SettingsRecipesView()
            case .mealPlanSettings:
                SettingsMealPlanView()
            case .appLog:
                LogView()
            case .aboutApp:
                AboutView()
            case .phoneTabs:
                PhoneTabsSettingsView()
            }
        }
        .navigationTitle("Settings")
        .task {
            await grocyVM.requestData(additionalObjects: [.system_info, .current_user])
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        SettingsView()
    }
}
