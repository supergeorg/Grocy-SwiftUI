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
    
    @State private var name: String = ""
    @State private var namePlural: String = ""
    @State private var mdQuantityUnitDescription: String = ""
    
    @State private var showDeleteAlert: Bool = false
    
    var isNewQuantityUnit: Bool
    var quantityUnit: MDQuantityUnit?
    
    @State var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundQuantityUnit = grocyVM.mdQuantityUnits.first(where: {$0.name == name})
        return isNewQuantityUnit ? !(name.isEmpty || foundQuantityUnit != nil) : !(name.isEmpty || (foundQuantityUnit != nil && foundQuantityUnit!.id != quantityUnit!.id))
    }
    
    private func resetForm() {
        if isNewQuantityUnit {
            self.name = ""
            self.namePlural = ""
            self.mdQuantityUnitDescription = ""
        } else {
            self.name = quantityUnit!.name
            self.namePlural = quantityUnit!.namePlural
            self.mdQuantityUnitDescription = quantityUnit!.mdQuantityUnitDescription ?? ""
        }
        isNameCorrect = checkNameCorrect()
    }
    
    private func saveQuantityUnit() {
        if isNewQuantityUnit {
            grocyVM.postMDObject(object: .quantity_units, content: MDQuantityUnitPOST(id: grocyVM.findNextID(.quantity_units), name: name, mdQuantityUnitDescription: mdQuantityUnitDescription, rowCreatedTimestamp: Date().iso8601withFractionalSeconds, namePlural: namePlural, pluralForms: nil, userfields: nil))
        } else {
            grocyVM.putMDObjectWithID(object: .quantity_units, id: quantityUnit!.id, content: MDQuantityUnitPOST(id: Int(quantityUnit!.id)!, name: name, mdQuantityUnitDescription: mdQuantityUnitDescription, rowCreatedTimestamp: quantityUnit!.rowCreatedTimestamp, namePlural: namePlural, pluralForms: nil, userfields: nil))
        }
        grocyVM.getMDQuantityUnits()
    }
    
    private func deleteQuantityUnit() {
        grocyVM.deleteMDObject(object: .quantity_units, id: quantityUnit!.id)
        grocyVM.getMDQuantityUnits()
    }
    
    var body: some View {
        Form {
            Section(header: Text("str.md.quantityUnit.info")){
                MyTextField(textToEdit: $name, description: "str.md.quantityUnit.name", isCorrect: $isNameCorrect, leadingIcon: "tag", isEditing: true, errorMessage: "str.md.quantityUnit.name.required")
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
                MyTextField(textToEdit: $namePlural, description: "str.md.quantityUnit.namePlural", isCorrect: Binding.constant(true), leadingIcon: "tag", isEditing: true)
                MyTextField(textToEdit: $mdQuantityUnitDescription, description: "str.md.description", isCorrect: Binding.constant(true), leadingIcon: "text.justifyleft", isEditing: true)
            }
            #if os(macOS)
            HStack{
                Button("str.cancel") {
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("str.save") {
                    saveQuantityUnit()
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.defaultAction)
            }
            #endif
            if !isNewQuantityUnit {
                Button(action: {
                    showDeleteAlert.toggle()
                }, label: {
                    Label("str.md.delete \("str.md.quantityUnit".localized)", systemImage: "trash")
                        .foregroundColor(.red)
                })
                .keyboardShortcut(.delete)
                .alert(isPresented: $showDeleteAlert) {
                    Alert(title: Text("str.md.quantityUnit.delete.confirm"), message: Text(""), primaryButton: .destructive(Text("str.delete")) {
                        deleteQuantityUnit()
                        #if os(macOS)
                        NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                        #else
                        presentationMode.wrappedValue.dismiss()
                        #endif
                    }, secondaryButton: .cancel())
                }
            }
        }
        .navigationTitle(isNewQuantityUnit ? "str.md.quantityUnit.new" : "str.md.quantityUnit.edit")
        .animation(.default)
        .onAppear(perform: {
            resetForm()
        })
        .toolbar(content: {
            #if os(iOS)
            ToolbarItem(placement: .cancellationAction) {
                if isNewQuantityUnit {
                    Button("str.cancel") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("str.md.save \("str.md.quantityUnit".localized)") {
                    saveQuantityUnit()
                    presentationMode.wrappedValue.dismiss()
                }.disabled(!isNameCorrect)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                // Back not shown without it
                if !isNewQuantityUnit{
                    Text("")
                }
            }
            #endif
        })
    }
}

struct MDQuantityUnitFormView_Previews: PreviewProvider {
    static var previews: some View {
        #if os(macOS)
        Group {
            MDQuantityUnitFormView(isNewQuantityUnit: true)
            MDQuantityUnitFormView(isNewQuantityUnit: false, quantityUnit: MDQuantityUnit(id: "0", name: "Quantity unit", mdQuantityUnitDescription: "Description", rowCreatedTimestamp: "", namePlural: "QU Plural", pluralForms: nil, userfields: nil))
        }
        #else
        Group {
            NavigationView {
                MDQuantityUnitFormView(isNewQuantityUnit: true)
            }
            NavigationView {
                MDQuantityUnitFormView(isNewQuantityUnit: false, quantityUnit: MDQuantityUnit(id: "0", name: "Quantity unit", mdQuantityUnitDescription: "Description", rowCreatedTimestamp: "", namePlural: "QU Plural", pluralForms: nil, userfields: nil))
            }
        }
        #endif
    }
}
