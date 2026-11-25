//
//  GrocyUserInfoView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 05.01.21.
//

import SwiftData
import SwiftUI

/// The logged-in user, who can edit their own names, password and picture here (Grocy's USERS_EDIT_SELF permission).
struct GrocyUserInfoView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query private var systemConfigList: [SystemConfig]

    @State private var showEditProfile: Bool = false

    var grocyUser: GrocyUser? = nil

    var body: some View {
        Form {
            if let grocyUser = grocyUser {
                Section {
                    HStack(spacing: Spacing.large) {
                        UserAvatarView(pictureFileName: grocyUser.pictureFileName, size: Sizes.userPicture)
                        VStack(alignment: .leading) {
                            Text(grocyUser.displayName.isEmpty ? grocyUser.username : grocyUser.displayName)
                                .font(.title2)
                            Text(grocyUser.username)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                if systemConfigList.first?.disableAuth != true {
                    Section {
                        Button {
                            showEditProfile = true
                        } label: {
                            Label("Edit profile", systemImage: MySymbols.edit)
                        }
                    } footer: {
                        Text("Change your name, password and picture.")
                    }
                }
            } else {
                Text("Unknown")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("User")
        .sheet(isPresented: $showEditProfile) {
            if let grocyUser {
                NavigationStack {
                    UserFormView(isNewUser: false, user: grocyUser, editsOwnProfile: true)
                }
                #if os(macOS)
                    .frame(minWidth: Sizes.popoverFormSize, minHeight: Sizes.popoverFormSize)
                #endif
            }
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        GrocyUserInfoView(grocyUser: GrocyUser(username: "Username", displayName: "Display Name"))
    }
}
