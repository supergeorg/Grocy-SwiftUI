//
//  SettingsView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 28.10.20.
//

import SwiftData
import SwiftUI

enum SettingsNavigationItem: Hashable {
    /// The signed-in user and the server, with reset cache and logout, like the account at the top of the system settings.
    case account
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

    /// False where the stack's root registers the settings pages (`settingsDestinations()`), e.g. when the settings
    /// are pushed from the iPhone's settings button: a destination registered on a pushed page isn't found there.
    var registersDestinations: Bool = true

    var body: some View {
        if registersDestinations {
            content.settingsDestinations()
        } else {
            content
        }
    }

    private var content: some View {
        // Like the system settings: the account on top, then the app's own settings, then one page per area,
        // each named like the area, then help and information.
        List {
            if isLoggedIn {
                Section {
                    NavigationLink(value: SettingsNavigationItem.account) {
                        SettingsAccountRow()
                    }
                }
            }

            Section {
                NavigationLink(value: SettingsNavigationItem.appSettings) {
                    ListRowLabel("General", systemImage: MySymbols.settings)
                }
            }

            // Like Grocy's own settings, an area the server turned off has no settings page.
            Section {
                if systemConfig?.featureFlagStock != false {
                    NavigationLink(value: SettingsNavigationItem.stockSettings) {
                        ListRowLabel("Stock", systemImage: MySymbols.stockOverview)
                    }
                }
                if systemConfig?.featureFlagShoppinglist != false {
                    NavigationLink(value: SettingsNavigationItem.shoppingListSettings) {
                        ListRowLabel("Shopping list", systemImage: MySymbols.shoppingList)
                    }
                }
                if systemConfig?.featureFlagChores != false {
                    NavigationLink(value: SettingsNavigationItem.choresSettings) {
                        ListRowLabel("Chores", systemImage: MySymbols.chores)
                    }
                }
                if systemConfig?.featureFlagTasks != false {
                    NavigationLink(value: SettingsNavigationItem.tasksSettings) {
                        ListRowLabel("Tasks", systemImage: MySymbols.tasks)
                    }
                }
                if systemConfig?.featureFlagBatteries != false {
                    NavigationLink(value: SettingsNavigationItem.batteriesSettings) {
                        ListRowLabel("Batteries", systemImage: MySymbols.batteries)
                    }
                }
                if systemConfig?.featureFlagRecipes != false {
                    NavigationLink(value: SettingsNavigationItem.recipesSettings) {
                        ListRowLabel("Recipes", systemImage: MySymbols.recipe)
                    }
                }
                if systemConfig?.featureFlagRecipes != false && systemConfig?.featureFlagRecipesMealplan != false {
                    NavigationLink(value: SettingsNavigationItem.mealPlanSettings) {
                        ListRowLabel("Meal plan", systemImage: MySymbols.mealPlan)
                    }
                }
            }

            Section {
                NavigationLink(value: SettingsNavigationItem.appLog) {
                    ListRowLabel("App log", systemImage: MySymbols.logFile)
                }
                NavigationLink(value: SettingsNavigationItem.aboutApp) {
                    ListRowLabel("About this app", systemImage: MySymbols.info)
                }
            }
        }
        .navigationTitle("Settings")
        .task {
            await grocyVM.requestData(additionalObjects: [.system_info, .current_user])
        }
    }
}

/// The account at the top of the settings: the user's picture and name, and the server, like the system settings.
private struct SettingsAccountRow: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    var body: some View {
        HStack(spacing: Spacing.medium) {
            UserAvatarView(pictureFileName: grocyVM.currentUser?.pictureFileName, size: Sizes.avatar)
            VStack(alignment: .leading) {
                if let user = grocyVM.currentUser {
                    Text(user.displayName.isEmpty ? user.username : user.displayName)
                        .font(.headline)
                } else {
                    Text("Account")
                        .font(.headline)
                }
                if let server = grocyVM.serverDisplayName {
                    Text(verbatim: server)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A page of the settings.
private struct SettingsDestinationView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    let destination: SettingsNavigationItem

    var body: some View {
        switch destination {
        case .account:
            SettingsAccountView()
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
}

extension View {
    /// Registers the settings pages. On the stack's root view when the settings are pushed onto it
    /// (`SettingsView(registersDestinations: false)`), otherwise on the settings themselves.
    func settingsDestinations() -> some View {
        navigationDestination(for: SettingsNavigationItem.self) { destination in
            SettingsDestinationView(destination: destination)
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        SettingsView()
    }
}
