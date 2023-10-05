//
//  MDQuantityUnitConversionFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 04.02.22.
//

import SwiftUI

struct MDQuantityUnitConversionFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var quIDFrom: Int?
    @State private var quIDTo: Int?
    @State private var factor: Double = 1.0
    @State private var createInverseConversion: Bool = true
    
    var isNewQuantityUnitConversion: Bool
    var quantityUnit: MDQuantityUnit
    var quantityUnitConversion: MDQuantityUnitConversion?
    
    @Binding var showAddQuantityUnitConversion: Bool
    
    
    @State private var conversionCorrect: Bool = false
    private func checkConversionExists() -> Bool {
        let foundQuantityUnitConversionsForQU = grocyVM.mdQuantityUnitConversions.filter({ $0.fromQuID == quIDFrom })
        let foundQuantityUnitConversion = foundQuantityUnitConversionsForQU.first(where: { $0.toQuID == quIDTo })
        if let foundQuantityUnitConversion = foundQuantityUnitConversion {
            if foundQuantityUnitConversion.id == quantityUnitConversion?.id {
                return false
            } else {
                return true
            }
        } else {
            return false
        }
    }
    private func checkReverseConversionExists() -> Bool {
        let foundQuantityUnitConversionsForQU = grocyVM.mdQuantityUnitConversions.filter({ $0.fromQuID == quIDTo })
        let foundQuantityUnitConversion = foundQuantityUnitConversionsForQU.first(where: { $0.toQuID == quIDFrom })
        if foundQuantityUnitConversion != nil {
            return true
        } else {
            return false
        }
    }
    private func checkConversionCorrect() -> Bool {
        return (factor > 0 && !checkConversionExists() && !(createInverseConversion && checkReverseConversionExists()) && quIDTo != nil)
    }
    
    private func resetForm() {
        self.quIDFrom = quantityUnitConversion?.fromQuID ?? quantityUnit.id
        self.quIDTo = quantityUnitConversion?.toQuID
        self.factor = quantityUnitConversion?.factor ?? 1.0
        self.createInverseConversion = true
        self.conversionCorrect = checkConversionCorrect()
    }
    
    private let dataToUpdate: [ObjectEntities] = [.quantity_unit_conversions]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private func getQUString(amount: Double, qu: MDQuantityUnit?) -> String {
        if let qu = qu {
            return "\(amount.formattedAmount) \(amount == 1 ? qu.name : qu.namePlural ?? qu.name)"
        } else {
            return amount.formattedAmount
        }
    }
    
    private func finishForm() {
#if os(iOS)
        self.dismiss()
#elseif os(macOS)
        if isNewQuantityUnitConversion {
            showAddQuantityUnitConversion = false
        }
#endif
    }
    
    private func saveQuantityUnitConversion() async {
        let id = isNewQuantityUnitConversion ? grocyVM.findNextID(.quantity_unit_conversions) : quantityUnitConversion!.id
        let timeStamp = isNewQuantityUnitConversion ? Date().iso8601withFractionalSeconds : quantityUnit.rowCreatedTimestamp
        let quantityUnitConversionPOST = MDQuantityUnitConversion(id: id, fromQuID: quIDFrom!, toQuID: quIDTo!, factor: factor, productID: nil, rowCreatedTimestamp: timeStamp)
        isProcessing = true
        if isNewQuantityUnitConversion {
            do {
                _ = try await grocyVM.postMDObject(object: .quantity_unit_conversions, content: quantityUnitConversionPOST)
                
                if createInverseConversion {
                    do {
                        let id = isNewQuantityUnitConversion ? (grocyVM.findNextID(.quantity_unit_conversions) + 1) : quantityUnitConversion!.id
                        let timeStamp = isNewQuantityUnitConversion ? Date().iso8601withFractionalSeconds : quantityUnit.rowCreatedTimestamp
                        let quantityUnitConversionPOST = MDQuantityUnitConversion(id: id, fromQuID: quIDTo!, toQuID: quIDFrom!, factor: (1 / factor), productID: nil, rowCreatedTimestamp: timeStamp)
                        _ = try await grocyVM.postMDObject(object: .quantity_unit_conversions, content: quantityUnitConversionPOST)
                        grocyVM.postLog("Inverse quantity unit conversion add successful.", type: .info)
                    } catch {
                        grocyVM.postLog("Inverse quantity unit conversion add failed. \(error)", type: .error)
                    }
                } else {
                    grocyVM.postLog("Quantity unit conversion added successfully.", type: .info)
                }
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Quantity unit conversion add failed. \(error)", type: .error)
            }
        } else {
            do {
                try await grocyVM.putMDObjectWithID(object: .quantity_unit_conversions, id: id, content: quantityUnitConversionPOST)
                grocyVM.postLog("Quantity unit conversion edited successfully.", type: .info)
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Quantity unit conversion edit failed. \(error)", type: .error)
            }
        }
        isProcessing = false
    }
    
    var body: some View {
        content
            .navigationTitle(isNewQuantityUnitConversion ? LocalizedStringKey("str.md.quantityUnit.conversion.new") : LocalizedStringKey("str.md.quantityUnit.conversion.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { Task { await saveQuantityUnitConversion() } }, label: {
                        Label(LocalizedStringKey("str.save"), systemImage: MySymbols.save)
                            .labelStyle(.titleAndIcon)
                    })
                    .disabled(!conversionCorrect || isProcessing)
                    .keyboardShortcut(.defaultAction)
                }
