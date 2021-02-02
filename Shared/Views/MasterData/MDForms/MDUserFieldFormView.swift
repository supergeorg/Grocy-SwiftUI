//
//  MDUserFieldFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 16.12.20.
//

import SwiftUI

struct MDUserFieldFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstAppear: Bool = true
    
    @State private var entity: ObjectEntities?
    @State private var name: String = ""
    @State private var caption: String = ""
    @State private var sortNumber: Int? = -1 // TODO ???
    @State private var type: UserFieldType = UserFieldType.none
    @State private var showAsColumnInTables: Bool = false
    
    var isNewUserField: Bool
    var userField: MDUserField?
    
    @Binding var toastType: MDToastType?
    
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
        sortNumber = Int(userField?.sortNumber ?? "") ?? -1
        type = UserFieldType(rawValue: userField?.type ?? "") ?? UserFieldType.none
        showAsColumnInTables = Bool(userField?.showAsColumnInTables ?? "0") ?? false
        isNameCorrect = checkNameCorrect()
        isCaptionCorrect = checkCaptionCorrect()
    }
    
    private func updateData() {
        grocyVM.getMDUserFields()
    }
    
    private func finishForm() {
        #if os(iOS)
        presentationMode.wrappedValue.dismiss()
        #elseif os(macOS)
        if isNewUserField {
            NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
        }
        #endif
    }
    
    private func saveUserField() {
        let sortNumberStr = sortNumber ?? 0 < 0 ? nil : String(sortNumber ?? 0)
        if let entity = entity {
            if isNewUserField {
                let userFieldPOST = MDUserFieldPOST(id: grocyVM.findNextID(.userfields), entity: entity.rawValue, name: name, caption: caption, type: type.rawValue, showAsColumnInTables: showAsColumnInTables ? "1" : "0", rowCreatedTimestamp: Date().iso8601withFractionalSeconds, config: nil, sortNumber: sortNumberStr, userfields: nil)
                grocyVM.postMDObject(object: .userfields, content: userFieldPOST, completion: { result in
                    switch result {
                    case let .success(message):
                        print(message)
                        toastType = .successAdd
                        resetForm()
                        updateData()
                        finishForm()
                    case let .failure(error):
                        print("\(error)")
                        toastType = .failAdd
                    }
                })
            } else {
                let userFieldPOST = MDUserFieldPOST(id: Int(userField!.id)!, entity: entity.rawValue, name: name, caption: caption, type: type.rawValue, showAsColumnInTables: showAsColumnInTables ? "1" : "0", rowCreatedTimestamp: userField!.rowCreatedTimestamp, config: nil, sortNumber: sortNumberStr, userfields: nil)
                grocyVM.putMDObjectWithID(object: .userfields, id: userField!.id, content: userFieldPOST, completion: { result in
                    switch result {
                    case let .success(message):
                        print(message)
                        toastType = .successEdit
                        updateData()
                        finishForm()
                    case let .failure(error):
                        print("\(error)")
                        toastType = .failEdit
                    }
                })
            }
        }
    }
    
    var body: some View {
        #if os(macOS)
        ScrollView{
            content
                .padding()
        }
        #elseif os(iOS)
        content
            .navigationTitle(isNewUserField ? LocalizedStringKey("str.md.userField.new") : LocalizedStringKey("str.md.userField.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    if isNewUserField {
                        Button(LocalizedStringKey("str.cancel")) {
                            finishForm()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("str.md.userField.save")) {
                        saveUserField()
                    }.disabled(!isNameCorrect)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    // Back not shown without it
                    if !isNewUserField{
                        Text("")
                    }
                }
            })
        #endif
    }
    
    var content: some View {
        Form {
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
                MyTextField(textToEdit: $name, description: "str.md.userField.name", isCorrect: $isNameCorrect, leadingIcon: "tag", isEditing: true, emptyMessage: "str.md.userField.name.required", errorMessage: "str.md.userField.name.invalid", helpText: "str.md.userField.name.info")
                    .onChange(of: name, perform: {newValue in
                                isNameCorrect = checkNameCorrect() })
                MyTextField(textToEdit: $caption, description: "str.md.userField.caption", isCorrect: $isCaptionCorrect, leadingIcon: "tag", isEditing: true, emptyMessage: "str.md.userField.caption.required", helpText: "str.md.userField.caption.info")
                    .onChange(of: caption, perform: {newValue in
                                isCaptionCorrect = checkCaptionCorrect() })
            }
            MyIntStepper(amount: $sortNumber, description: "str.md.userField.sortNumber", helpText: "str.md.userField.sortNumber.info", minAmount: -1, errorMessage: "str.md.userField.sortNumber.error", systemImage: "list.number")
            
            Picker(selection: $type, label: Text(LocalizedStringKey("str.md.userField.type")), content: {
                ForEach(UserFieldType.allCases, id:\.self) { userFieldType in
                    Text(LocalizedStringKey(userFieldType.getDescription())).tag(userFieldType)
                }
            })
            
            MyToggle(isOn: $showAsColumnInTables, description: "str.md.userField.showAsColumnInTables", icon: "tablecells")
            #if os(macOS)
            HStack{
                Button(LocalizedStringKey("str.cancel")) {
                    if isNewUserField{
                        finishForm()
                    } else {
                        resetForm()
                    }
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button(LocalizedStringKey("str.save")) {
                    saveUserField()
                }
                .keyboardShortcut(.defaultAction)
            }
            #endif
        }
        .animation(.default)
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestDataIfUnavailable(objects: [.userfields])
                resetForm()
                firstAppear = false
            }
        })
    }
}

struct MDUserFieldFormView_Previews: PreviewProvider {
    static var previews: some View {
        MDUserFieldFormView(isNewUserField: true, toastType: Binding.constant(.successAdd))
    }
}
