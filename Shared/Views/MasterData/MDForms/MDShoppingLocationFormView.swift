//
//  MDShoppingLocationFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDShoppingLocationFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var name: String = ""
    @State private var mdShoppingLocationDescription: String = ""
    
    var isNewShoppingLocation: Bool
    var shoppingLocation: MDShoppingLocation?
    
    @Binding var showAddShoppingLocation: Bool
    @Binding var toastType: ToastType?
    
    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundShoppingLocation = grocyVM.mdShoppingLocations.first(where: {$0.name == name})
        return isNewShoppingLocation ? !(name.isEmpty || foundShoppingLocation != nil) : !(name.isEmpty || (foundShoppingLocation != nil && foundShoppingLocation!.id != shoppingLocation!.id))
    }
    
    private func resetForm() {
        self.name = shoppingLocation?.name ?? ""
        self.mdShoppingLocationDescription = shoppingLocation?.mdShoppingLocationDescription ?? ""
        isNameCorrect = checkNameCorrect()
    }
    
    private let dataToUpdate: [ObjectEntities] = [.shopping_locations]
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate)
    }
    
    private func finishForm() {
#if os(iOS)
        self.dismiss()
#elseif os(macOS)
        if isNewShoppingLocation {
            showAddShoppingLocation = false
        }
#endif
    }
    
    private func saveShoppingLocation() {
        let id = isNewShoppingLocation ? grocyVM.findNextID(.shopping_locations) : shoppingLocation!.id
        let timeStamp = isNewShoppingLocation ? Date().iso8601withFractionalSeconds : shoppingLocation!.rowCreatedTimestamp
        let shoppingLocationPOST = MDShoppingLocation(id: id, name: name, mdShoppingLocationDescription: mdShoppingLocationDescription, rowCreatedTimestamp: timeStamp)
        isProcessing = true
        if isNewShoppingLocation {
            grocyVM.postMDObject(object: .shopping_locations, content: shoppingLocationPOST, completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog("Shopping location add successful. \(message)", type: .info)
                    toastType = .successAdd
                    updateData()
                    finishForm()
                case let .failure(error):
                    grocyVM.postLog("Shopping location add failed. \(error)", type: .error)
                    toastType = .failAdd
                }
                isProcessing = false
            })
        } else {
            grocyVM.putMDObjectWithID(object: .shopping_locations, id: id, content: shoppingLocationPOST, completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog("Shopping location edit successful. \(message)", type: .info)
                    toastType = .successEdit
                    updateData()
                    finishForm()
                case let .failure(error):
                    grocyVM.postLog("Shopping location add failed. \(error)", type: .error)
                    toastType = .failEdit
                }
                isProcessing = false
            })
        }
        
    }
    
    var body: some View {
        content
            .navigationTitle(isNewShoppingLocation ? LocalizedStringKey("str.md.shoppingLocation.new") : LocalizedStringKey("str.md.shoppingLocation.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    if isNewShoppingLocation {
                        Button(LocalizedStringKey("str.cancel"), role: .cancel, action: finishForm)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveShoppingLocation, label: {
                        Label(LocalizedStringKey("str.md.shoppingLocation.save"), systemImage: MySymbols.save)
                            .labelStyle(.titleAndIcon)
                    })
                        .disabled(!isNameCorrect || isProcessing)
                        .keyboardShortcut(.defaultAction)
                }
            })
    }
    
    var content: some View {
        Form {
#if os(macOS)
            Text(isNewShoppingLocation ? LocalizedStringKey("str.md.shoppingLocation.new") : LocalizedStringKey("str.md.shoppingLocation.edit"))
                .font(.title)
                .bold()
                .padding(.bottom, 20.0)
#endif

            Section(header: Text(LocalizedStringKey("str.md.shoppingLocation.info"))){
                MyTextField(textToEdit: $name, description: "str.md.shoppingLocation.name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "str.md.shoppingLocation.name.required", errorMessage: "str.md.shoppingLocation.name.exists")
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
                MyTextField(textToEdit: $mdShoppingLocationDescription, description: "str.md.description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
            }
        }
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestData(objects: dataToUpdate)
                resetForm()
                firstAppear = false
            }
        })
    }
}

struct MDShoppingLocationFormView_Previews: PreviewProvider {
    static var previews: some View {
#if os(macOS)
        Group {
            MDShoppingLocationFormView(isNewShoppingLocation: true, showAddShoppingLocation: Binding.constant(true), toastType: Binding.constant(nil))
            MDShoppingLocationFormView(isNewShoppingLocation: false, shoppingLocation: MDShoppingLocation(id: 0, name: "Shoppingloc", mdShoppingLocationDescription: "Descr", rowCreatedTimestamp: ""), showAddShoppingLocation: Binding.constant(false), toastType: Binding.constant(nil))
        }
#else
        Group {
            NavigationView {
                MDShoppingLocationFormView(isNewShoppingLocation: true, showAddShoppingLocation: Binding.constant(true), toastType: Binding.constant(nil))
            }
            NavigationView {
                MDShoppingLocationFormView(isNewShoppingLocation: false, shoppingLocation: MDShoppingLocation(id: 0, name: "Shoppinglocation", mdShoppingLocationDescription: "Descr", rowCreatedTimestamp: ""), showAddShoppingLocation: Binding.constant(false), toastType: Binding.constant(nil))
            }
        }
#endif
    }
}
