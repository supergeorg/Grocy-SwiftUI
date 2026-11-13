//
//  MDQuantityUnitConversionFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 04.02.22.
//

import SwiftData
import SwiftUI

struct MDQuantityUnitConversionFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query(sort: \MDQuantityUnitConversion.id, order: .forward) var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query(filter: #Predicate<MDQuantityUnit> { $0.active }, sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits

    @Environment(\.dismiss) var dismiss

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var quantityUnit: MDQuantityUnit
    var existingQuantityUnitConversion: MDQuantityUnitConversion?
    @State private var quantityUnitConversion: MDQuantityUnitConversion

    @State private var createInverseConversion: Bool = true

    @State private var conversionCorrect: Bool = false
    private func checkConversionExists() -> Bool {
        let foundQuantityUnitConversionsForQU = mdQuantityUnitConversions.filter({ $0.fromQuID == quantityUnitConversion.fromQuID })
        let foundQuantityUnitConversion = foundQuantityUnitConversionsForQU.first(where: { $0.toQuID == quantityUnitConversion.toQuID })
        if let foundQuantityUnitConversion = foundQuantityUnitConversion {
            if foundQuantityUnitConversion.id == quantityUnitConversion.id {
                return false
            } else {
                return true
            }
        } else {
            return false
        }
    }
    private func checkReverseConversionExists() -> Bool {
        let foundQuantityUnitConversionsForQU = mdQuantityUnitConversions.filter({ $0.fromQuID == quantityUnitConversion.toQuID })
        let foundQuantityUnitConversion = foundQuantityUnitConversionsForQU.first(where: { $0.toQuID == quantityUnitConversion.fromQuID })
        if foundQuantityUnitConversion != nil {
            return true
        } else {
            return false
        }
    }
    private func checkConversionCorrect() -> Bool {
        return quantityUnitConversion.factor > 0 && !checkConversionExists() && !(createInverseConversion && checkReverseConversionExists())
    }

    init(quantityUnit: MDQuantityUnit, existingQuantityUnitConversion: MDQuantityUnitConversion? = nil) {
        self.quantityUnit = quantityUnit
        self.existingQuantityUnitConversion = existingQuantityUnitConversion
        let initialQuantityUnitConversion = existingQuantityUnitConversion ?? MDQuantityUnitConversion(fromQuID: quantityUnit.id)
        _quantityUnitConversion = State(initialValue: initialQuantityUnitConversion)
    }

    private let dataToUpdate: [ObjectEntities] = [.quantity_unit_conversions]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func getQUString(amount: Double, qu: MDQuantityUnit?) -> String {
        if let qu = qu {
            return "\(amount.formattedAmount) \(qu.getName(amount: amount))"
        } else {
            return amount.formattedAmount
        }
    }

    private func finishForm() {
        self.dismiss()
    }

    private func saveQuantityUnitConversion() async {
        if quantityUnitConversion.id == -1 {
            do {
                quantityUnitConversion.id = try grocyVM.findNextID(.quantity_unit_conversions)
            } catch {
                GrocyLogger.error("Failed to get next ID: \(error)")
                return
            }
        }
        isProcessing = true
        isSuccessful = nil
        do {
            try quantityUnitConversion.modelContext?.save()
            if existingQuantityUnitConversion == nil {
                _ = try await grocyVM.postMDObject(object: .quantity_unit_conversions, content: quantityUnitConversion)
                if createInverseConversion {
                    do {
                        let inverseQuantityUnitConversion = MDQuantityUnitConversion(
                            id: try grocyVM.findNextID(.quantity_unit_conversions) + 1,
                            fromQuID: quantityUnitConversion.toQuID,
                            toQuID: quantityUnitConversion.fromQuID,
                            factor: (1 / quantityUnitConversion.factor),
                            productID: nil
                        )
                        _ = try await grocyVM.postMDObject(object: .quantity_unit_conversions, content: inverseQuantityUnitConversion)
                        GrocyLogger.info("Inverse quantity unit conversion add successful.")
                    } catch {
                        GrocyLogger.error("Inverse quantity unit conversion add failed. \(error)")
                    }
                } else {
                    GrocyLogger.info("Quantity unit conversion added successfully.")
                }
            } else {
                try await grocyVM.putMDObjectWithID(object: .quantity_unit_conversions, id: quantityUnitConversion.id, content: quantityUnitConversion)
            }
            GrocyLogger.info("Quantity unit conversion add for \(quantityUnit.name) successful.")
            await updateData()
            isSuccessful = true
        } catch {
            GrocyLogger.error("Quantity unit conversion add for \(quantityUnit.name) failed. \(error)")
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
            isSuccessful = false
        }
        isProcessing = false
    }

    var body: some View {
        Form {
            if isSuccessful == false, let errorMessage = errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            Picker(
                selection: $quantityUnitConversion.fromQuID,
                label: Label("Quantity unit from", systemImage: MySymbols.quantityUnit),
                content: {
                    Text("")
                        .tag(0)
                    ForEach(mdQuantityUnits, id: \.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name)
                            .tag(grocyQuantityUnit.id)
                    }
                }
            )
            .foregroundStyle(.primary)
            .disabled(true)

            VStack(alignment: .leading) {
                Picker(
                    selection: $quantityUnitConversion.toQuID,
                    label: Label("Quantity unit to", systemImage: MySymbols.quantityUnit),
                    content: {
                        Text("")
                            .tag(0)
                        ForEach(mdQuantityUnits.filter({ $0.id != quantityUnit.id }), id: \.id) { grocyQuantityUnit in
                            Text(grocyQuantityUnit.name)
                                .tag(grocyQuantityUnit.id)
                        }
                    }
                )
                .foregroundStyle(.primary)

                if checkConversionExists() {
                    Text("Such a conversion already exists")
                        .font(.caption)
                        .foregroundStyle(Color.red)
                }
                Text("This means \(getQUString(amount: 1, qu: quantityUnit)) is the same as \(getQUString(amount: quantityUnitConversion.factor, qu: mdQuantityUnits.first(where: { $0.id == quantityUnitConversion.toQuID })))")
                    .font(.caption)
            }

            MyDoubleStepper(amount: $quantityUnitConversion.factor, description: "Factor", minAmount: 0.0001, amountStep: 1.0, amountName: "", systemImage: MySymbols.amount)

            if existingQuantityUnitConversion == nil {
                VStack(alignment: .leading) {
                    MyToggle(isOn: $createInverseConversion, description: "Create inverse QU conversion", icon: MySymbols.transfer)

                    if checkReverseConversionExists() {
                        Text("Such a conversion already exists")
                            .font(.caption)
                            .foregroundStyle(Color.red)
                    }
                    Text("This means \(getQUString(amount: 1, qu: mdQuantityUnits.first(where: { $0.id == quantityUnitConversion.toQuID }))) is the same as \(getQUString(amount: (1 / quantityUnitConversion.factor), qu: quantityUnit))")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Create QU conversion")
        .onChange(of: quantityUnitConversion.factor) {
            conversionCorrect = checkConversionCorrect()
        }
        .onChange(of: createInverseConversion) {
            conversionCorrect = checkConversionCorrect()
        }
        .onChange(of: quantityUnitConversion.toQuID) {
            conversionCorrect = checkConversionCorrect()
        }
        .formStyle(.grouped)
        .task {
            await updateData()
        }
        .navigationTitle(existingQuantityUnitConversion == nil ? "Create QU conversion" : "Edit QU conversion")
        .toolbar(content: {
            if existingQuantityUnitConversion == nil {
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
            ToolbarItem(placement: .confirmationAction) {
                Button(
                    role: .confirm,
                    action: {
                        Task {
                            await saveQuantityUnitConversion()
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
                .disabled(!conversionCorrect || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
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
        MDQuantityUnitConversionFormView(quantityUnit: MDQuantityUnit(name: "Quantity unit"))
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        MDQuantityUnitConversionFormView(quantityUnit: MDQuantityUnit(name: "Piece"), existingQuantityUnitConversion: MDQuantityUnitConversion(fromQuID: 2, toQuID: 3))
    }
}
