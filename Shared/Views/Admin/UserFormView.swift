//
//  UserFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import SwiftUI

struct UserFormView: View {
    @StateObject private var grocyVM: GrocyViewModel = .shared
    
    @State var username: String = ""
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var password: String = ""
    @State var passwordConfirm: String = ""
    
    var isNewUser: Bool
    var user: GrocyUser?
    
    @State var isValidUsername: Bool = false
    private func checkUsernameCorrect() -> Bool {
        let foundUsername = grocyVM.users.first(where: {$0.username == username})
        return isNewUser ? !(username.isEmpty || foundUsername != nil) : !(username.isEmpty || (foundUsername != nil && foundUsername!.id != user!.id))
    }
    
    @State var isMatchingPassword: Bool = true
    private func checkPWParity() {
        if (password == passwordConfirm) && (!password.isEmpty) {
            isMatchingPassword = true
        } else {
            isMatchingPassword = false
        }
    }
    
    private func saveUser() {
        if isNewUser {
            let userPost = GrocyUserPOST(id: grocyVM.getNewUserID(), username: username, firstName: firstName, lastName: lastName, password: password, rowCreatedTimestamp: Date().iso8601withFractionalSeconds)
            grocyVM.postUser(user: userPost)
        } else {
            if let intID = Int(user?.id ?? "") {
                let userPost = GrocyUserPOST(id: intID, username: username, firstName: firstName, lastName: lastName, password: password, rowCreatedTimestamp: user!.rowCreatedTimestamp)
                grocyVM.putUser(id: user!.id, user: userPost)
            }
        }
        grocyVM.getUsers()
    }
    
    var body: some View {
        #if os(macOS)
        content
        #elseif os(iOS)
        content
            .navigationTitle(isNewUser ? LocalizedStringKey("str.admin.user.new.create") : LocalizedStringKey("str.admin.user.new.edit"))
        #endif
    }
    
    var content: some View {
        Form {
            #if os(macOS)
            Text(isNewUser ? LocalizedStringKey("str.admin.user.new.create") : LocalizedStringKey("str.admin.user.new.edit"))
                .font(.headline)
            #endif
            Section(header: Text(LocalizedStringKey("str.admin.user.new.userName")).font(.title)){
                MyTextField(textToEdit: $username, description: "str.admin.user.new.userName", isCorrect: $isValidUsername, leadingIcon: "rectangle.and.pencil.and.ellipsis", isEditing: true, emptyMessage: "str.admin.user.new.userName.required", errorMessage: "str.admin.user.new.userName.exists")
                    .onChange(of: username) { newValue in
                        isValidUsername = checkUsernameCorrect()
                    }
                MyTextField(textToEdit: $firstName, description: "str.admin.user.new.firstName", isCorrect: Binding.constant(true), leadingIcon: "person", isEditing: true, errorMessage: nil)
                MyTextField(textToEdit: $lastName, description: "str.admin.user.new.lastName", isCorrect: Binding.constant(true), leadingIcon: "person.2", isEditing: true, errorMessage: nil)
            }
            Divider()
            Section(header: Text(LocalizedStringKey("str.admin.user.new.password")).font(.title)){
                MyTextField(textToEdit: $password, description: "str.admin.user.new.password", isCorrect: Binding.constant(true), leadingIcon: "key", isEditing: true, errorMessage: nil)
                MyTextField(textToEdit: $passwordConfirm, description: "str.admin.user.new.password.confirm", isCorrect: $isMatchingPassword, leadingIcon: "key", isEditing: true, errorMessage: "str.admin.user.new.password.mismatch")
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
    }
}

struct UserFormView_Previews: PreviewProvider {
    static var previews: some View {
        UserFormView(isNewUser: true)
    }
}