#if os(iOS)
                ToolbarItem(placement: .cancellationAction) {
                    if isNewQuantityUnitConversion {
                        Button(LocalizedStringKey("str.cancel")) {
                            finishForm()
                        }
                    }
                }
#endif
            })
    }
    
    var content: some View {
        Form {
#if os(macOS)
            Text(isNewQuantityUnitConversion ? LocalizedStringKey("str.md.quantityUnit.conversion.new") : LocalizedStringKey("str.md.quantityUnit.conversion.edit"))
                .font(.title)
                .bold()
                .padding(.bottom, 20.0)
#endif
            Section(){
                Picker(selection: $quIDFrom, label: Label(LocalizedStringKey("str.md.quantityUnit.conversion.quFrom"), systemImage: MySymbols.quantityUnit), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdQuantityUnits.filter({$0.active}), id:\.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id as Int?)
                    }
                })
                .disabled(true)
                
                VStack(alignment: .leading) {
                    Picker(selection: $quIDTo, label: Label(LocalizedStringKey("str.md.quantityUnit.conversion.quTo"), systemImage: MySymbols.quantityUnit), content: {
                        Text("").tag(nil as Int?)
                        ForEach(grocyVM.mdQuantityUnits.filter({ $0.id != quantityUnit.id }), id:\.id) { grocyQuantityUnit in
                            Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id as Int?)
                        }
                    })
                    .onChange(of: quIDTo) {
                        conversionCorrect = checkConversionCorrect()
                    }
                    if checkConversionExists() {
                        Text(LocalizedStringKey("str.md.quantityUnit.conversion.quTo.exists"))
                            .font(.caption)
                            .foregroundColor(Color.red)
                    }
                    if let quIDTo = quIDTo {
                        Text(LocalizedStringKey("str.md.quantityUnit.conversion.means \(getQUString(amount: 1, qu: quantityUnit)) \(getQUString(amount: factor, qu: grocyVM.mdQuantityUnits.first(where: { $0.id == quIDTo })))"))
                            .font(.caption)
                    }
                }
                
                MyDoubleStepper(amount: $factor, description: "str.md.quantityUnit.conversion.factor", minAmount: 0.0001, amountStep: 1, amountName: "", systemImage: MySymbols.amount)
                    .onChange(of: factor) {
                        conversionCorrect = checkConversionCorrect()
                    }
                
                if isNewQuantityUnitConversion {
                    VStack(alignment: .leading) {
                        MyToggle(isOn: $createInverseConversion, description: "str.md.quantityUnit.conversion.createInverse", icon: MySymbols.transfer)
                            .onChange(of: createInverseConversion) {
                                conversionCorrect = checkConversionCorrect()
                            }
                        if checkReverseConversionExists() {
                            Text(LocalizedStringKey("str.md.quantityUnit.conversion.quTo.exists"))
                                .font(.caption)
                                .foregroundColor(Color.red)
                        }
                        if let quIDTo = quIDTo {
                            Text(LocalizedStringKey("str.md.quantityUnit.conversion.means \(getQUString(amount: 1, qu: grocyVM.mdQuantityUnits.first(where: { $0.id == quIDTo }))) \(getQUString(amount: (1 / factor), qu: quantityUnit))"))
                                .font(.caption)
                        }
                    }
                }
#if os(macOS)
                Button(action: { Task { await saveQuantityUnitConversion() } }, label: {
                    Label(LocalizedStringKey("str.save"), systemImage: MySymbols.save)
                        .labelStyle(.titleAndIcon)
                })
#endif
            }
        }
        .task {
            if firstAppear {
                await grocyVM.requestData(objects: dataToUpdate)
                resetForm()
                firstAppear = false
            }
        }
    }
}

struct MDQuantityUnitConversionFormView_Previews: PreviewProvider {
    static var previews: some View {
        MDQuantityUnitConversionFormView(isNewQuantityUnitConversion: true, quantityUnit: MDQuantityUnit(id: 1, name: "Test QU", namePlural: "NAME PLURAL", active: true, mdQuantityUnitDescription: "DESCRIPTION", rowCreatedTimestamp: "ts"), showAddQuantityUnitConversion: Binding.constant(true))
    }
}
