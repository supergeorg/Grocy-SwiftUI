//
//  MDLocationFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 16.11.20.
//

import SwiftUI

struct MDLocationFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var name: String = ""
    @State private var isActive: Bool = true
    @State private var mdLocationDescription: String = ""
    @State private var isFreezer: Bool = false
    
    var location: MDLocation? = nil
    
    @Binding var showAddLocation: Bool
    
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
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Location add failed. \(error)", type: .error)
            }
        } else {
            do {
                try await grocyVM.putMDObjectWithID(object: .locations, id: id, content: locationPOST)
                grocyVM.postLog("Location edit successful.", type: .info)
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Location edit failed. \(error)", type: .error)
            }
        }
        isProcessing = false
    }
    
    var body: some View {
        Form {
            MyTextField(textToEdit: $name, description: "Name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "A name is required", errorMessage: "Name already exists")
                .onChange(of: name) {
                    isNameCorrect = checkNameCorrect()
                }
            MyToggle(isOn: $isActive, description: "Active")
            MyTextEditor(textToEdit: $mdLocationDescription, description: "Description", leadingIcon: MySymbols.description)
            MyToggle(
                isOn: $isFreezer,
                description: "Is freezer",
                descriptionInfo: "When moving product from/to a freezer location, the products due date is automatically adjusted according to the product settings",
                icon: MySymbols.freezing
            )
        }
        .task {
            if firstAppear {
                await updateData()
                resetForm()
                firstAppear = false
            }
        }
        .navigationTitle(location == nil ? "Create location" : "Edit location")
        .toolbar(content: {
#if os(iOS)
            if location == nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel, action: finishForm)
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
                    Label("Save", systemImage: MySymbols.save)
                        .labelStyle(.titleAndIcon)
                })
                .disabled(!isNameCorrect || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        })
    }
}
