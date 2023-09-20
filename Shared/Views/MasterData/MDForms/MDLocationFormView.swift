//
//  MDLocationFormView.swift
//  Grocy Mobile
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
    @State private var isActive: Bool = true
    @State private var mdLocationDescription: String = ""
    @State private var isFreezer: Bool = false
    
    var location: MDLocation? = nil
    
    @Binding var showAddLocation: Bool
    @State var toastType: ToastType? = nil
    
    @State private var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundLocation = grocyVM.mdLocations.first(where: {$0.name == name})
        return location == nil ? !(name.isEmpty || foundLocation != nil) : !(name.isEmpty || (foundLocation != nil && foundLocation!.id != location!.id))
    }
    
    private func resetForm() {
        self.name = location?.name ?? ""
        self.isActive = location?.active ?? true
        self.mdLocationDescription = location?.mdLocationDescription ?? ""
        self.isFreezer = location?.isFreezer ?? false
        isNameCorrect = checkNameCorrect()
    }
    
    private let dataToUpdate: [ObjectEntities] = [.locations]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private func finishForm() {
#if os(iOS)
        self.dismiss()
#elseif os(macOS)
        if location == nil {
            showAddLocation = false
        }
#endif
    }
    
    private func saveLocation() async {
        let id = location == nil ? grocyVM.findNextID(.locations) : location!.id
        let timeStamp = location == nil ? Date().iso8601withFractionalSeconds : location!.rowCreatedTimestamp
        let locationPOST = MDLocation(
            id: id,
            name: name,
            active: isActive,
            mdLocationDescription: mdLocationDescription,
            isFreezer: isFreezer,
            rowCreatedTimestamp: timeStamp
        )
        isProcessing = true
        if location == nil {
            do {
                _ = try await grocyVM.postMDObject(object: .locations, content: locationPOST)
                grocyVM.postLog("Location added successfully.", type: .info)
                toastType = .successAdd
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Location add failed. \(error)", type: .error)
                toastType = .failAdd
            }
        } else {
            do {
                try await grocyVM.putMDObjectWithID(object: .locations, id: id, content: locationPOST)
                grocyVM.postLog("Location edit successful.", type: .info)
                toastType = .successEdit
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Location edit failed. \(error)", type: .error)
                toastType = .failEdit
            }
        }
        isProcessing = false
    }
    
    var body: some View {
        Form {
            Section("str.md.location.info") {
                MyTextField(textToEdit: $name, description: "str.md.location.name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "str.md.location.name.required", errorMessage: "str.md.location.name.exists")
                    .onChange(of: name) {
                        isNameCorrect = checkNameCorrect()
                    }
                MyToggle(isOn: $isActive, description: "str.md.product.active")
                MyTextEditor(textToEdit: $mdLocationDescription, description: "str.md.description", leadingIcon: MySymbols.description)
            }
            
            Section("str.md.location.freezer") {
                MyToggle(isOn: $isFreezer, description: "str.md.location.isFreezing", descriptionInfo: "str.md.location.isFreezing.description", icon: "thermometer.snowflake")
            }
        }
        .task {
            if firstAppear {
                await updateData()
                resetForm()
                firstAppear = false
            }
        }
        .navigationTitle(location == nil ? LocalizedStringKey("str.md.location.new") : LocalizedStringKey("str.md.location.edit"))
        .toolbar(content: {
#if os(iOS)
            if location == nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("str.cancel"), role: .cancel, action: finishForm)
                        .keyboardShortcut(.cancelAction)
                }
            }
#endif
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    Task {
                        await saveLocation()
                    }
                }, label: {
                    Label("str.md.location.save", systemImage: MySymbols.save)
                        .labelStyle(.titleAndIcon)
                })
                .disabled(!isNameCorrect || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        })
    }
}

//struct MDLocationFormView_Previews: PreviewProvider {
//    static var previews: some View {
//#if os(macOS)
//        Group {
//            MDLocationFormView(isNewLocation: true, showAddLocation: Binding.constant(true))
//            MDLocationFormView(isNewLocation: false, location: MDLocation(id: 1, name: "Loc", active: true, mdLocationDescription: "descr", isFreezer: true, rowCreatedTimestamp: ""), showAddLocation: Binding.constant(false))
//        }
//#else
//        Group {
//            NavigationView {
//                MDLocationFormView(isNewLocation: true, showAddLocation: Binding.constant(true))
//            }
//            NavigationView {
//                MDLocationFormView(isNewLocation: false, location: MDLocation(id: 1, name: "Location", active: true, mdLocationDescription: "Location Description", isFreezer: true, rowCreatedTimestamp: ""), showAddLocation: Binding.constant(false))
//            }
//        }
//#endif
//    }
//}
