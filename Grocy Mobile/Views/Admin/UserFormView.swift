//
//  UserFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftUI
import SwiftData

struct UserFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query var users: GrocyUsers
    
    @Environment(\.dismiss) var dismiss
    
    @State private var username: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var password: String = ""
    @State private var passwordConfirm: String = ""
    
    var isNewUser: Bool
    var user: GrocyUser?
    
    
    
    @State private var isValidUsername: Bool = false
    private func checkUsernameCorrect() -> Bool {
        let foundUsername = users.first(where: {$0.username == username})
        return isNewUser ? !(username.isEmpty || foundUsername != nil) : !(username.isEmpty || (foundUsername != nil && foundUsername!.id != user!.id))
    }
    
    @State private var isMatchingPassword: Bool = true
    private func checkPWParity() {
        if (password == passwordConfirm) && (!password.isEmpty) {
            isMatchingPassword = true
        } else {
            isMatchingPassword = false
        }
    }
    
    private func updateData() async {
        await grocyVM.requestData(additionalObjects: [.users])
    }
    
    private func finishForm() {
#if os(iOS)
        self.dismiss()
#elseif os(macOS)
        if isNewUser {
            NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
        }
#endif
    }
    
    private func saveUser() async {
        if isNewUser {
            let userPost = GrocyUserPOST(id: grocyVM.getNewUserID(), username: username, firstName: firstName, lastName: lastName, password: password, rowCreatedTimestamp: Date().iso8601withFractionalSeconds)
            do {
                try await grocyVM.postUser(user: userPost)
                GrocyLogger.info("Successfully saved user.")
                await updateData()
                finishForm()
            } catch {
                GrocyLogger.error("Saving user failed. \(error)")
            }
        } else {
            if let intID = user?.id {
                let userPost = GrocyUserPOST(id: intID, username: username, firstName: firstName, lastName: lastName, password: password, rowCreatedTimestamp: user!.rowCreatedTimestamp)
                do {
                    try await grocyVM.putUser(id: user!.id, user: userPost)
                    GrocyLogger.info("Successfully edited user.")
                    await updateData()
                    finishForm()
                } catch {
                    GrocyLogger.error("Editing user failed. \(error)")
                }
            }
        }
    }
    
    var body: some View {
#if os(macOS)
        content
#elseif os(iOS)
        content
            .navigationTitle(isNewUser ? "Create user" : "Edit user")
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        finishForm()
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    Button(role: .confirm, action: {
                        Task {
                            await saveUser()
                        }
                    })
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValidUsername || !isMatchingPassword || password.isEmpty)
                }
            })
#endif
    }
    
    var content: some View {
        Form {
#if os(macOS)
            Text(isNewUser ? "Create user" : "Edit user")
                .font(.headline)
#endif
            Section(header: Text("Username").font(.title)){
                MyTextField(textToEdit: $username, description: "Username", isCorrect: $isValidUsername, leadingIcon: "rectangle.and.pencil.and.ellipsis", emptyMessage: "A username is required", errorMessage: "Username already exists")
                    .onChange(of: username) {
                        isValidUsername = checkUsernameCorrect()
                    }
                MyTextField(textToEdit: $firstName, description: "First name", isCorrect: Binding.constant(true), leadingIcon: "person", errorMessage: nil)
                MyTextField(textToEdit: $lastName, description: "Last name", isCorrect: Binding.constant(true), leadingIcon: "person.2", errorMessage: nil)
            }
            Section(header: Text("Password").font(.title)){
                MyTextField(textToEdit: $password, description: "Password", isCorrect: Binding.constant(true), leadingIcon: "key", errorMessage: nil)
                MyTextField(textToEdit: $passwordConfirm, description: "Confirm password", isCorrect: $isMatchingPassword, leadingIcon: "key", errorMessage: "Passwords do not match")
            }
#if os(macOS)
            Divider()
            HStack{
                Button("Cancel") {
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    Task {
                        await saveUser()
                    }
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValidUsername || !isMatchingPassword || password.isEmpty)
            }
#endif
        }
        .onChange(of: password) {
            checkPWParity()
        }
        .onChange(of: passwordConfirm) {
            checkPWParity()
        }
    }
}

#Preview {
    UserFormView(isNewUser: true)
}
