//
//  UserFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftData
import SwiftUI

struct UserFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query var users: GrocyUsers

    @Environment(\.dismiss) var dismiss

    @State private var username: String
    @State private var firstName: String
    @State private var lastName: String
    @State private var password: String = ""
    @State private var passwordConfirm: String = ""

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var isNewUser: Bool
    var user: GrocyUser?

    init(isNewUser: Bool, user: GrocyUser? = nil) {
        self.isNewUser = isNewUser
        self.user = user
        _username = State(initialValue: user?.username ?? "")
        _firstName = State(initialValue: user?.firstName ?? "")
        _lastName = State(initialValue: user?.lastName ?? "")
        _isValidUsername = State(initialValue: !(user?.username.isEmpty ?? true))
    }

    @State private var isValidUsername: Bool
    private func checkUsernameCorrect() -> Bool {
        guard !username.isEmpty else { return false }
        let foundUser = users.first(where: { $0.username == username })
        return foundUser == nil || (!isNewUser && foundUser?.id == user?.id)
    }

    /// A new user needs a password; an edit keeps the current one when both fields stay empty.
    private var isMatchingPassword: Bool {
        password == passwordConfirm && (!isNewUser || !password.isEmpty)
    }

    private func updateData() async {
        await grocyVM.requestData(additionalObjects: [.users])
    }

    private func saveUser() async {
        isProcessing = true
        isSuccessful = nil
        do {
            if isNewUser {
                let userPost = GrocyUserPOST(
                    id: grocyVM.getNewUserID(),
                    username: username,
                    firstName: firstName,
                    lastName: lastName,
                    password: password,
                    rowCreatedTimestamp: Date()
                )
                try await grocyVM.postUser(user: userPost)
                GrocyLogger.info("Creating user was successful.")
            } else if let user {
                let userPost = GrocyUserPOST(
                    id: user.id,
                    username: username,
                    firstName: firstName,
                    lastName: lastName,
                    password: password,
                    pictureFileName: user.pictureFileName,
                    rowCreatedTimestamp: user.rowCreatedTimestamp
                )
                try await grocyVM.putUser(id: user.id, user: userPost)
                GrocyLogger.info("Editing user was successful.")
            }
            await updateData()
            isSuccessful = true
        } catch {
            GrocyLogger.error("Saving user failed. \(error)")
            errorMessage = (error as? APIError)?.displayMessage ?? error.localizedDescription
            isSuccessful = false
        }
        isProcessing = false
    }

    var body: some View {
        Form {
            if isSuccessful == false, let errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            Section(header: Text("Username")) {
                MyTextField(
                    textToEdit: $username,
                    description: "Username",
                    isCorrect: $isValidUsername,
                    leadingIcon: MySymbols.user,
                    emptyMessage: "A username is required",
                    errorMessage: "Username already exists"
                )
                .onChange(of: username) {
                    isValidUsername = checkUsernameCorrect()
                }
                MyTextField(textToEdit: $firstName, description: "First name", isCorrect: .constant(true), leadingIcon: MySymbols.user)
                MyTextField(textToEdit: $lastName, description: "Last name", isCorrect: .constant(true), leadingIcon: MySymbols.user)
            }
            Section {
                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
                SecureField("Confirm password", text: $passwordConfirm)
                    .textContentType(.newPassword)
                if password != passwordConfirm, !passwordConfirm.isEmpty {
                    Text("Passwords do not match")
                        .font(.caption)
                        .foregroundStyle(Color(.GrocyColors.grocyRed))
                }
            } header: {
                Text("Password")
            } footer: {
                if !isNewUser {
                    Text("Leave empty to keep the current password.")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(isNewUser ? "Create user" : "Edit user")
        .toolbar(content: {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(
                    role: .confirm,
                    action: {
                        Task {
                            await saveUser()
                        }
                    }
                )
                .keyboardShortcut(.defaultAction)
                .disabled(!isValidUsername || !isMatchingPassword || isProcessing)
            }
        })
        .onChange(of: isSuccessful) {
            if isSuccessful == true {
                dismiss()
            }
        }
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }
}

#Preview("Create", traits: .previewData) {
    NavigationStack {
        UserFormView(isNewUser: true)
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        UserFormView(isNewUser: false, user: GrocyUser(id: 1, username: "demo", firstName: "Demo", lastName: "User", displayName: "Demo User"))
    }
}
