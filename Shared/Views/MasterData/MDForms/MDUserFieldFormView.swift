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
    
    @State private var entity: ObjectEntities = ObjectEntities.none
    @State private var name: String = ""
    @State private var caption: String = ""
    @State private var sortNumber: Int = -1
    @State private var type: UserFieldType = .none
    @State private var showAsColumnInTables: Bool = false
    
    var isNewUserField: Bool
    var userField: MDUserField?
    
    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundUserField = grocyVM.mdUserFields.first(where: {$0.name == name})
        return isNewUserField ? !(name.isEmpty || foundUserField != nil) : !(name.isEmpty || (foundUserField != nil && foundUserField!.id != foundUserField!.id))
    }
    
    @State private var isTitleCorrect: Bool = true
    
    private func resetForm() {
        entity = ObjectEntities(rawValue: userField?.entity ?? "") ?? ObjectEntities.none
        name = userField?.name ?? ""
        caption = userField?.caption ?? ""
        sortNumber = Int(userField?.sortNumber ?? "") ?? -1
        type = UserFieldType(rawValue: userField?.type ?? "") ?? .none
        showAsColumnInTables = Bool(userField?.showAsColumnInTables ?? "0") ?? false
        isNameCorrect = checkNameCorrect()
    }
    
    private func saveUserField() {
        let sortNumberStr = sortNumber < 0 ? nil : String(sortNumber)
        if isNewUserField {
            grocyVM.postMDObject(object: .userfields, content: MDUserFieldPOST(id: grocyVM.findNextID(.userfields), entity: entity.rawValue, name: name, caption: caption, type: type.rawValue, showAsColumnInTables: showAsColumnInTables ? "1" : "0", rowCreatedTimestamp: Date().iso8601withFractionalSeconds, config: nil, sortNumber: sortNumberStr, userfields: nil))
        } else {
            grocyVM.putMDObjectWithID(object: .userfields, id: userField!.id, content: MDUserFieldPOST(id: Int(userField!.id)!, entity: entity.rawValue, name: name, caption: caption, type: type.rawValue, showAsColumnInTables: showAsColumnInTables ? "1" : "0", rowCreatedTimestamp: userField!.rowCreatedTimestamp, config: nil, sortNumber: sortNumberStr, userfields: nil))
        }
        grocyVM.getMDUserFields()
    }
    
    var body: some View {
        #if os(macOS)
        ScrollView{
        content
            .padding()
        }
        #elseif os(iOS)
        #endif
    }
    
    var content: some View {
        Form {
            Picker(selection: $entity, label: Text(LocalizedStringKey("str.md.userField.entity")), content: {
                ForEach(ObjectEntities.allCases, id:\.self){ objectEntity in
                    Text(objectEntity.rawValue).tag(objectEntity)
                }
            })
            if entity == .none {
                Text(LocalizedStringKey("str.md.userField.entity.required"))
                    .foregroundColor(.red)
            }
            
            Section(header: Text(LocalizedStringKey("str.md.userField.name"))){
                MyTextField(textToEdit: $name, description: "str.md.userField.name", isCorrect: $isNameCorrect, leadingIcon: "tag", isEditing: true, errorMessage: "str.md.userField.name.required", helpText: "str.md.userField.name.info")
                MyTextField(textToEdit: $caption, description: "str.md.userField.caption", isCorrect: $isTitleCorrect, leadingIcon: "tag", isEditing: true, errorMessage: "str.md.userField.caption.required", helpText: "str.md.userField.caption.info")
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
                Button("str.cancel") {
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("str.save") {
                    saveUserField()
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.defaultAction)
            }
            #endif
        }
        .navigationTitle(isNewUserField ? "str.md.userField.new" : "str.md.userField.edit")
        .animation(.default)
        .onAppear(perform: {
            resetForm()
        })
        .toolbar(content: {
            #if os(iOS)
            ToolbarItem(placement: .cancellationAction) {
                if isNewUserField {
                    Button("str.cancel") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("str.md.save \("str.md.userField".localized)") {
                    saveUserField()
                    presentationMode.wrappedValue.dismiss()
                }.disabled(!isNameCorrect)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                // Back not shown without it
                if !isNewUserField{
                    Text("")
                }
            }
            #endif
        })
    }
}

struct MDUserFieldFormView_Previews: PreviewProvider {
    static var previews: some View {
        MDUserFieldFormView(isNewUserField: true)
    }
}
