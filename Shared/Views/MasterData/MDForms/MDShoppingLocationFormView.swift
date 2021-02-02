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
    
    @State private var name: String = ""
    @State private var mdShoppingLocationDescription: String = ""
    
    var isNewShoppingLocation: Bool
    var shoppingLocation: MDShoppingLocation?
    
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
        grocyVM.getMDShoppingLocations()
    }
    
    private func finishForm() {
        #if os(iOS)
        presentationMode.wrappedValue.dismiss()
        #elseif os(macOS)
        if isNewShoppingLocation {
            NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
        }
        #endif
    }
    
    private func saveShoppingLocation() {
        if isNewShoppingLocation {
            let shoppingLocationPOST = MDShoppingLocationPOST(id: grocyVM.findNextID(.shopping_locations), name: name, mdShoppingLocationDescription: mdShoppingLocationDescription, rowCreatedTimestamp: Date().iso8601withFractionalSeconds, userfields: nil)
            grocyVM.postMDObject(object: .shopping_locations, content: shoppingLocationPOST, completion: { result in
                switch result {
                case let .success(message):
                    print(message)
                    toastType = .successAdd
                    updateData()
                    finishForm()
                case let .failure(error):
                    print("\(error)")
                    toastType = .failAdd
                }
            })
        } else {
            let shoppingLocationPOST = MDShoppingLocationPOST(id: Int(shoppingLocation!.id)!, name: name, mdShoppingLocationDescription: mdShoppingLocationDescription, rowCreatedTimestamp: shoppingLocation!.rowCreatedTimestamp, userfields: nil)
            grocyVM.putMDObjectWithID(object: .shopping_locations, id: shoppingLocation!.id, content: shoppingLocationPOST, completion: { result in
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
        content
            .padding()
        #elseif os(iOS)
        content
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
                    }.disabled(!isNameCorrect)
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
                MyTextField(textToEdit: $mdShoppingLocationDescription, description: "str.md.description", isCorrect: Binding.constant(true), leadingIcon: "text.justifyleft", isEditing: true)
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
                .keyboardShortcut(.defaultAction)
            }
            #endif
        }
        .navigationTitle(isNewShoppingLocation ? LocalizedStringKey("str.md.shoppingLocation.new") : LocalizedStringKey("str.md.shoppingLocation.edit"))
        .animation(.default)
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestDataIfUnavailable(objects: [.shopping_locations])
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
            MDShoppingLocationFormView(isNewShoppingLocation: true, toastType: Binding.constant(nil))
            MDShoppingLocationFormView(isNewShoppingLocation: false, shoppingLocation: MDShoppingLocation(id: "0", name: "Shoppingloc", mdShoppingLocationDescription: "Descr", rowCreatedTimestamp: "", userfields: nil), toastType: Binding.constant(nil))
        }
        #else
        Group {
            NavigationView {
                MDShoppingLocationFormView(isNewShoppingLocation: true, toastType: Binding.constant(nil))
            }
            NavigationView {
                MDShoppingLocationFormView(isNewShoppingLocation: false, shoppingLocation: MDShoppingLocation(id: "0", name: "Shoppingloc", mdShoppingLocationDescription: "Descr", rowCreatedTimestamp: "", userfields: nil), toastType: Binding.constant(nil))
            }
        }
        #endif
    }
}
