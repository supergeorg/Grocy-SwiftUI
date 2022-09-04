//
//  UserFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftUI

struct UserFormView: View {
    @StateObject private var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var username: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var password: String = ""
    @State private var passwordConfirm: String = ""
    
    var isNewUser: Bool
    var user: GrocyUser?
    
    @Binding var toastType: ToastType?
    
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
    
    private func updateData() {
        grocyVM.requestData(additionalObjects: [.users])
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
    
    private func saveUser() {
        if isNewUser {
            let userPost = GrocyUserPOST(id: grocyVM.getNewUserID(), username: username, firstName: firstName, lastName: lastName, password: password, rowCreatedTimestamp: Date().iso8601withFractionalSeconds)
            grocyVM.postUser(user: userPost, completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog("Successfully created object with id \(message.createdObjectID).", type: .info)
                    toastType = .successAdd
                    updateData()
                    finishForm()
                case let .failure(error):
                    grocyVM.postLog("Saving user failed. \(error)", type: .error)
                    toastType = .failAdd
                }
            })
        } else {
            if let intID = user?.id {
                let userPost = GrocyUserPOST(id: intID, username: username, firstName: firstName, lastName: lastName, password: password, rowCreatedTimestamp: user!.rowCreatedTimestamp)
                grocyVM.putUser(id: user!.id, user: userPost, completion: { result in
                    switch result {
                    case let .success(message):
                        grocyVM.postLog("Successfully edited object with id \(message.changedObjectID).", type: .info)
                        toastType = .successEdit
                        updateData()
                        finishForm()
                    case let .failure(error):
                        grocyVM.postLog("Editing user failed. \(error)", type: .error)
                        toastType = .failAdd
                    }
                })
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
                        saveUser()
                        finishForm()
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
                    .onChange(of: username) { newValue in
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
                    saveUser()
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValidUsername || !isMatchingPassword || password.isEmpty)
            }
            #endif
        }
        .onChange(of: password) { newValue in
            checkPWParity()
        }
        .onChange(of: passwordConfirm) {  newValue in
            checkPWParity()
        }
        .toast(
            item: $toastType,
            isSuccess: Binding.constant(false),
            isShown: [.failAdd, .failEdit].contains(toastType),
            text: { item in
            switch item {
            case .failAdd:
                return LocalizedStringKey("str.md.new.fail")
            case .failEdit:
                return LocalizedStringKey("str.md.edit.fail")
            default:
                return LocalizedStringKey("")
            }
        })
    }
}

struct UserFormView_Previews: PreviewProvider {
    static var previews: some View {
        UserFormView(isNewUser: true, toastType: Binding.constant(nil))
    }
}
