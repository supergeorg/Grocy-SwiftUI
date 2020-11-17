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
    
    @State private var name: String = ""
    @State private var mdShoppingLocationDescription: String = ""
    
    var isNewShoppingLocation: Bool
    var shoppingLocation: MDShoppingLocation?
    
    @State var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundShoppingLocation = grocyVM.mdShoppingLocations.first(where: {$0.name == name})
        return isNewShoppingLocation ? !(name.isEmpty || foundShoppingLocation != nil) : !(name.isEmpty || (foundShoppingLocation != nil && foundShoppingLocation!.id != shoppingLocation!.id))
    }
    
    private func resetForm() {
        if isNewShoppingLocation {
            self.name = ""
            self.mdShoppingLocationDescription = ""
        } else {
            self.name = shoppingLocation!.name
            self.mdShoppingLocationDescription = shoppingLocation!.mdShoppingLocationDescription ?? ""
        }
        isNameCorrect = checkNameCorrect()
    }
    
    private func saveLocation() {
        if isNewShoppingLocation {
            grocyVM.postMDObject(object: .shopping_locations, content: MDShoppingLocationPOST(id: grocyVM.findNextID(.shopping_locations), name: name, mdShoppingLocationDescription: mdShoppingLocationDescription, rowCreatedTimestamp: Date().iso8601withFractionalSeconds, userfields: nil))
        } else {
            grocyVM.putMDObjectWithID(object: .shopping_locations, id: shoppingLocation!.id, content: MDShoppingLocationPOST(id: Int(shoppingLocation!.id)!, name: name, mdShoppingLocationDescription: mdShoppingLocationDescription, rowCreatedTimestamp: shoppingLocation!.rowCreatedTimestamp, userfields: nil))
        }
        grocyVM.getMDShoppingLocations()
    }
    
    private func deleteShoppingLocation() {
        grocyVM.deleteMDObject(object: .shopping_locations, id: shoppingLocation!.id)
        grocyVM.getMDShoppingLocations()
    }
    
    var body: some View {
        Form {
            Section(header: Text("str.md.shoppingLocation.info")){
                MyTextField(textToEdit: $name, description: "str.md.shoppingLocation.name", isCorrect: $isNameCorrect, leadingIcon: "tag", isEditing: true, errorMessage: "str.md.shoppingLocation.name.required")
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
                MyTextField(textToEdit: $mdShoppingLocationDescription, description: "str.md.description", isCorrect: Binding.constant(true), leadingIcon: "text.justifyleft", isEditing: true)
            }
            #if os(macOS)
            HStack{
                Button("str.cancel") {
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("str.save") {
                    saveLocation()
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.defaultAction)
            }
            #endif
            if !isNewShoppingLocation {
                Button(action: {
                    deleteShoppingLocation()
                    #if os(macOS)
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                    #else
                    presentationMode.wrappedValue.dismiss()
                    #endif
                }, label: {
                    Label("str.md.delete \("str.md.shoppingLocation".localized)", systemImage: "trash")
                        .foregroundColor(.red)
                })
                .keyboardShortcut(.delete)
            }
        }
        .navigationTitle(isNewShoppingLocation ? "str.md.shoppingLocation.new" : "str.md.shoppingLocation.edit")
        .animation(.default)
        .onAppear(perform: {
            resetForm()
        })
        .toolbar(content: {
            #if os(iOS)
            ToolbarItem(placement: .cancellationAction) {
                if isNewLocation {
                    Button("str.cancel") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("str.md.save \("str.md.location".localized)") {
                    saveLocation()
                    presentationMode.wrappedValue.dismiss()
                }.disabled(!isNameCorrect)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                // Back not shown without it
                if !isNewLocation{
                    Text("")
                }
            }
            #endif
        })
    }
}

struct MDShoppingLocationFormView_Previews: PreviewProvider {
    static var previews: some View {
        #if os(macOS)
        Group {
            MDShoppingLocationFormView(isNewShoppingLocation: true)
            MDShoppingLocationFormView(isNewShoppingLocation: false, shoppingLocation: MDShoppingLocation(id: "0", name: "Shoppingloc", mdShoppingLocationDescription: "Descr", rowCreatedTimestamp: "", userfields: nil))
        }
        #else
        Group {
            NavigationView {
                MDShoppingLocationFormView(isNewShoppingLocation: true)
            }
            NavigationView {
                MDShoppingLocationFormView(isNewShoppingLocation: false, shoppingLocation: MDShoppingLocation(id: "0", name: "Shoppingloc", mdShoppingLocationDescription: "Descr", rowCreatedTimestamp: "", userfields: nil))
            }
        }
        #endif
    }
}
