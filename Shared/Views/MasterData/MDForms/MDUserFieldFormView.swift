//
//  MDUserFieldFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 16.12.20.
//

import SwiftUI

struct MDUserFieldFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var entity: ObjectEntities?
    @State private var name: String = ""
    @State private var caption: String = ""
    @State private var sortNumber: Int? = -1
    @State private var type: UserFieldType = UserFieldType.none
    @State private var showAsColumnInTables: Bool = false
    
    var isNewUserField: Bool
    var userField: MDUserField?
    
    @Binding var showAddUserField: Bool
    @State var toastType: ToastType? = nil
    
    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundUserField = grocyVM.mdUserFields.first(where: {$0.name == name})
        return isNewUserField ? !(name.isEmpty || foundUserField != nil) : !(name.isEmpty || (foundUserField != nil && foundUserField!.id != foundUserField!.id))
    }
    
    @State private var isCaptionCorrect: Bool = true
    private func checkCaptionCorrect() -> Bool {
        return !caption.isEmpty
    }
    
    private func resetForm() {
        entity = ObjectEntities(rawValue: userField?.entity ?? "")
        name = userField?.name ?? ""
        caption = userField?.caption ?? ""
        sortNumber = userField?.sortNumber ?? -1
        type = UserFieldType(rawValue: userField?.type ?? "") ?? UserFieldType.none
        showAsColumnInTables = userField?.showAsColumnInTables == 1
        isNameCorrect = checkNameCorrect()
        isCaptionCorrect = checkCaptionCorrect()
    }
    
    private let dataToUpdate: [ObjectEntities] = [.userfields]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private func finishForm() {
#if os(iOS)
        self.dismiss()
#elseif os(macOS)
        if isNewUserField {
            showAddUserField = false
        }
#endif
    }
    
    private func saveUserField() async {
        if let entity = entity {
            let id = isNewUserField ? grocyVM.findNextID(.userfields) : userField!.id
            let timeStamp = isNewUserField ? Date().iso8601withFractionalSeconds : userField!.rowCreatedTimestamp
            let userFieldPOST = MDUserField(id: id, name: name, entity: entity.rawValue, caption: caption, type: type.rawValue, showAsColumnInTables: showAsColumnInTables ? 1 : 0, config: nil, sortNumber: sortNumber, rowCreatedTimestamp: timeStamp)
            isProcessing = true
            if isNewUserField {
                do {
                    _ = try await grocyVM.postMDObject(object: .userfields, content: userFieldPOST)
                                            grocyVM.postLog("Userfield add successful.", type: .info)
                                            toastType = .successAdd
                                            resetForm()
                                            await updateData()
                                            finishForm()
                } catch {
                                            grocyVM.postLog("Userfield add failed. \(error)", type: .error)
                                            toastType = .failAdd
                }
            } else {
                do {
                    _ = try await grocyVM.putMDObjectWithID(object: .userfields, id: id, content: userFieldPOST)
                                            grocyVM.postLog("Userfield edit successful.", type: .info)
                                            toastType = .successEdit
                                            await updateData()
                                            finishForm()
                } catch {
                                            grocyVM.postLog("Userfield edit failed. \(error)", type: .error)
                                            toastType = .failEdit
                }
            }
            isProcessing = true
        }
    }
    
    var body: some View {
        content
            .navigationTitle(isNewUserField ? LocalizedStringKey("str.md.userField.new") : LocalizedStringKey("str.md.userField.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { Task { await saveUserField() } }, label: {
                        Label(LocalizedStringKey("str.md.userField.save"), systemImage: MySymbols.save)
                            .labelStyle(.titleAndIcon)
                    })
                    .disabled(!isNameCorrect || isProcessing)
                    .keyboardShortcut(.defaultAction)
                }
#if os(iOS)
                ToolbarItem(placement: .cancellationAction) {
                    if isNewUserField {
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
            Text(isNewUserField ? LocalizedStringKey("str.md.userField.new") : LocalizedStringKey("str.md.userField.edit"))
                .font(.title)
                .bold()
                .padding(.bottom, 20.0)
#endif
            VStack(alignment: .leading){
                Picker(selection: $entity, label: Text(LocalizedStringKey("str.md.userField.entity")), content: {
                    Text("").tag(nil as ObjectEntities?)
                    ForEach(ObjectEntities.allCases, id:\.self){ objectEntity in
                        Text(objectEntity.rawValue).tag(objectEntity as ObjectEntities?)
                    }
                })
                if entity == nil {
                    Text(LocalizedStringKey("str.md.userField.entity.required"))
                        .foregroundColor(.red)
                }
            }
            
            Section(header: Text(LocalizedStringKey("str.md.userField.name"))){
                MyTextField(textToEdit: $name, description: "str.md.userField.name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "str.md.userField.name.required", errorMessage: "str.md.userField.name.invalid", helpText: "str.md.userField.name.info")
                    .onChange(of: name) {
                        isNameCorrect = checkNameCorrect()
                    }
                MyTextField(textToEdit: $caption, description: "str.md.userField.caption", isCorrect: $isCaptionCorrect, leadingIcon: "tag", emptyMessage: "str.md.userField.caption.required", helpText: "str.md.userField.caption.info")
                    .onChange(of: caption) {
                        isCaptionCorrect = checkCaptionCorrect()
                    }
            }
            MyIntStepperOptional(amount: $sortNumber, description: "str.md.userField.sortNumber", helpText: "str.md.userField.sortNumber.info", minAmount: -1, errorMessage: "str.md.userField.sortNumber.error", systemImage: "list.number")
            
            Picker(selection: $type, label: Text(LocalizedStringKey("str.md.userField.type")), content: {
                ForEach(UserFieldType.allCases, id:\.self) { userFieldType in
                    Text(LocalizedStringKey(userFieldType.getDescription())).tag(userFieldType)
                }
            })
            
            MyToggle(isOn: $showAsColumnInTables, description: "str.md.userField.showAsColumnInTables", icon: "tablecells")
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

struct MDUserFieldFormView_Previews: PreviewProvider {
    static var previews: some View {
        MDUserFieldFormView(isNewUserField: true, showAddUserField: Binding.constant(true))
    }
}
