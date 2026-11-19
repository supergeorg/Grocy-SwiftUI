//
//  UserPermissionsView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 19.11.26.
//

import SwiftUI

/// The permissions of a user, as Grocy's permission tree.
///
/// A chosen permission includes everything below it, so those rows show as on and can't be changed.
/// Changing permissions needs the ADMIN permission.
struct UserPermissionsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.dismiss) private var dismiss

    var user: GrocyUser

    @State private var hierarchy: GrocyPermissions = []
    @State private var selectedIDs: Set<Int> = []
    @State private var isLoading: Bool = true
    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    /// The permissions in tree order, with their depth for the indentation.
    private var rows: [(permission: GrocyPermission, depth: Int)] {
        var result: [(GrocyPermission, Int)] = []
        func add(_ parentID: Int?, depth: Int) {
            for permission in hierarchy.children(of: parentID) {
                result.append((permission, depth))
                add(permission.id, depth: depth + 1)
            }
        }
        add(nil, depth: 0)
        return result
    }

    /// The permissions that come with a chosen permission above them.
    private var inheritedIDs: Set<Int> {
        selectedIDs.reduce(into: Set<Int>()) { result, id in
            result.formUnion(hierarchy.descendantIDs(of: id))
        }
    }

    private func load() async {
        isLoading = true
        do {
            hierarchy = try await grocyVM.getPermissionHierarchy()
            selectedIDs = try await grocyVM.getUserPermissionIDs(userID: user.id)
            errorMessage = nil
        } catch {
            GrocyLogger.error("Loading permissions of user \(user.username) failed. \(error)")
            errorMessage = (error as? APIError)?.displayMessage ?? error.localizedDescription
            isSuccessful = false
        }
        isLoading = false
    }

    private func save() async {
        isProcessing = true
        isSuccessful = nil
        // Only the chosen permissions; the ones below them come with them.
        let inherited = inheritedIDs
        do {
            try await grocyVM.putUserPermissions(userID: user.id, permissionIDs: selectedIDs.subtracting(inherited))
            GrocyLogger.info("Saving permissions of user \(user.username) was successful.")
            isSuccessful = true
        } catch {
            GrocyLogger.error("Saving permissions of user \(user.username) failed. \(error)")
            errorMessage = (error as? APIError)?.displayMessage ?? error.localizedDescription
            isSuccessful = false
        }
        isProcessing = false
    }

    private func binding(for id: Int) -> Binding<Bool> {
        Binding(
            get: { selectedIDs.contains(id) || inheritedIDs.contains(id) },
            set: { isOn in
                if isOn {
                    selectedIDs.insert(id)
                } else {
                    selectedIDs.remove(id)
                }
            }
        )
    }

    var body: some View {
        Form {
            if isSuccessful == false, let errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Section {
                    ForEach(rows, id: \.permission.id) { row in
                        Toggle(isOn: binding(for: row.permission.id)) {
                            Text(Self.displayName(of: row.permission))
                        }
                        .disabled(inheritedIDs.contains(row.permission.id))
                        .padding(.leading, CGFloat(row.depth) * Spacing.large)
                    }
                } footer: {
                    Text("A permission includes all permissions below it.")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Permissions for \(user.displayName)")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) {
                    Task {
                        await save()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isLoading || isProcessing || hierarchy.isEmpty)
            }
        }
        .task {
            await load()
        }
        .onChange(of: isSuccessful) {
            if isSuccessful == true {
                dismiss()
            }
        }
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }

    /// Grocy's names for its permissions; unknown (newer) ones show their internal name.
    static func displayName(of permission: GrocyPermission) -> LocalizedStringKey {
        switch permission.name {
        case "ADMIN": "All permissions"
        case "USERS": "User management"
        case "USERS_CREATE": "Create users"
        case "USERS_EDIT": "Edit users (including passwords)"
        case "USERS_READ": "Show users"
        case "USERS_EDIT_SELF": "Edit own user data / change own password"
        case "STOCK": "Stock"
        case "STOCK_PURCHASE": "Purchase"
        case "STOCK_CONSUME": "Consume"
        case "STOCK_INVENTORY": "Inventory"
        case "STOCK_TRANSFER": "Transfer"
        case "STOCK_OPEN": "Open products"
        case "STOCK_EDIT": "Edit stock entries"
        case "SHOPPINGLIST": "Shopping list"
        case "SHOPPINGLIST_ITEMS_ADD": "Add items"
        case "SHOPPINGLIST_ITEMS_DELETE": "Remove items"
        case "RECIPES": "Recipes"
        case "RECIPES_MEALPLAN": "Meal plan"
        case "CHORES": "Chores"
        case "CHORE_TRACK_EXECUTION": "Track execution"
        case "CHORE_UNDO_EXECUTION": "Undo execution"
        case "BATTERIES": "Batteries"
        case "BATTERIES_TRACK_CHARGE_CYCLE": "Track charge cycle"
        case "BATTERIES_UNDO_CHARGE_CYCLE": "Undo charge cycle"
        case "TASKS": "Tasks"
        case "TASKS_MARK_COMPLETED": "Mark completed"
        case "TASKS_UNDO_EXECUTION": "Undo execution"
        case "EQUIPMENT": "Equipment"
        case "CALENDAR": "Calendar"
        case "MASTER_DATA_EDIT": "Edit master data"
        default: LocalizedStringKey(permission.name)
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        UserPermissionsView(user: GrocyUser(id: 1, username: "demo", displayName: "Demo User"))
    }
}
