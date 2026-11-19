//
//  UserRowView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftUI

struct UserRowActionsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    var user: GrocyUser
    var isCurrentUser: Bool

    @State private var showDeleteAction: Bool = false
    @State private var showEditUser: Bool = false
    @State private var showPermissions: Bool = false

    private func deleteUser() async {
        do {
            try await grocyVM.deleteUser(id: user.id)
            GrocyLogger.info("Delete user successful.")
            await grocyVM.requestData(additionalObjects: [.users])
        } catch {
            GrocyLogger.error("Delete user failed. \(error)")
        }
    }

    var body: some View {
        // Real buttons (not tap gestures), labeled for VoiceOver; the icon-only style keeps the row compact.
        HStack {
            Button {
                showEditUser = true
            } label: {
                Label("Edit this item", systemImage: MySymbols.edit)
            }
            .help("Edit this item")
            Button {
                showPermissions = true
            } label: {
                Label("Configure user permissions", systemImage: MySymbols.permissions)
            }
            .help("Configure user permissions")
            Button(role: .destructive) {
                showDeleteAction.toggle()
            } label: {
                Label("Delete this item", systemImage: MySymbols.delete)
            }
            .help("Delete this item")
            .disabled(isCurrentUser)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .sheet(isPresented: $showEditUser) {
            NavigationStack {
                UserFormView(isNewUser: false, user: user)
            }
            #if os(macOS)
                .frame(minWidth: Sizes.popoverFormSize, minHeight: Sizes.popoverFormSize)
            #endif
        }
        .sheet(isPresented: $showPermissions) {
            NavigationStack {
                UserPermissionsView(user: user)
            }
            #if os(macOS)
                .frame(minWidth: Sizes.popoverFormSize, minHeight: Sizes.popoverFormSize)
            #endif
        }
        .alert(
            "Are you sure you want to delete user \"\(user.displayName)\"?",
            isPresented: $showDeleteAction,
            actions: {
                Button("Cancel", role: .cancel) {}
                // No destructive role: the person chose to delete, this button carries out their intent (HIG).
                Button("Delete") {
                    Task {
                        await deleteUser()
                    }
                }
            },
            message: {
                Text("This can't be undone.")
            }
        )
    }
}

struct UserRowView: View {
    var user: GrocyUser

    var isCurrentUser: Bool

    var body: some View {
        HStack {
            UserRowActionsView(user: user, isCurrentUser: isCurrentUser)
            Divider()
            VStack(alignment: .leading) {
                Text(user.username)
                    .font(.headline)
                Text(user.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview(traits: .previewData) {
    List {
        UserRowView(
            user: GrocyUser(id: 1, username: "username", firstName: "First name", lastName: "Last name", displayName: "Display Name"),
            isCurrentUser: false
        )
        UserRowView(user: GrocyUser(id: 2, username: "me", displayName: "Current user"), isCurrentUser: true)
    }
}
