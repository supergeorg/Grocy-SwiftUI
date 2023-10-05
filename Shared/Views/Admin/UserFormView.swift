//
//  UserFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftUI

struct UserFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
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
        let foundUsername = grocyVM.users.first(where: {$0.username == username})
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
                grocyVM.postLog("Successfully saved user.", type: .info)
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Saving user failed. \(error)", type: .error)
            }
        } else {
            if let intID = user?.id {
                let userPost = GrocyUserPOST(id: intID, username: username, firstName: firstName, lastName: lastName, password: password, rowCreatedTimestamp: user!.rowCreatedTimestamp)
                do {
                    try await grocyVM.putUser(id: user!.id, user: userPost)
                    grocyVM.postLog("Successfully edited user.", type: .info)
                    await updateData()
                    finishForm()
                } catch {
                    grocyVM.postLog("Editing user failed. \(error)", type: .error)
                }
            }
        }
    }
    
    var body: some View {
#if os(macOS)
        content
#elseif os(iOS)
        content
            .navigationTitle(isNewUser ? LocalizedStringKey("str.admin.user.new.create") : LocalizedStringKey("str.admin.user.new.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("str.cancel")) {
                        finishForm()
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    Button(LocalizedStringKey("str.save")) {
                        Task {
                            await saveUser()
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValidUsername || !isMatchingPassword || password.isEmpty)
                }
            })
#endif
    }
    
    var content: some View {
        Form {
#if os(macOS)
            Text(isNewUser ? LocalizedStringKey("str.admin.user.new.create") : LocalizedStringKey("str.admin.user.new.edit"))
                .font(.headline)
#endif
            Section(header: Text(LocalizedStringKey("str.admin.user.new.userName")).font(.title)){
                MyTextField(textToEdit: $username, description: "str.admin.user.new.userName", isCorrect: $isValidUsername, leadingIcon: "rectangle.and.pencil.and.ellipsis", emptyMessage: "str.admin.user.new.userName.required", errorMessage: "str.admin.user.new.userName.exists")
                    .onChange(of: username) {
                        isValidUsername = checkUsernameCorrect()
                    }
                MyTextField(textToEdit: $firstName, description: "str.admin.user.new.firstName", isCorrect: Binding.constant(true), leadingIcon: "person", errorMessage: nil)
                MyTextField(textToEdit: $lastName, description: "str.admin.user.new.lastName", isCorrect: Binding.constant(true), leadingIcon: "person.2", errorMessage: nil)
            }
            Section(header: Text(LocalizedStringKey("str.admin.user.new.password")).font(.title)){
                MyTextField(textToEdit: $password, description: "str.admin.user.new.password", isCorrect: Binding.constant(true), leadingIcon: "key", errorMessage: nil)
                MyTextField(textToEdit: $passwordConfirm, description: "str.admin.user.new.password.confirm", isCorrect: $isMatchingPassword, leadingIcon: "key", errorMessage: "str.admin.user.new.password.mismatch")
            }
#if os(macOS)
            Divider()
            HStack{
                Button(LocalizedStringKey("str.cancel")) {
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button(LocalizedStringKey("str.save")) {
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
