//
//  MDUserEntityFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 22.01.21.
//

import SwiftUI

struct MDUserEntityFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
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
    
    
    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
//        let foundUserEntity = grocyVM.mdUserEntities.first(where: {$0.name == name})
//        return isNewUserEntity ? !(name.isEmpty || foundUserEntity != nil) : !(name.isEmpty || (foundUserEntity != nil && foundUserEntity!.id != foundUserEntity!.id))
        return false
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
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
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
    
    private func saveUserEntity() async {
        let id: Int = isNewUserEntity ? grocyVM.findNextID(.userentities) : userEntity!.id
        let timeStamp = isNewUserEntity ? Date().iso8601withFractionalSeconds : userEntity!.rowCreatedTimestamp
        let userEntityPOST = MDUserEntity(id: id, name: name, caption: caption, mdUserEntityDescription: mdUserEntityDescription, showInSidebarMenu: showInSidebarMenu ? 1 : 0, iconCSSClass: nil, rowCreatedTimestamp: timeStamp)
        isProcessing = true
        if isNewUserEntity {
            do {
                _ = try await grocyVM.postMDObject(object: .userentities, content: userEntityPOST)
                grocyVM.postLog("User entity add successful.", type: .info)
                resetForm()
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("User entity add failed. \(error)", type: .error)
            }
        } else {
            do {
                try await grocyVM.putMDObjectWithID(object: .userentities, id: id, content: userEntityPOST)
                grocyVM.postLog("User entity edit successful.", type: .info)
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("User entity edit failed. \(error)", type: .error)
            }
        }
        isProcessing = false
    }
    
    var body: some View {
        content
            .navigationTitle(isNewUserEntity ? "New userentity" : "Edit userentity")
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { Task { await saveUserEntity() } }, label: {
                        Label("Save userentity", systemImage: MySymbols.save)
                            .labelStyle(.titleAndIcon)
                    })
                    .disabled(!isNameCorrect || isProcessing)
                    .keyboardShortcut(.defaultAction)
                }
#if os(iOS)
                ToolbarItem(placement: .cancellationAction) {
                    if isNewUserEntity {
                        Button("Cancel") {
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
            Text(isNewUserEntity ? "New userentity" : "Edit userentity")
                .font(.title)
                .bold()
                .padding(.bottom, 20.0)
#endif
            Section(header: Text("Name of the userentity")){
                MyTextField(textToEdit: $name, description: "Name of the userentity", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "This is required and can only contain letters and numbers", errorMessage: "This is required and can only contain letters and numbers")
                    .onChange(of: name) {
                        isNameCorrect = checkNameCorrect()
                    }
                MyTextField(textToEdit: $caption, description: "Caption", isCorrect: $isCaptionCorrect, leadingIcon: "tag", emptyMessage: "A caption is required")
                    .onChange(of: caption) {
                        isCaptionCorrect = checkCaptionCorrect()
                    }
            }
            
            MyTextField(textToEdit: $mdUserEntityDescription, description: "Description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
            
            MyToggle(isOn: $showInSidebarMenu, description: "Show in sidebar menu", icon: "tablecells")
        }
        .task {
            if firstAppear {
                await updateData()
                resetForm()
                firstAppear = false
            }
        }
    }
}

struct MDUserEntityFormView_Previews: PreviewProvider {
    static var previews: some View {
        MDUserEntityFormView(isNewUserEntity: true, showAddUserEntity: Binding.constant(false))
    }
}
