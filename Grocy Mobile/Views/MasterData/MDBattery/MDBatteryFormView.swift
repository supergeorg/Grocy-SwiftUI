//
//  MDBatteryFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import SwiftData
import SwiftUI

struct MDBatteryFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.dismiss) var dismiss

    @Query(sort: \MDBattery.id, order: .forward) var mdBatteries: MDBatteries

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var existingBattery: MDBattery?
    var isPopup: Bool = false
    @State private var battery: MDBattery

    @State private var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundBattery = mdBatteries.first(where: { $0.name == battery.name })
        return !(battery.name.isEmpty || (foundBattery != nil && foundBattery!.id != battery.id))
    }

    init(existingBattery: MDBattery? = nil, isPopup: Bool = false) {
        self.existingBattery = existingBattery
        self.isPopup = isPopup
        // Edited on a copy, so cancelling doesn't change the cached battery.
        self.battery = existingBattery.map {
            MDBattery(
                id: $0.id,
                name: $0.name,
                mdBatteryDescription: $0.mdBatteryDescription,
                usedIn: $0.usedIn,
                chargeIntervalDays: $0.chargeIntervalDays,
                active: $0.active,
                rowCreatedTimestamp: $0.rowCreatedTimestamp
            )
        } ?? MDBattery()
    }

    private let dataToUpdate: [ObjectEntities] = [.batteries]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: [.batteries])
    }

    private func finishForm() {
        dismiss()
    }

    private func saveBattery() async {
        if battery.id == -1 {
            do {
                battery.id = try grocyVM.findNextID(.batteries)
            } catch {
                GrocyLogger.error("Failed to get next ID: \(error)")
                return
            }
        }
        isProcessing = true
        isSuccessful = nil
        do {
            if existingBattery == nil {
                _ = try await grocyVM.postMDObject(object: .batteries, content: battery)
            } else {
                try await grocyVM.putMDObjectWithID(object: .batteries, id: battery.id, content: battery)
            }
            GrocyLogger.info("Battery \(battery.name) successful.")
            await updateData()
            isSuccessful = true
        } catch {
            GrocyLogger.error("Battery \(battery.name) failed. \(error)")
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
            if isSuccessful == false, let errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            MyTextField(
                textToEdit: $battery.name,
                description: "Name",
                prompt: "Required",
                isCorrect: $isNameCorrect,
                leadingIcon: MySymbols.name,
                emptyMessage: "A name is required",
                errorMessage: "Name already exists"
            )
            .onChange(of: battery.name) {
                isNameCorrect = checkNameCorrect()
            }
            MyToggle(isOn: $battery.active, description: "Active", icon: MySymbols.active)
            MyTextEditor(textToEdit: $battery.mdBatteryDescription, description: "Description", leadingIcon: MySymbols.description)
            MyTextField(
                textToEdit: $battery.usedIn,
                description: "Used in",
                isCorrect: Binding.constant(true),
                leadingIcon: MySymbols.batteryUsedIn
            )
            MyIntStepper(
                amount: $battery.chargeIntervalDays,
                description: "Charge cycle interval",
                helpText: "0 means suggestions for the next charge cycle are disabled",
                minAmount: 0,
                amountName: "days",
                systemImage: MySymbols.batteryChargeInterval
            )
        }
        .formStyle(.grouped)
        .task {
            await updateData()
            self.isNameCorrect = checkNameCorrect()
        }
        .navigationTitle(existingBattery == nil ? "Create battery" : "Edit battery")
        .toolbar {
            if existingBattery == nil || isPopup {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        finishForm()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) {
                    Task {
                        await saveBattery()
                    }
                } label: {
                    // While it runs, the icon becomes an animated progress symbol. It stays an image: with a ProgressView as its icon,
                    // the item loses its icon and leaves iPhone Duo's vertical bar for a text-only button at the bottom.
                    Label("Save", systemImage: isProcessing ? MySymbols.progress : MySymbols.save)
                        .symbolEffect(.variableColor.iterative, isActive: isProcessing)
                }
                .disabled(!isNameCorrect || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        }
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
        MDBatteryFormView()
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        MDBatteryFormView(existingBattery: MDBattery(name: "Battery", usedIn: "TV remote control", chargeIntervalDays: 180))
    }
}
