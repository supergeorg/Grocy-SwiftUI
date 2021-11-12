//
//  MDQuantityUnitFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDQuantityUnitFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var name: String = ""
    @State private var namePlural: String = ""
    @State private var mdQuantityUnitDescription: String = ""
    
    var isNewQuantityUnit: Bool
    var quantityUnit: MDQuantityUnit?
    
    @Binding var showAddQuantityUnit: Bool
    @Binding var toastType: MDToastType?
    
    @State private var isNameCorrect: Bool = false
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
    
    private let dataToUpdate: [ObjectEntities] = [.quantity_units]
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate)
    }
    
    private func finishForm() {
#if os(iOS)
        self.dismiss()
#elseif os(macOS)
        if isNewQuantityUnit {
            showAddQuantityUnit = false
        }
#endif
    }
    
    private func saveQuantityUnit() {
        let id = isNewQuantityUnit ? grocyVM.findNextID(.quantity_units) : quantityUnit!.id
        let timeStamp = isNewQuantityUnit ? Date().iso8601withFractionalSeconds : quantityUnit!.rowCreatedTimestamp
        let quantityUnitPOST = MDQuantityUnit(id: id, name: name, namePlural: namePlural, mdQuantityUnitDescription: mdQuantityUnitDescription, rowCreatedTimestamp: timeStamp)
        isProcessing = true
        if isNewQuantityUnit {
            grocyVM.postMDObject(object: .quantity_units, content: quantityUnitPOST, completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog(message: "Quantity unit add successful. \(message)", type: .info)
                    toastType = .successAdd
                    resetForm()
                    updateData()
                    finishForm()
                case let .failure(error):
                    grocyVM.postLog(message: "Quantity unit add failed. \(error)", type: .error)
                    toastType = .failAdd
                }
                isProcessing = false
            })
        } else {
            grocyVM.putMDObjectWithID(object: .quantity_units, id: id, content: quantityUnitPOST, completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog(message: "Quantity unit edit successful. \(message)", type: .info)
                    toastType = .successEdit
                    updateData()
                    finishForm()
                case let .failure(error):
                    grocyVM.postLog(message: "Quantity unit edit failed. \(error)", type: .error)
                    toastType = .failEdit
                }
                isProcessing = false
            })
        }
    }
    
    var body: some View {
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
                    }
                    .disabled(!isNameCorrect || isProcessing)
                }
            })
    }
    
    var content: some View {
        Form {
            Section(header: Text(LocalizedStringKey("str.md.quantityUnit.info"))){
                MyTextField(textToEdit: $name, description: "str.md.quantityUnit.name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "str.md.quantityUnit.name.required", errorMessage: "str.md.quantityUnit.name.exists")
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
                MyTextField(textToEdit: $namePlural, description: "str.md.quantityUnit.namePlural", isCorrect: Binding.constant(true), leadingIcon: "tag")
                MyTextField(textToEdit: $mdQuantityUnitDescription, description: "str.md.description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
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
                .disabled(!isNameCorrect || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
#endif
        }
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestData(objects: dataToUpdate, ignoreCached: false)
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
            MDQuantityUnitFormView(isNewQuantityUnit: true, showAddQuantityUnit: Binding.constant(true), toastType: Binding.constant(.successAdd))
            MDQuantityUnitFormView(isNewQuantityUnit: false, quantityUnit: MDQuantityUnit(id: 0, name: "Quantity unit", namePlural: "QU Plural", mdQuantityUnitDescription: "Description", rowCreatedTimestamp: ""), showAddQuantityUnit: Binding.constant(false), toastType: Binding.constant(.successAdd))
        }
#else
        Group {
            NavigationView {
                MDQuantityUnitFormView(isNewQuantityUnit: true, showAddQuantityUnit: Binding.constant(true), toastType: Binding.constant(.successAdd))
            }
            NavigationView {
                MDQuantityUnitFormView(isNewQuantityUnit: false, quantityUnit: MDQuantityUnit(id: 0, name: "Quantity unit", namePlural: "QU Plural", mdQuantityUnitDescription: "Description", rowCreatedTimestamp: ""), showAddQuantityUnit: Binding.constant(false), toastType: Binding.constant(.successAdd))
            }
        }
#endif
    }
}
