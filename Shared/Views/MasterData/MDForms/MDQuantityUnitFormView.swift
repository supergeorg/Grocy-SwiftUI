//
//  MDQuantityUnitFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDQuantityUnitFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstAppear: Bool = true
    
    @State private var name: String = ""
    @State private var namePlural: String = ""
    @State private var mdQuantityUnitDescription: String = ""
    
    var isNewQuantityUnit: Bool
    var quantityUnit: MDQuantityUnit?
    
    @Binding var toastType: MDToastType?
    
    @State var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundQuantityUnit = grocyVM.mdQuantityUnits.first(where: {$0.name == name})
        return isNewQuantityUnit ? !(name.isEmpty || foundQuantityUnit != nil) : !(name.isEmpty || (foundQuantityUnit != nil && foundQuantityUnit!.id != quantityUnit!.id))
    }
    
    private func resetForm() {
        self.name = quantityUnit?.name ?? ""
        self.namePlural = quantityUnit?.namePlural ?? ""
        self.mdQuantityUnitDescription = quantityUnit?.mdQuantityUnitDescription ?? ""
        isNameCorrect = checkNameCorrect()
    }
    
    private func updateData() {
        grocyVM.getMDQuantityUnits()
    }
    
    private func finishForm() {
        #if os(iOS)
        presentationMode.wrappedValue.dismiss()
        #elseif os(macOS)
        if isNewQuantityUnit {
            NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
        }
        #endif
    }
    
    private func saveQuantityUnit() {
        if isNewQuantityUnit {
            let quPOST = MDQuantityUnitPOST(id: grocyVM.findNextID(.quantity_units), name: name, mdQuantityUnitDescription: mdQuantityUnitDescription, rowCreatedTimestamp: Date().iso8601withFractionalSeconds, namePlural: namePlural, pluralForms: nil, userfields: nil)
            grocyVM.postMDObject(object: .quantity_units, content: quPOST, completion: { result in
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
            let quPOST = MDQuantityUnitPOST(id: Int(quantityUnit!.id)!, name: name, mdQuantityUnitDescription: mdQuantityUnitDescription, rowCreatedTimestamp: quantityUnit!.rowCreatedTimestamp, namePlural: namePlural, pluralForms: nil, userfields: nil)
            grocyVM.putMDObjectWithID(object: .quantity_units, id: quantityUnit!.id, content: quPOST, completion: { result in
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
    
    var body: some View {
        #if os(macOS)
        ScrollView {
            content
                .padding()
        }
        #elseif os(iOS)
        content
            .navigationTitle(isNewQuantityUnit ? LocalizedStringKey("str.md.quantityUnit.new") : LocalizedStringKey("str.md.quantityUnit.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    if isNewQuantityUnit {
                        Button(LocalizedStringKey("str.cancel")) {
                            finishForm()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("str.md.quantityUnit.save")) {
                        saveQuantityUnit()
                    }.disabled(!isNameCorrect)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    // Back not shown without it
                    if !isNewQuantityUnit{
                        Text("")
                    }
                }
            })
        #endif
    }
    
    var content: some View {
        Form {
            Section(header: Text(LocalizedStringKey("str.md.quantityUnit.info"))){
                MyTextField(textToEdit: $name, description: "str.md.quantityUnit.name", isCorrect: $isNameCorrect, leadingIcon: "tag", isEditing: true, errorMessage: "str.md.quantityUnit.name.required")
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
                MyTextField(textToEdit: $namePlural, description: "str.md.quantityUnit.namePlural", isCorrect: Binding.constant(true), leadingIcon: "tag", isEditing: true)
                MyTextField(textToEdit: $mdQuantityUnitDescription, description: "str.md.description", isCorrect: Binding.constant(true), leadingIcon: "text.justifyleft", isEditing: true)
            }
            #if os(macOS)
            HStack{
                Button(LocalizedStringKey("str.cancel")) {
                    if isNewQuantityUnit{
                        finishForm()
                    } else {
                        resetForm()
                    }
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button(LocalizedStringKey("str.save")) {
                    saveQuantityUnit()
                }
                .keyboardShortcut(.defaultAction)
            }
            #endif
        }
        .animation(.default)
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestDataIfUnavailable(objects: [.quantity_units])
                resetForm()
                firstAppear = false
            }
        })
    }
}

struct MDQuantityUnitFormView_Previews: PreviewProvider {
    static var previews: some View {
        #if os(macOS)
        Group {
            MDQuantityUnitFormView(isNewQuantityUnit: true, toastType: Binding.constant(.successAdd))
            MDQuantityUnitFormView(isNewQuantityUnit: false, quantityUnit: MDQuantityUnit(id: "0", name: "Quantity unit", mdQuantityUnitDescription: "Description", rowCreatedTimestamp: "", namePlural: "QU Plural", pluralForms: nil, userfields: nil), toastType: Binding.constant(.successAdd))
        }
        #else
        Group {
            NavigationView {
                MDQuantityUnitFormView(isNewQuantityUnit: true, toastType: Binding.constant(.successAdd))
            }
            NavigationView {
                MDQuantityUnitFormView(isNewQuantityUnit: false, quantityUnit: MDQuantityUnit(id: "0", name: "Quantity unit", mdQuantityUnitDescription: "Description", rowCreatedTimestamp: "", namePlural: "QU Plural", pluralForms: nil, userfields: nil), toastType: Binding.constant(.successAdd))
            }
        }
        #endif
    }
}
