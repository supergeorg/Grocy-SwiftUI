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
    case appLog
    case aboutApp
}

struct SettingsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Environment(\.dismiss) var dismiss

    @State private var selection: SettingsNavigationItem? = nil
    @State private var path = NavigationPath()

    @AppStorage("isDemoModus") var isDemoModus: Bool = true
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("grocyServerURL") var grocyServerURL: String = ""
    @AppStorage("grocyAPIKey") var grocyAPIKey: String = ""

    var body: some View {
        NavigationStack(path: $path) {
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
                        Button(
                            action: {
                                grocyVM.logout()
                            },
                            label: {
                                Label("Logout", systemImage: MySymbols.logout)
                                    .foregroundStyle(.red)
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
                case .appLog:
                    LogView()
                case .aboutApp:
                    AboutView()
                }
            }
            .navigationTitle("Settings")
            .task {
                await grocyVM.requestData(additionalObjects: [.system_info, .current_user])
            }
        }
    }
}

#Preview {
    SettingsView()
}
