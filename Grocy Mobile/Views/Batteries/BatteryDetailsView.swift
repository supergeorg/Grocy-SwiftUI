//
//  BatteryDetailsView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import SwiftData
import SwiftUI

/// Grocy's battery card: charge cycles count, last charged and next planned charge cycle.
struct BatteryDetailsView: View {
    var batteryID: Int
    var isPopup: Bool = false

    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.dismiss) var dismiss
    @Environment(BatteryInteractionNavigationRouter.self) private var batteryInteractionRouter: BatteryInteractionNavigationRouter?

    @AppStorage("localizationKey") var localizationKey: String = "en"

    @Query private var mdBatteriesArray: MDBatteries
    private var mdBattery: MDBattery? {
        mdBatteriesArray.first
    }

    @State private var batteryDetails: BatteryDetails?
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    init(batteryID: Int, isPopup: Bool = false) {
        self.batteryID = batteryID
        self.isPopup = isPopup
        _mdBatteriesArray = Query(filter: #Predicate<MDBattery> { $0.id == batteryID })
    }

    private func updateData() async {
        await grocyVM.requestData(objects: [.batteries])
        do {
            batteryDetails = try await grocyVM.getBatteryDetails(id: batteryID)
            errorMessage = nil
        } catch {
            GrocyLogger.error("Getting battery details failed. \(error)")
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    private func dateContent(_ date: Date?) -> some View {
        VStack(alignment: .trailing) {
            if let date {
                // Date and time here; the overview rows only show the date.
                Text(formatDateAsString(date, showTime: true, localizationKey: localizationKey) ?? "")
                Text(getRelativeDateAsText(date, localizationKey: localizationKey) ?? "")
                    .font(.caption)
                    .italic()
            } else {
                Text("Never")
            }
        }
    }

    var body: some View {
        Form {
            if let errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            if let mdBattery {
                Section {
                    LabeledContent {
                        Text(mdBattery.name)
                    } label: {
                        Label("Name", systemImage: MySymbols.name)
                            .foregroundStyle(.primary)
                    }
                    if !mdBattery.usedIn.isEmpty {
                        LabeledContent {
                            Text(mdBattery.usedIn)
                        } label: {
                            Label("Used in", systemImage: MySymbols.batteryUsedIn)
                                .foregroundStyle(.primary)
                        }
                    }
                    if !mdBattery.mdBatteryDescription.isEmpty {
                        LabeledContent {
                            Text(mdBattery.mdBatteryDescription)
                        } label: {
                            Label("Description", systemImage: MySymbols.description)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            if let batteryDetails {
                Section {
                    LabeledContent {
                        Text("\(batteryDetails.chargeCyclesCount)")
                    } label: {
                        Label("Charge cycles count", systemImage: MySymbols.amount)
                            .foregroundStyle(.primary)
                    }
                    LabeledContent {
                        dateContent(batteryDetails.lastCharged)
                    } label: {
                        Label("Last charged", systemImage: MySymbols.date)
                            .foregroundStyle(.primary)
                    }
                    if let mdBattery, mdBattery.chargeIntervalDays > 0 {
                        LabeledContent {
                            dateContent(batteryDetails.nextEstimatedChargeTime)
                        } label: {
                            Label("Next planned charge cycle", systemImage: MySymbols.batteryChargeInterval)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Battery overview")
        .task {
            await updateData()
        }
        .refreshable {
            await updateData()
        }
        .toolbar {
            if isPopup {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            if let batteryInteractionRouter {
                ToolbarItemGroup(placement: .automatic) {
                    Button {
                        batteryInteractionRouter.present(.trackChargeCycle(batteryID: batteryID))
                    } label: {
                        Label("Track charge cycle", systemImage: MySymbols.batteryCharge)
                    }
                    Button {
                        batteryInteractionRouter.present(.batteryJournal(batteryID: batteryID))
                    } label: {
                        Label("Battery journal", systemImage: MySymbols.stockJournal)
                    }
                    Button {
                        if let mdBattery {
                            batteryInteractionRouter.present(.editBattery(mdBattery: mdBattery))
                        }
                    } label: {
                        Label("Edit battery", systemImage: MySymbols.edit)
                    }
                    .disabled(mdBattery == nil)
                }
            }
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        BatteryDetailsView(batteryID: 1)
    }
}
