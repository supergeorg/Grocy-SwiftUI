//
//  MDQuantityUnitConversionFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 04.02.22.
//

import SwiftUI
import SwiftData

struct MDQuantityUnitConversionFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDQuantityUnitConversion.id, order: .forward) var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query(filter: #Predicate<MDQuantityUnit>{$0.active}, sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    
    @Environment(\.dismiss) var dismiss
    
    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil
    
    var quantityUnit: MDQuantityUnit
    var existingQuantityUnitConversion: MDQuantityUnitConversion?
    @State var quantityUnitConversion: MDQuantityUnitConversion
    
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
        let initialQuantityUnitConversion = existingQuantityUnitConversion ?? MDQuantityUnitConversion(
            id: 0,
            fromQuID: quantityUnit.id,
            toQuID: 0,
            factor: 1,
            productID: nil,
            rowCreatedTimestamp: Date().iso8601withFractionalSeconds
        )
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
        if quantityUnitConversion.id == 0 {
            quantityUnitConversion.id = grocyVM.findNextID(.quantity_unit_conversions)
        }
        isProcessing = true
        isSuccessful = nil
        do {
            if existingQuantityUnitConversion == nil {
                _ = try await grocyVM.postMDObject(object: .quantity_unit_conversions, content: quantityUnitConversion)
                if createInverseConversion {
                    do {
                        let inverseQuantityUnitConversion = MDQuantityUnitConversion(
                            id: grocyVM.findNextID(.quantity_unit_conversions) + 1,
                            fromQuID: quantityUnitConversion.toQuID,
                            toQuID: quantityUnitConversion.fromQuID,
                            factor: (1 / quantityUnitConversion.factor),
                            productID: nil,
                            rowCreatedTimestamp: Date().iso8601withFractionalSeconds
                        )
                        _ = try await grocyVM.postMDObject(object: .quantity_unit_conversions, content: inverseQuantityUnitConversion)
                        grocyVM.postLog("Inverse quantity unit conversion add successful.", type: .info)
                    } catch {
                        grocyVM.postLog("Inverse quantity unit conversion add failed. \(error)", type: .error)
                    }
                } else {
                    grocyVM.postLog("Quantity unit conversion added successfully.", type: .info)
                }
            } else {
                try await grocyVM.putMDObjectWithID(object: .quantity_unit_conversions, id: quantityUnitConversion.id, content: quantityUnitConversion)
            }
            grocyVM.postLog("Quantity unit conversion add for \(quantityUnit.name) successful.", type: .info)
            await updateData()
            isSuccessful = true
        } catch {
            grocyVM.postLog("Quantity unit conversion add for \(quantityUnit.name) failed. \(error)", type: .error)
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
            Picker(selection: $quantityUnitConversion.fromQuID, label: Label("Quantity unit from", systemImage: MySymbols.quantityUnit), content: {
                Text("")
                    .tag(0)
                ForEach(mdQuantityUnits, id:\.id) { grocyQuantityUnit in
                    Text(grocyQuantityUnit.name)
                        .tag(grocyQuantityUnit.id)
                }
            })
            .disabled(true)
            
            VStack(alignment: .leading) {
                Picker(selection: $quantityUnitConversion.toQuID, label: Label("Quantity unit to", systemImage: MySymbols.quantityUnit), content: {
                    Text("")
                        .tag(0)
                    ForEach(mdQuantityUnits.filter({ $0.id != quantityUnit.id }), id:\.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name)
                            .tag(grocyQuantityUnit.id)
                    }
                })
                
                if checkConversionExists() {
                    Text("Such a conversion already exists")
                        .font(.caption)
                        .foregroundStyle(Color.red)
                }
                Text("This means \(getQUString(amount: 1, qu: quantityUnit)) is the same as \(getQUString(amount: quantityUnitConversion.factor, qu: mdQuantityUnits.first(where: { $0.id == quantityUnitConversion.toQuID })))")
                    .font(.caption)
            }
            
            MyDoubleStepper(amount: $quantityUnitConversion.factor, description: "Factor", minAmount: 0.0001, amountStep: 1, amountName: "", systemImage: MySymbols.amount)
            
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
            ToolbarItem(placement: .confirmationAction) {
                Button(action: { Task { await saveQuantityUnitConversion() } }, label: {
                    Label("Save", systemImage: MySymbols.save)
                })
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

#Preview {
    MDQuantityUnitConversionFormView(quantityUnit: MDQuantityUnit(id: 1, name: "Quantity unit", active: true, rowCreatedTimestamp: ""))
}
