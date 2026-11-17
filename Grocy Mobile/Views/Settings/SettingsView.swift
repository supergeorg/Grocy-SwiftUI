//
//  SettingsView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 28.10.20.
//

import SwiftUI

enum SettingsNavigationItem: Hashable {
    case serverInfo
    case userInfo
    case appSettings
    case stockSettings
    case shoppingListSettings
    case choresSettings
    case batteriesSettings
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
                NavigationLink(value: SettingsNavigationItem.stockSettings) {
                    Label("Stock settings", systemImage: MySymbols.stockOverview)
                        .foregroundStyle(.primary)
                }
                NavigationLink(value: SettingsNavigationItem.shoppingListSettings) {
                    Label("Shopping list settings", systemImage: MySymbols.shoppingList)
                        .foregroundStyle(.primary)
                }
                NavigationLink(value: SettingsNavigationItem.choresSettings) {
                    Label("Chores settings", systemImage: MySymbols.chores)
                        .foregroundStyle(.primary)
                }
                NavigationLink(value: SettingsNavigationItem.batteriesSettings) {
                    Label("Batteries settings", systemImage: MySymbols.batteries)
                        .foregroundStyle(.primary)
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
            case .batteriesSettings:
                SettingsBatteriesView()
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
