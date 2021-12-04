//
//  MDLocationFormView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 16.11.20.
//

import SwiftUI

struct MDLocationFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var name: String = ""
    @State private var mdLocationDescription: String = ""
    @State private var isFreezer: Bool = false
    
    var isNewLocation: Bool
    var location: MDLocation?
    
    @Binding var showAddLocation: Bool
    @Binding var toastType: MDToastType?
    
    @State private var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundLocation = grocyVM.mdLocations.first(where: {$0.name == name})
        return isNewLocation ? !(name.isEmpty || foundLocation != nil) : !(name.isEmpty || (foundLocation != nil && foundLocation!.id != location!.id))
    }
    
    private func resetForm() {
        self.name = location?.name ?? ""
        self.mdLocationDescription = location?.mdLocationDescription ?? ""
        self.isFreezer = location?.isFreezer ?? false
        isNameCorrect = checkNameCorrect()
    }
    
    private let dataToUpdate: [ObjectEntities] = [.locations]
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate)
    }
    
    private func finishForm() {
#if os(iOS)
        self.dismiss()
#elseif os(macOS)
        if isNewLocation {
            showAddLocation = false
        }
#endif
    }
    
    private func saveLocation() {
        let id = isNewLocation ? grocyVM.findNextID(.locations) : location!.id
        let timeStamp = isNewLocation ? Date().iso8601withFractionalSeconds : location!.rowCreatedTimestamp
        let locationPOST = MDLocation(id: id, name: name, mdLocationDescription: mdLocationDescription, rowCreatedTimestamp: timeStamp, isFreezer: isFreezer)
        isProcessing = true
        if isNewLocation {
            grocyVM.postMDObject(object: .locations, content: locationPOST, completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog("Location add successful. \(message)", type: .info)
                    toastType = .successAdd
                    updateData()
                    finishForm()
                case let .failure(error):
                    grocyVM.postLog("Location add failed. \(error)", type: .error)
                    toastType = .failAdd
                }
                isProcessing = false
            })
        } else {
            grocyVM.putMDObjectWithID(object: .locations, id: id, content: locationPOST, completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog("Location edit successful. \(message)", type: .info)
                    toastType = .successEdit
                    updateData()
                    finishForm()
                case let .failure(error):
                    grocyVM.postLog("Location edit failed. \(error)", type: .error)
                    toastType = .failEdit
                }
                isProcessing = false
            })
        }
    }
    
    var body: some View {
        content
            .navigationTitle(isNewLocation ? LocalizedStringKey("str.md.location.new") : LocalizedStringKey("str.md.location.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    if isNewLocation {
                        Button(LocalizedStringKey("str.cancel"), role: .cancel, action: finishForm)
                            .keyboardShortcut(.cancelAction)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("str.md.location.save"), action: saveLocation)
                        .disabled(!isNameCorrect || isProcessing)
                }
            })
    }
    
    var content: some View {
        Form {
            Section(header: Text(LocalizedStringKey("str.md.location.info"))){
                MyTextField(textToEdit: $name, description: "str.md.location.name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "str.md.location.name.required", errorMessage: "str.md.location.name.exists")
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
                MyTextField(textToEdit: $mdLocationDescription, description: "str.md.description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
            }
            Section(header: Text(LocalizedStringKey("str.md.location.freezer"))){
                MyToggle(isOn: $isFreezer, description: "str.md.location.isFreezing", descriptionInfo: "str.md.location.isFreezing.description", icon: "thermometer.snowflake")
            }
#if os(macOS)
            HStack{
                Button(LocalizedStringKey("str.cancel"), action: isNewLocation ? finishForm : resetForm)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(LocalizedStringKey("str.save"), action: saveLocation)
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

struct MDLocationFormView_Previews: PreviewProvider {
    static var previews: some View {
#if os(macOS)
        //        Group {
        //            MDLocationFormView(isNewLocation: true, showAddLocation: Binding.constant(true), toastType: Binding.constant(.successAdd))
        //            MDLocationFormView(isNewLocation: false, location: MDLocation(id: "1", name: "Loc", mdLocationDescription: "descr", rowCreatedTimestamp: "", isFreezer: "1", userfields: nil), showAddLocation: Binding.constant(false), toastType: Binding.constant(.successAdd))
        //        }
#else
        Group {
            NavigationView {
                MDLocationFormView(isNewLocation: true, showAddLocation: Binding.constant(true), toastType: Binding.constant(.successAdd))
            }
            NavigationView {
                MDLocationFormView(isNewLocation: false, location: MDLocation(id: 1, name: "Location", mdLocationDescription: "Location Description", rowCreatedTimestamp: "", isFreezer: true), showAddLocation: Binding.constant(false), toastType: Binding.constant(.successAdd))
            }
        }
#endif
    }
}
