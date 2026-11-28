//
//  UserManagementView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 23.11.20.
//

import SwiftData
import SwiftUI

/// Grocy's user management: all users, to create, edit and delete them and to configure their permissions.
///
/// Listing users needs the USERS_READ permission. Permissions can only be read and changed by admins,
/// so their actions only show for an admin (`GrocyViewModel.isCurrentUserAdmin`).
struct UserManagementView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    /// False where the stack's root registers the user form (`userManagementDestinations()`), e.g. when the user
    /// management is pushed from the iPhone's settings button: a destination registered on a pushed page isn't found there.
    var registersDestinations: Bool = true

    @Query(sort: \GrocyUser.username) var users: GrocyUsers
    @Query private var systemConfigList: [SystemConfig]

    @State private var searchString: String = ""

    @State private var showAddUser: Bool = false
    /// The form for a new object zooms out of the create button.
    @Namespace private var addTransition
    @State private var userForPermissions: GrocyUser? = nil
    @State private var userToDelete: GrocyUser? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var deleteErrorMessage: String? = nil

    private let additionalDataToUpdate: [AdditionalEntities] = [.users, .current_user]

    private func updateData() async {
        await grocyVM.requestData(additionalObjects: additionalDataToUpdate)
        await grocyVM.checkCurrentUserIsAdmin()
    }

    /// Grocy without its own login has no permissions to configure.
    private var canConfigurePermissions: Bool {
        grocyVM.isCurrentUserAdmin == true && systemConfigList.first?.disableAuth != true
    }

    var filteredUsers: GrocyUsers {
        guard !searchString.isEmpty else { return users }
        return users.filter {
            $0.username.localizedStandardContains(searchString) || $0.displayName.localizedStandardContains(searchString)
        }
    }

    private func isCurrentUser(_ user: GrocyUser) -> Bool {
        grocyVM.currentUser?.id == user.id
    }

    private func deleteUser(_ user: GrocyUser) async {
        do {
            try await grocyVM.deleteUser(id: user.id)
            GrocyLogger.info("Deleting user was successful.")
            if let pictureFileName = user.pictureFileName, !pictureFileName.isEmpty {
                do {
                    try await grocyVM.deleteUserPicture(fileName: pictureFileName)
                } catch {
                    GrocyLogger.warning("Deleting the picture of the deleted user failed. \(error)")
                }
            }
            await grocyVM.reloadUsers()
        } catch {
            GrocyLogger.error("Deleting user failed. \(error)")
            deleteErrorMessage = (error as? APIError)?.displayMessage ?? error.localizedDescription
        }
    }

    var body: some View {
        if grocyVM.failedToLoadAdditionalObjects.filter({ additionalDataToUpdate.contains($0) }).count == 0 {
            content
        } else {
            ServerProblemView()
                .navigationTitle("User management")
        }
    }

    var content: some View {
        List {
            ForEach(filteredUsers, id: \.id) { user in
                NavigationLink(value: user) {
                    UserRowView(user: user, isCurrentUser: isCurrentUser(user))
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if !isCurrentUser(user) {
                        Button(role: .destructive) {
                            userToDelete = user
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: MySymbols.delete)
                        }
                    }
                }
                .swipeActions(edge: .leading) {
                    if canConfigurePermissions {
                        Button {
                            userForPermissions = user
                        } label: {
                            Label("Configure user permissions", systemImage: MySymbols.permissions)
                        }
                        .tint(Color(.GrocyColors.grocyBlue))
                    }
                }
                .contextMenu {
                    if canConfigurePermissions {
                        Button {
                            userForPermissions = user
                        } label: {
                            Label("Configure user permissions", systemImage: MySymbols.permissions)
                        }
                    }
                    if !isCurrentUser(user) {
                        Button(role: .destructive) {
                            userToDelete = user
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: MySymbols.delete)
                        }
                    }
                }
            }
        }
        .overlay {
            if users.isEmpty {
                ContentUnavailableView("No users found", systemImage: MySymbols.user)
            } else if filteredUsers.isEmpty {
                ContentUnavailableView.search
            }
        }
        .navigationTitle("User management")
        .userManagementDestinations(isEnabled: registersDestinations)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddUser = true
                } label: {
                    Label("Create user", systemImage: MySymbols.new)
                        .macHelp("Create user")
                }
            }
            #if os(iOS)
                .matchedTransitionSource(id: ZoomTransitionID.add, in: addTransition)
            #endif
        }
        .sheet(isPresented: $showAddUser) {
            NavigationStack {
                UserFormView(isNewUser: true)
            }
            #if os(iOS)
                .navigationTransition(.zoom(sourceID: ZoomTransitionID.add, in: addTransition))
            #endif
            #if os(macOS)
                .frame(minWidth: Sizes.popoverFormSize, minHeight: Sizes.popoverFormSize)
            #endif
        }
        .sheet(item: $userForPermissions) { user in
            NavigationStack {
                UserPermissionsView(user: user)
            }
            #if os(macOS)
                .frame(minWidth: Sizes.popoverFormSize, minHeight: Sizes.popoverFormSize)
            #endif
        }
        .alert(
            "Are you sure you want to delete user \"\(userToDelete?.displayName ?? "")\"?",
            isPresented: $showDeleteConfirmation,
            presenting: userToDelete,
            actions: { user in
                Button("Cancel", role: .cancel) {}
                // No destructive role: the person chose to delete, this button carries out their intent (HIG).
                Button("Delete") {
                    Task {
                        await deleteUser(user)
                    }
                }
            },
            message: { _ in
                Text("This can't be undone.")
            }
        )
        .alert(
            "Deleting the user failed",
            isPresented: Binding(get: { deleteErrorMessage != nil }, set: { if !$0 { deleteErrorMessage = nil } }),
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text(deleteErrorMessage ?? "")
            }
        )
        .task {
            await updateData()
        }
        .refreshable {
            await updateData()
        }
        .searchable(text: $searchString, prompt: "Search")
    }
}

extension View {
    /// Registers the form of an existing user. On the stack's root view when the user management is pushed onto it
    /// (`UserManagementView(registersDestinations: false)`), otherwise on the user management itself.
    @ViewBuilder
    func userManagementDestinations(isEnabled: Bool = true) -> some View {
        if isEnabled {
            navigationDestination(for: GrocyUser.self) { user in
                UserFormView(isNewUser: false, user: user)
            }
        } else {
            self
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        UserManagementView()
    }
}
