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
    
    @State private var showDeleteAlert: Bool = false
    
    var isNewShoppingLocation: Bool
    var shoppingLocation: MDShoppingLocation?
    
    @State var isNameCorrect: Bool = true
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
    
    private func saveShoppingLocation() {
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
        #if os(macOS)
        content
            .padding()
        #elseif os(iOS)
        content
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    if isNewShoppingLocation {
                        Button("str.cancel") {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("str.md.save \("str.md.location".localized)") {
                        saveShoppingLocation()
                        presentationMode.wrappedValue.dismiss()
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
                    saveShoppingLocation()
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.defaultAction)
            }
            #endif
            if !isNewShoppingLocation {
                Button(action: {
                    showDeleteAlert.toggle()
                }, label: {
                    Label("str.md.delete \("str.md.shoppingLocation".localized)", systemImage: "trash")
                        .foregroundColor(.red)
                })
                .keyboardShortcut(.delete)
                .alert(isPresented: $showDeleteAlert) {
                    Alert(title: Text("str.md.shoppingLocation.delete.confirm"), message: Text(""), primaryButton: .destructive(Text("str.delete")) {
                        deleteShoppingLocation()
                        #if os(macOS)
                        NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                        #else
                        presentationMode.wrappedValue.dismiss()
                        #endif
                    }, secondaryButton: .cancel())
                }
            }
        }
        .navigationTitle(isNewShoppingLocation ? "str.md.shoppingLocation.new" : "str.md.shoppingLocation.edit")
        .animation(.default)
        .onAppear(perform: {
            resetForm()
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
