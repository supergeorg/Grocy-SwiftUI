//
//  SettingsAccountView.swift
//  Grocy Mobile
//

import SwiftUI

/// The signed-in user and the server, with resetting the cache and logging out at the end,
/// like the account page of the system settings.
struct SettingsAccountView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @State private var showLogoutConfirmation: Bool = false

    var body: some View {
        Form {
            Section {
                if let currentUser = grocyVM.currentUser {
                    NavigationLink(value: SettingsNavigationItem.userInfo) {
                        ListRowLabel("Logged in as user \(currentUser.displayName)", systemImage: MySymbols.user)
                    }
                }
                NavigationLink(value: SettingsNavigationItem.serverInfo) {
                    ListRowLabel("Information about Grocy Server", systemImage: MySymbols.info)
                }
            } footer: {
                if let server = grocyVM.serverDisplayName {
                    Text(verbatim: server)
                }
            }

            Section {
                Button {
                    grocyVM.deleteAllCachedData()
                } label: {
                    ListRowLabel("Reset cache", systemImage: MySymbols.delete)
                }
            } footer: {
                Text("Loads all data from the server again.")
            }

            Section {
                // The destructive role colors the button, instead of a hard-coded red label.
                Button(role: .destructive) {
                    showLogoutConfirmation = true
                } label: {
                    Label("Logout", systemImage: MySymbols.logout)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Account")
        .confirmationDialog("Logout", isPresented: $showLogoutConfirmation) {
            Button("Logout", role: .destructive) {
                grocyVM.logout()
            }
        } message: {
            Text("The data saved on this device is deleted. You can log in again at any time.")
        }
        .task {
            await grocyVM.requestData(additionalObjects: [.system_info, .current_user])
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        SettingsAccountView()
            .settingsDestinations()
    }
}
