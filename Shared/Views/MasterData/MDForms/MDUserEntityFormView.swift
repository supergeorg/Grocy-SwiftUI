//
//  MDUserEntityFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 22.01.21.
//

import SwiftUI

struct MDUserEntityFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstAppear: Bool = true
    
    @State private var name: String = ""
    @State private var caption: String = ""
    @State private var mdUserEntityDescription: String = ""
    @State private var showInSidebarMenu: Bool = false
    
    var isNewUserEntity: Bool
    var userEntity: MDUserEntity?
    
    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundUserEntity = grocyVM.mdUserEntities.first(where: {$0.name == name})
        return isNewUserEntity ? !(name.isEmpty || foundUserEntity != nil) : !(name.isEmpty || (foundUserEntity != nil && foundUserEntity!.id != foundUserEntity!.id))
    }
    
    @State private var isCaptionCorrect: Bool = true
    private func checkCaptionCorrect() -> Bool {
        return !caption.isEmpty
    }
    
    private func resetForm() {
        name = userEntity?.name ?? ""
        caption = userEntity?.caption ?? ""
        mdUserEntityDescription = userEntity?.mdUserEntityDescription ?? ""
        showInSidebarMenu = userEntity?.showInSidebarMenu == "1"
        isNameCorrect = checkNameCorrect()
        isCaptionCorrect = checkCaptionCorrect()
    }
    
    private func updateData() {
        grocyVM.getMDUserEntities()
    }
    
    private func saveUserEntity() {
        let userEntityPost = MDUserEntityPOST(id: isNewUserEntity ? grocyVM.findNextID(.userentities) : Int(userEntity!.id)!, name: name, caption: caption, mdUserEntityDescription: mdUserEntityDescription, showInSidebarMenu: showInSidebarMenu ? "1" : "0", iconCSSClass: nil, rowCreatedTimestamp: isNewUserEntity ? Date().iso8601withFractionalSeconds : userEntity!.rowCreatedTimestamp, userfields: nil)
        if isNewUserEntity {
            grocyVM.postMDObject(object: .userentities, content: userEntityPost)
        } else {
            grocyVM.putMDObjectWithID(object: .userentities, id: userEntity!.id, content: userEntityPost)
        }
        updateData()
    }
    
    var body: some View {
        #if os(macOS)
        ScrollView{
            content
                .padding()
        }
        #elseif os(iOS)
        content
            .navigationTitle(isNewUserEntity ? LocalizedStringKey("str.md.userEntity.new") : LocalizedStringKey("str.md.userEntity.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    if isNewUserEntity {
                        Button(LocalizedStringKey("str.cancel")) {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("str.md.userEntity.save")) {
                        saveUserEntity()
                        presentationMode.wrappedValue.dismiss()
                    }.disabled(!isNameCorrect)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    // Back not shown without it
                    if !isNewUserEntity{
                        Text("")
                    }
                }
            })
        #endif
    }
    
    var content: some View {
        Form {
            Section(header: Text(LocalizedStringKey("str.md.userEntity.name"))){
                MyTextField(textToEdit: $name, description: "str.md.userEntity.name", isCorrect: $isNameCorrect, leadingIcon: "tag", isEditing: true, emptyMessage: "str.md.userEntity.name.required", errorMessage: "str.md.userEntity.name.invalid")
                    .onChange(of: name, perform: {newValue in
                                isNameCorrect = checkNameCorrect() })
                MyTextField(textToEdit: $caption, description: "str.md.userEntity.caption", isCorrect: $isCaptionCorrect, leadingIcon: "tag", isEditing: true, emptyMessage: "str.md.userEntity.caption.required")
                        .onChange(of: caption, perform: {newValue in
                                    isCaptionCorrect = checkCaptionCorrect() })
            }
            
            MyTextField(textToEdit: $mdUserEntityDescription, description: "str.md.userEntity.description", isCorrect: Binding.constant(true), leadingIcon: "text.justifyleft", isEditing: true)
            
            MyToggle(isOn: $showInSidebarMenu, description: "str.md.userEntity.showInSideBarMenu", icon: "tablecells")
            #if os(macOS)
            HStack{
                Button(LocalizedStringKey("str.cancel")) {
                    if isNewUserEntity{
                        NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                    } else {
                        resetForm()
                    }
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button(LocalizedStringKey("str.save")) {
                    saveUserEntity()
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.defaultAction)
            }
            #endif
        }
        .animation(.default)
        .onAppear(perform: {
            if firstAppear {
                updateData()
                resetForm()
                firstAppear = false
            }
        })
    }
}

struct MDUserEntityFormView_Previews: PreviewProvider {
    static var previews: some View {
        MDUserEntityFormView(isNewUserEntity: true)
    }
}
