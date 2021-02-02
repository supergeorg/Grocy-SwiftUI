//
//  MDLocationFormView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 16.11.20.
//

import SwiftUI

struct MDLocationFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstAppear: Bool = true
    
    @State private var name: String = ""
    @State private var mdLocationDescription: String = ""
    @State private var isFreezer: Bool = false
    
    @State private var showFreezerInfo: Bool = false
    
    var isNewLocation: Bool
    var location: MDLocation?
    
    @Binding var toastType: MDToastType?
    
    @State var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundLocation = grocyVM.mdLocations.first(where: {$0.name == name})
        return isNewLocation ? !(name.isEmpty || foundLocation != nil) : !(name.isEmpty || (foundLocation != nil && foundLocation!.id != location!.id))
    }
    
    private func resetForm() {
        self.name = location?.name ?? ""
        self.mdLocationDescription = location?.mdLocationDescription ?? ""
        self.isFreezer = Bool(location?.isFreezer ?? "0") ?? false
        isNameCorrect = checkNameCorrect()
    }
    
    private func updateData() {
        grocyVM.getMDLocations()
    }
    
    private func finishForm() {
        #if os(iOS)
        presentationMode.wrappedValue.dismiss()
        #elseif os(macOS)
        if isNewLocation {
            NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
        }
        #endif
    }
    
    private func saveLocation() {
        if isNewLocation {
            let locationPOST = MDLocationPOST(id: grocyVM.findNextID(.locations), name: name, mdLocationDescription: mdLocationDescription, rowCreatedTimestamp: Date().iso8601withFractionalSeconds, isFreezer: String(isFreezer), userfields: nil)
            grocyVM.postMDObject(object: .locations, content: locationPOST, completion: { result in
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
            let locationPOST = MDLocationPOST(id: Int(location!.id)!, name: name, mdLocationDescription: mdLocationDescription, rowCreatedTimestamp: location!.rowCreatedTimestamp, isFreezer: String(isFreezer), userfields: nil)
            grocyVM.putMDObjectWithID(object: .locations, id: location!.id, content: locationPOST, completion: { result in
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
    
    private func deleteLocation() {
        grocyVM.deleteMDObject(object: .locations, id: location!.id)
        grocyVM.getMDLocations()
    }
    
    var body: some View {
        Form {
            Section(header: Text(LocalizedStringKey("str.md.location.info"))){
                MyTextField(textToEdit: $name, description: "str.md.location.name", isCorrect: $isNameCorrect, leadingIcon: "tag", isEditing: true, emptyMessage: "str.md.location.name.required", errorMessage: "str.md.location.name.exists")
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
                MyTextField(textToEdit: $mdLocationDescription, description: "str.md.description", isCorrect: Binding.constant(true), leadingIcon: "text.justifyleft", isEditing: true)
            }
            Section(header: Text(LocalizedStringKey("str.md.location.freezer"))){
                MyToggle(isOn: $isFreezer, description: "str.md.location.isFreezing", descriptionInfo: "str.md.location.isFreezing.description", icon: "thermometer.snowflake")
            }
            #if os(macOS)
            HStack{
                Button(LocalizedStringKey("str.cancel")) {
                    if isNewLocation{
                        finishForm()
                    } else {
                        resetForm()
                    }
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button(LocalizedStringKey("str.save")) {
                    saveLocation()
                }
                .keyboardShortcut(.defaultAction)
            }
            #endif
        }
        .navigationTitle(isNewLocation ? LocalizedStringKey("str.md.location.new") : LocalizedStringKey("str.md.location.edit"))
        .animation(.default)
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestDataIfUnavailable(objects: [.locations])
                resetForm()
                firstAppear = false
            }
        })
        .toolbar(content: {
            #if os(iOS)
            ToolbarItem(placement: .cancellationAction) {
                if isNewLocation {
                    Button(LocalizedStringKey("str.cancel")) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedStringKey("str.md.location.save")) {
                    saveLocation()
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

struct MDLocationFormView_Previews: PreviewProvider {
    static var previews: some View {
        #if os(macOS)
        Group {
            MDLocationFormView(isNewLocation: true, toastType: Binding.constant(.successAdd))
            MDLocationFormView(isNewLocation: false, location: MDLocation(id: "1", name: "Loc", mdLocationDescription: "descr", rowCreatedTimestamp: "", isFreezer: "1", userfields: nil), toastType: Binding.constant(.successAdd))
        }
        #else
        Group {
            NavigationView {
                MDLocationFormView(isNewLocation: true, toastType: Binding.constant(.successAdd))
            }
            NavigationView {
                MDLocationFormView(isNewLocation: false, location: MDLocation(id: "1", name: "Loc", mdLocationDescription: "descr", rowCreatedTimestamp: "", isFreezer: "1", userfields: nil), toastType: Binding.constant(.successAdd))
            }
        }
        #endif
    }
}
