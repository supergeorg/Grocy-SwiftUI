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
        self.location = existingLocation ?? MDLocation()
    }

    private let dataToUpdate: [ObjectEntities] = [.locations]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func finishForm() {
        dismiss()
    }

    private func saveLocation() async {
        if location.id == -1 {
            do {
                location.id = try grocyVM.findNextID(.locations)
            } catch {
                GrocyLogger.error("Failed to get next ID: \(error)")
                return
            }
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
            isSuccessful = false
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
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
                            if !isProcessing {
                                // Label style is left to the system, so the confirm button gets the standard Liquid Glass look.
                                Label("Save", systemImage: MySymbols.save)
                            } else {
                                ProgressView().progressViewStyle(.circular)
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

#Preview("Create", traits: .previewData) {
    NavigationStack {
        MDLocationFormView()
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        MDLocationFormView(existingLocation: MDLocation(name: "Location"))
    }
}
