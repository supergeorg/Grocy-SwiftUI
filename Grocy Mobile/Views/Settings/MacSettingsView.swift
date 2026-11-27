//
//  MacSettingsView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 27.11.26.
//

import SwiftData
import SwiftUI

#if os(macOS)
    /// The Settings window (⌘,) like other Mac apps: a pane per topic, chosen with the tabs in the toolbar,
    /// instead of the iOS list that pushes its pages. General first, then the account and each area's settings.
    /// The app log and the information about the app are windows of their own (Window menu, app menu).
    struct MacSettingsView: View {
        private enum Pane: Hashable {
            case general, account
            case area(SettingsNavigationItem)
        }

        @Environment(GrocyViewModel.self) private var grocyVM

        @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
        @State private var selectedPane: Pane = .general

        @Query private var systemConfigList: [SystemConfig]

        private var areas: [SettingsNavigationItem] {
            isLoggedIn ? SettingsNavigationItem.areas(in: systemConfigList.first) : []
        }

        var body: some View {
            TabView(selection: $selectedPane) {
                Tab(SettingsNavigationItem.appSettings.title, systemImage: SettingsNavigationItem.appSettings.icon, value: Pane.general) {
                    pane {
                        SettingsAppView()
                    }
                }
                if isLoggedIn {
                    Tab("Account", systemImage: MySymbols.user, value: Pane.account) {
                        pane {
                            Form {
                                SettingsAccountSections()
                                SettingsLogoutSection()
                            }
                            .formStyle(.grouped)
                            .navigationTitle("Account")
                        }
                    }
                }
                ForEach(areas, id: \.self) { area in
                    Tab(area.title, systemImage: area.icon, value: Pane.area(area)) {
                        pane {
                            SettingsDestinationView(destination: area)
                        }
                    }
                }
            }
            // Settings windows have a fixed width (HIG); the height can grow for the longer panes.
            .frame(width: Constants.macOSSettingsWidth)
            .frame(minHeight: Constants.macOSSettingsMinHeight, idealHeight: Constants.macOSSettingsHeight)
            .task {
                if isLoggedIn {
                    await grocyVM.requestData(additionalObjects: [.system_config, .system_info, .current_user])
                }
            }
        }

        /// Each pane has its own navigation, so pages like the server's information open inside the pane.
        private func pane(@ViewBuilder content: () -> some View) -> some View {
            NavigationStack {
                content()
                    .settingsDestinations()
            }
        }
    }

    #Preview(traits: .previewData) {
        MacSettingsView()
    }
#endif
