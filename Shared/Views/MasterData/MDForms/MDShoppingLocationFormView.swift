//
//  MDShoppingLocationFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDShoppingLocationFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var name: String = ""
    @State private var mdShoppingLocationDescription: String = ""
    
    var isNewShoppingLocation: Bool
    var shoppingLocation: MDShoppingLocation?
    
    @Binding var showAddShoppingLocation: Bool
    @Binding var toastType: MDToastType?
    
    @State var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundShoppingLocation = grocyVM.mdShoppingLocations.first(where: {$0.name == name})
        return isNewShoppingLocation ? !(name.isEmpty || foundShoppingLocation != nil) : !(name.isEmpty || (foundShoppingLocation != nil && foundShoppingLocation!.id != shoppingLocation!.id))
    }
    
    private func resetForm() {
        self.name = shoppingLocation?.name ?? ""
        self.mdShoppingLocationDescription = shoppingLocation?.mdShoppingLocationDescription ?? ""
        isNameCorrect = checkNameCorrect()
    }
    
    private func updateData() {
        grocyVM.requestData(objects: [.shopping_locations])
    }
    
    private func finishForm() {
        #if os(iOS)
        presentationMode.wrappedValue.dismiss()
        #elseif os(macOS)
        if isNewShoppingLocation {
            showAddShoppingLocation = false
        }
        #endif
    }
    
    private func saveShoppingLocation() {
        let id = isNewShoppingLocation ? String(grocyVM.findNextID(.shopping_locations)) : shoppingLocation!.id
        let timeStamp = isNewShoppingLocation ? Date().iso8601withFractionalSeconds : shoppingLocation!.rowCreatedTimestamp
        let shoppingLocationPOST = MDShoppingLocation(id: id, name: name, mdShoppingLocationDescription: mdShoppingLocationDescription, rowCreatedTimestamp: timeStamp, userfields: nil)
        isProcessing = true
        if isNewShoppingLocation {
            grocyVM.postMDObject(object: .shopping_locations, content: shoppingLocationPOST, completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog(message: "Shopping location add successful. \(message)", type: .info)
                    toastType = .successAdd
                    updateData()
                    finishForm()
                case let .failure(error):
                    grocyVM.postLog(message: "Shopping location add failed. \(error)", type: .error)
                    toastType = .failAdd
                }
                isProcessing = false
            })
        } else {
            grocyVM.putMDObjectWithID(object: .shopping_locations, id: id, content: shoppingLocationPOST, completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog(message: "Shopping location edit successful. \(message)", type: .info)
                    toastType = .successEdit
                    updateData()
                    finishForm()
                case let .failure(error):
                    grocyVM.postLog(message: "Shopping location add failed. \(error)", type: .error)
                    toastType = .failEdit
                }
                isProcessing = false
            })
        }
        
    }
    
    var body: some View {
        #if os(macOS)
        ScrollView {
            content
                .padding()
        }
        .toolbar(content: {
            ToolbarItem(placement: .cancellationAction) {
                if !isNewShoppingLocation {
                    Button(LocalizedStringKey("str.cancel")) {
                        finishForm()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                if !isNewShoppingLocation {
                    Button(LocalizedStringKey("str.md.shoppingLocation.save")) {
                        saveShoppingLocation()
                    }
                    .disabled(!isNameCorrect || isProcessing)
                }
            }
        })
        #elseif os(iOS)
        content
            .navigationTitle(isNewShoppingLocation ? LocalizedStringKey("str.md.shoppingLocation.new") : LocalizedStringKey("str.md.shoppingLocation.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    if isNewShoppingLocation {
                        Button(LocalizedStringKey("str.cancel")) {
                            finishForm()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("str.md.shoppingLocation.save")) {
                        saveShoppingLocation()
                    }
                    .disabled(!isNameCorrect || isProcessing)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    // Back not shown without it
                    if !isNewShoppingLocation{
                        Text("")
                    }
                }
            })
        #endif
    }
    
    var content: some View {
        Form {
            Section(header: Text(LocalizedStringKey("str.md.shoppingLocation.info"))){
                MyTextField(textToEdit: $name, description: "str.md.shoppingLocation.name", isCorrect: $isNameCorrect, leadingIcon: "tag", isEditing: true, emptyMessage: "str.md.shoppingLocation.name.required", errorMessage: "str.md.shoppingLocation.name.exists")
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
                MyTextField(textToEdit: $mdShoppingLocationDescription, description: "str.md.description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description, isEditing: true)
            }
            #if os(macOS)
            HStack{
                Button(LocalizedStringKey("str.cancel")) {
                    if isNewShoppingLocation{
                        finishForm()
                    } else {
                        resetForm()
                    }
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button(LocalizedStringKey("str.save")) {
                    saveShoppingLocation()
                }
                .disabled(!isNameCorrect || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
            #endif
        }
        .animation(.default)
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestData(objects: [.shopping_locations], ignoreCached: false)
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
            MDShoppingLocationFormView(isNewShoppingLocation: false, shoppingLocation: MDShoppingLocation(id: "0", name: "Shoppingloc", mdShoppingLocationDescription: "Descr", rowCreatedTimestamp: "", userfields: nil), showAddShoppingLocation: Binding.constant(false), toastType: Binding.constant(nil))
        }
        #else
        Group {
            NavigationView {
                MDShoppingLocationFormView(isNewShoppingLocation: true, showAddShoppingLocation: Binding.constant(true), toastType: Binding.constant(nil))
            }
            NavigationView {
                MDShoppingLocationFormView(isNewShoppingLocation: false, shoppingLocation: MDShoppingLocation(id: "0", name: "Shoppingloc", mdShoppingLocationDescription: "Descr", rowCreatedTimestamp: "", userfields: nil), showAddShoppingLocation: Binding.constant(false), toastType: Binding.constant(nil))
            }
        }
        #endif
    }
}
