//
//  MDLocationFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 16.11.20.
//

import SwiftData
import SwiftUI

struct MDLocationFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query(sort: \MDLocation.id, order: .forward) var mdLocations: MDLocations

    @Environment(\.dismiss) var dismiss

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var existingLocation: MDLocation?
    @State var location: MDLocation

    @State private var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundLocation = mdLocations.first(where: { $0.name == location.name })
        return !(location.name.isEmpty || (foundLocation != nil && foundLocation!.id != location.id))
    }

    init(existingLocation: MDLocation? = nil) {
        self.existingLocation = existingLocation
        let initialLocation =
            existingLocation
            ?? MDLocation(
                id: 0,
                name: "",
                active: true,
                mdLocationDescription: "",
                isFreezer: false,
                rowCreatedTimestamp: Date().iso8601withFractionalSeconds
            )
        _location = State(initialValue: initialLocation)
        _isNameCorrect = State(initialValue: true)
    }

    private let dataToUpdate: [ObjectEntities] = [.locations]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func finishForm() {
        dismiss()
    }

    private func saveLocation() async {
        if location.id == 0 {
            location.id = grocyVM.findNextID(.locations)
        }
        isProcessing = true
        isSuccessful = nil
        do {
            try location.modelContext?.save()
            if existingLocation == nil {
                _ = try await grocyVM.postMDObject(object: .locations, content: location)
            } else {
                try await grocyVM.putMDObjectWithID(object: .locations, id: location.id, content: location)
            }
            GrocyLogger.info("Location \(location.name) successful.")
            await updateData()
            isSuccessful = true
        } catch {
            GrocyLogger.error("Location \(location.name) failed. \(error)")
            errorMessage = error.localizedDescription
            isSuccessful = false
        }
        isProcessing = false
    }

    var body: some View {
        Form {
            if isSuccessful == false, let errorMessage = errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            MyTextField(
                textToEdit: $location.name,
                description: "Name",
                prompt: "Required",
                isCorrect: $isNameCorrect,
                leadingIcon: MySymbols.name,
                emptyMessage: "A name is required",
                errorMessage: "Name already exists"
            )
            .onChange(of: location.name) {
                isNameCorrect = checkNameCorrect()
            }
            MyToggle(isOn: $location.active, description: "Active", icon: MySymbols.active)
            MyTextEditor(textToEdit: $location.mdLocationDescription, description: "Description", leadingIcon: MySymbols.description)
            MyToggle(
                isOn: $location.isFreezer,
                description: "Is freezer",
                descriptionInfo: "When moving product from/to a freezer location, the products due date is automatically adjusted according to the product settings",
                icon: MySymbols.freezing
            )
        }
        .formStyle(.grouped)
        .task {
            await updateData()
            self.isNameCorrect = checkNameCorrect()
        }
        .navigationTitle(existingLocation == nil ? "Create location" : "Edit location")
        .toolbar(content: {
            if existingLocation == nil {
                ToolbarItem(
                    placement: .cancellationAction,
                    content: {
                        Button(
                            role: .cancel,
                            action: {
                                finishForm()
                            }
                        )
                        .keyboardShortcut(.cancelAction)
                    }
                )
            }
            ToolbarItem(
                placement: .confirmationAction,
                content: {
                    Button(
                        role: .confirm,
                        action: {
                            Task {
                                await saveLocation()
                            }
                        },
                        label: {
                            if isProcessing == false {
                                Image(systemName: MySymbols.save)
                            } else {
                                ProgressView()
                            }
                        }
                    )
                    .disabled(!isNameCorrect || isProcessing)
                    .keyboardShortcut(.defaultAction)
                }
            )
        })
        .onChange(of: isSuccessful) {
            if isSuccessful == true {
                finishForm()
            }
        }
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }
}
