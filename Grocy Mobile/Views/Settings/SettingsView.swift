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

    /// Built like the system settings: the account first, then the app's general settings, the settings of each area,
    /// the app's log and information, and logging out at the end. Sections without headers, rows named like their pages.
    private var content: some View {
        List {
            if isLoggedIn {
                SettingsAccountSections()
            }
            Section {
                settingsLink(.appSettings)
            }
            Section {
                ForEach(SettingsNavigationItem.areas(in: systemConfig), id: \.self) { area in
                    settingsLink(area)
                }
            }
            Section {
                settingsLink(.appLog)
                settingsLink(.aboutApp)
            }
            if isLoggedIn {
                SettingsLogoutSection()
            }
        }
        .navigationTitle("Settings")
        .task {
            await grocyVM.requestData(additionalObjects: [.system_info, .current_user])
        }
    }

    private func settingsLink(_ item: SettingsNavigationItem) -> some View {
        NavigationLink(value: item) {
            Label(item.title, systemImage: item.icon)
                .foregroundStyle(.primary)
        }
    }
}

extension SettingsNavigationItem {
    /// The areas with a settings page of their own, in the sidebar's order. Like Grocy's own settings,
    /// an area the server turned off has none. Until the config is loaded, every area is shown.
    static func areas(in systemConfig: SystemConfig?) -> [SettingsNavigationItem] {
        var areas: [SettingsNavigationItem] = []
        if systemConfig?.featureFlagStock != false { areas.append(.stockSettings) }
        if systemConfig?.featureFlagShoppinglist != false { areas.append(.shoppingListSettings) }
        if systemConfig?.featureFlagRecipes != false {
            areas.append(.recipesSettings)
            if systemConfig?.featureFlagRecipesMealplan != false { areas.append(.mealPlanSettings) }
        }
        if systemConfig?.featureFlagChores != false { areas.append(.choresSettings) }
        if systemConfig?.featureFlagTasks != false { areas.append(.tasksSettings) }
        if systemConfig?.featureFlagBatteries != false { areas.append(.batteriesSettings) }
        return areas
    }

    /// The row's and the page's title. Within the settings, "settings" in each title would only repeat itself.
    var title: LocalizedStringKey {
        switch self {
        case .serverInfo: "Information about Grocy Server"
        case .userInfo: "User"
        case .appSettings: "General"
        case .stockSettings: "Stock"
        case .shoppingListSettings: "Shopping list"
        case .choresSettings: "Chores"
        case .tasksSettings: "Tasks"
        case .batteriesSettings: "Batteries"
        case .recipesSettings: "Recipes"
        case .mealPlanSettings: "Meal plan"
        case .appLog: "App log"
        case .aboutApp: "About this app"
        case .phoneTabs: "Tabs"
        }
    }

    var icon: String {
        switch self {
        case .serverInfo, .aboutApp: MySymbols.info
        case .userInfo: MySymbols.user
        case .appSettings: MySymbols.settings
        case .stockSettings: MySymbols.stockOverview
        case .shoppingListSettings: MySymbols.shoppingList
        case .choresSettings: MySymbols.chores
        case .tasksSettings: MySymbols.tasks
        case .batteriesSettings: MySymbols.batteries
        case .recipesSettings: MySymbols.recipe
        case .mealPlanSettings: MySymbols.mealPlan
        case .appLog: MySymbols.logFile
        case .phoneTabs: MySymbols.chooseTabs
        }
    }
}

/// A page of the settings.
struct SettingsDestinationView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    let destination: SettingsNavigationItem

    var body: some View {
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
