//
//  SettingsAccountSections.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 27.11.26.
//

import SwiftUI

/// Who is logged in where, like the account at the top of the system settings: the user with their picture and the server,
/// then the server's information. On iOS the top of the settings list, on macOS the Account pane.
struct SettingsAccountSections: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @AppStorage("isDemoModus") private var isDemoModus: Bool = false

    /// The server's address without the scheme and path, or "Demo server".
    private var serverName: Text {
        if isDemoModus {
            return Text("Demo server")
        }
        guard let address = grocyVM.selectedServerProfile?.grocyServerURL else { return Text("Server") }
        return Text(verbatim: URL(string: address)?.host() ?? address)
    }

    private var userName: String {
        guard let user = grocyVM.currentUser else { return "" }
        return user.displayName.isEmpty ? user.username : user.displayName
    }

    var body: some View {
        Section {
            NavigationLink(value: SettingsNavigationItem.userInfo) {
                HStack(spacing: Spacing.medium) {
                    UserAvatarView(pictureFileName: grocyVM.currentUser?.pictureFileName)
                    VStack(alignment: .leading, spacing: Spacing.hairline) {
                        Text(verbatim: userName)
                            .font(.headline)
                        serverName
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, Spacing.xxSmall)
            }
            .disabled(grocyVM.currentUser == nil)
            NavigationLink(value: SettingsNavigationItem.serverInfo) {
                Label("Information about Grocy Server", systemImage: MySymbols.info)
                    .foregroundStyle(.primary)
            }
        }
    }
}

/// Resetting the cache and logging out, at the end of the settings like signing out in the system settings.
struct SettingsLogoutSection: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    var body: some View {
        Section {
            Button {
                grocyVM.deleteAllCachedData()
            } label: {
                Label("Reset cache", systemImage: MySymbols.delete)
                    .foregroundStyle(.primary)
            }
            // The destructive role colors the button, instead of a hard-coded red label.
            Button(role: .destructive) {
                grocyVM.logout()
            } label: {
                Label("Logout", systemImage: MySymbols.logout)
            }
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        Form {
            SettingsAccountSections()
            SettingsLogoutSection()
        }
        .formStyle(.grouped)
    }
}
