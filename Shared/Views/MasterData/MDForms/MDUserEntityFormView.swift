//
//  MDUserEntityFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 22.01.21.
//

import SwiftUI

struct MDUserEntityFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var name: String = ""
    @State private var caption: String = ""
    @State private var mdUserEntityDescription: String = ""
    @State private var showInSidebarMenu: Bool = false
    
    var isNewUserEntity: Bool
    var userEntity: MDUserEntity?
    
    @Binding var showAddUserEntity: Bool
    @Binding var toastType: ToastType?
    
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
        showInSidebarMenu = userEntity?.showInSidebarMenu == 1
        isNameCorrect = checkNameCorrect()
        isCaptionCorrect = checkCaptionCorrect()
    }
    
    private let dataToUpdate: [ObjectEntities] = [.userentities]
    private func updateData() {
        Task {
            await grocyVM.requestData(objects: dataToUpdate)
        }
    }
    
    private func finishForm() {
#if os(iOS)
        self.dismiss()
#elseif os(macOS)
        if isNewUserEntity {
            showAddUserEntity = false
        }
#endif
    }
    
    private func saveUserEntity() {
        let id: Int = isNewUserEntity ? grocyVM.findNextID(.userentities) : userEntity!.id
        let timeStamp = isNewUserEntity ? Date().iso8601withFractionalSeconds : userEntity!.rowCreatedTimestamp
        let userEntityPOST = MDUserEntity(id: id, name: name, caption: caption, mdUserEntityDescription: mdUserEntityDescription, showInSidebarMenu: showInSidebarMenu ? 1 : 0, iconCSSClass: nil, rowCreatedTimestamp: timeStamp)
        isProcessing = true
        if isNewUserEntity {
//            grocyVM.postMDObject(object: .userentities, content: userEntityPOST, completion: { result in
//                switch result {
//                case let .success(message):
//                    grocyVM.postLog("User entity add successful. \(message)", type: .info)
//                    toastType = .successAdd
//                    resetForm()
//                    updateData()
//                    finishForm()
//                case let .failure(error):
//                    grocyVM.postLog("User entity add failed. \(error)", type: .error)
//                    toastType = .failAdd
//                }
//                isProcessing = false
//            })
        } else {
//            grocyVM.putMDObjectWithID(object: .userentities, id: id, content: userEntityPOST, completion: { result in
//                switch result {
//                case let .success(message):
//                    grocyVM.postLog("User entity edit successful. \(message)", type: .info)
//                    toastType = .successEdit
//                    updateData()
//                    finishForm()
//                case let .failure(error):
//                    grocyVM.postLog("User entity edit failed. \(error)", type: .error)
//                    toastType = .failEdit
//                }
//                isProcessing = false
//            })
        }
    }
    
    var body: some View {
        content
            .navigationTitle(isNewUserEntity ? LocalizedStringKey("str.md.userEntity.new") : LocalizedStringKey("str.md.userEntity.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveUserEntity, label: {
                        Label(LocalizedStringKey("str.md.userEntity.save"), systemImage: MySymbols.save)
                            .labelStyle(.titleAndIcon)
                    })
                    .disabled(!isNameCorrect || isProcessing)
                    .keyboardShortcut(.defaultAction)
                }
#if os(iOS)
                ToolbarItem(placement: .cancellationAction) {
                    if isNewUserEntity {
                        Button(LocalizedStringKey("str.cancel")) {
                            finishForm()
                        }
                    }
                }
#endif
            })
    }
    
    var content: some View {
        Form {
#if os(macOS)
            Text(isNewUserEntity ? LocalizedStringKey("str.md.userEntity.new") : LocalizedStringKey("str.md.userEntity.edit"))
                .font(.title)
                .bold()
                .padding(.bottom, 20.0)
#endif
            Section(header: Text(LocalizedStringKey("str.md.userEntity.name"))){
                MyTextField(textToEdit: $name, description: "str.md.userEntity.name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "str.md.userEntity.name.required", errorMessage: "str.md.userEntity.name.invalid")
                    .onChange(of: name, perform: {newValue in
                        isNameCorrect = checkNameCorrect() })
                MyTextField(textToEdit: $caption, description: "str.md.userEntity.caption", isCorrect: $isCaptionCorrect, leadingIcon: "tag", emptyMessage: "str.md.userEntity.caption.required")
                    .onChange(of: caption, perform: {newValue in
                        isCaptionCorrect = checkCaptionCorrect() })
            }
            
            MyTextField(textToEdit: $mdUserEntityDescription, description: "str.md.userEntity.description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
            
            MyToggle(isOn: $showInSidebarMenu, description: "str.md.userEntity.showInSideBarMenu", icon: "tablecells")
        }
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
        MDUserEntityFormView(isNewUserEntity: true, showAddUserEntity: Binding.constant(false), toastType: Binding.constant(nil))
    }
}
