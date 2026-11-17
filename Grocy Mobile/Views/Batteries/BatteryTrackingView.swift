//
//  BatteryTrackingView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import SwiftData
import SwiftUI

/// Grocy's "Battery tracking": records a charge cycle for a battery at a time up to now.
struct BatteryTrackingView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.dismiss) var dismiss

    @Query(filter: #Predicate<MDBattery> { $0.active }, sort: \MDBattery.name, order: .forward) var mdBatteries: MDBatteries
    @Query var batteries: Batteries

    @AppStorage("localizationKey") var localizationKey: String = "en"

    @State private var firstAppear: Bool = true
    @State private var isProcessingAction: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var mdBatteryID: Int? = nil
    var isPopup: Bool = false

    @State private var batteryID: Int?
    @State private var trackedTime: Date = Date()

    private let dataToUpdate: [ObjectEntities] = [.batteries]
    private let additionalDataToUpdate: [AdditionalEntities] = [.batteries]

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    private var isFormValid: Bool {
        batteryID != nil && trackedTime <= Date()
    }

    private var selectedBattery: Battery? {
        batteries.first(where: { $0.batteryID == batteryID })
    }

    private func resetForm() {
        batteryID = mdBatteryID
        trackedTime = Date()
    }

    private func trackChargeCycle() async {
        guard let batteryID else { return }
        isProcessingAction = true
        isSuccessful = nil
        do {
            try await grocyVM.chargeBattery(id: batteryID, content: BatteryChargeModel(trackedTime: trackedTime.grocyDateTimeString))
            GrocyLogger.info("Tracking charge cycle was successful.")
            await grocyVM.requestData(objects: [.battery_charge_cycles], additionalObjects: [.batteries])
            isSuccessful = true
            if isPopup {
                dismiss()
            } else {
                // Stays open for the next battery, like the chore tracking screen.
                self.batteryID = nil
                trackedTime = Date()
            }
        } catch {
            GrocyLogger.error("Tracking charge cycle failed. \(error)")
            isSuccessful = false
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isProcessingAction = false
    }

    var body: some View {
        Form {
            if isSuccessful == false, let errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                Section {
                    ServerProblemView(isCompact: true)
                }
            }

            Section {
                Picker(selection: $batteryID) {
                    Text("")
                        .tag(nil as Int?)
                    ForEach(mdBatteries) { battery in
                        Text(battery.name)
                            .tag(battery.id as Int?)
                    }
                } label: {
                    Label("Battery", systemImage: MySymbols.batteries)
                        .foregroundStyle(.primary)
                }

                LabeledContent {
                    // A charge cycle can only be tracked up to now, as in Grocy.
                    DatePicker(selection: $trackedTime, in: ...Date()) {
                        Text(getRelativeDateAsText(trackedTime, localizationKey: localizationKey) ?? "")
                            .font(.caption)
                            .italic()
                    }
                } label: {
                    Label("Tracked time", systemImage: MySymbols.date)
                        .foregroundStyle(.primary)
                }
            }

            // Like the battery card next to the form in Grocy.
            if let selectedBattery {
                Section("Battery overview") {
                    if !selectedBattery.usedIn.isEmpty {
                        LabeledContent("Used in", value: selectedBattery.usedIn)
                    }
                    LabeledContent("Last charged") {
                        if let lastTrackedTime = selectedBattery.lastTrackedTime {
                            Text(formatDateAsString(lastTrackedTime, showTime: true, localizationKey: localizationKey) ?? "")
                        } else {
                            Text("Never")
                        }
                    }
                    if let next = selectedBattery.nextEstimatedChargeTime {
                        LabeledContent("Next planned charge cycle") {
                            Text(formatDateAsString(next, showTime: false, localizationKey: localizationKey) ?? "")
                        }
                    }
                }
            }
        }
        .navigationTitle("Battery tracking")
        .formStyle(.grouped)
        .task {
            if firstAppear {
                await updateData()
                resetForm()
                firstAppear = false
            }
        }
        .toolbar {
            if isPopup {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) {
                    Task {
                        await trackChargeCycle()
                    }
                } label: {
                    // While it runs, the icon becomes an animated progress symbol. It stays an image: with a ProgressView as its icon,
                    // the item loses its icon and leaves iPhone Duo's vertical bar for a text-only button at the bottom.
                    Label("Track charge cycle", systemImage: isProcessingAction ? MySymbols.progress : MySymbols.batteryCharge)
                        .symbolEffect(.variableColor.iterative, isActive: isProcessingAction)
                }
                .disabled(!isFormValid || isProcessingAction)
                .keyboardShortcut(.defaultAction)
            }
        }
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        BatteryTrackingView()
    }
}

#Preview("Preselected", traits: .previewData) {
    NavigationStack {
        BatteryTrackingView(mdBatteryID: 1, isPopup: true)
    }
}
