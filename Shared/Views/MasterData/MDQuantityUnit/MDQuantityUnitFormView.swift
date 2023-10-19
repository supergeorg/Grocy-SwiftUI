//
//  MDQuantityUnitFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDQuantityUnitFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Environment(\.dismiss) var dismiss
    
    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil
    
    var existingQuantityUnit: MDQuantityUnit?
    @State var quantityUnit: MDQuantityUnit
    
    @State private var showAddQuantityUnitConversion: Bool = false
    
    @State private var conversionToDelete: MDQuantityUnitConversion? = nil
    @State private var showConversionDeleteAlert: Bool = false
    
    @State private var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundQuantityUnit = grocyVM.mdQuantityUnits.first(where: {$0.name == quantityUnit.name})
        return !(quantityUnit.name.isEmpty || (foundQuantityUnit != nil && foundQuantityUnit!.id != quantityUnit.id))
    }
    
    init(existingQuantityUnit: MDQuantityUnit? = nil) {
        self.existingQuantityUnit = existingQuantityUnit
        let initialQuantityUnit = existingQuantityUnit ?? MDQuantityUnit(
            id: 0,
            name: "",
            namePlural: "",
            active: true,
            mdQuantityUnitDescription: "",
            rowCreatedTimestamp: Date().iso8601withFractionalSeconds
        )
        _quantityUnit = State(initialValue: initialQuantityUnit)
        _isNameCorrect = State(initialValue: true)
    }
    
    private let dataToUpdate: [ObjectEntities] = [.quantity_units, .quantity_unit_conversions]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var quConversions: MDQuantityUnitConversions {
        if let existingQuantityUnit = existingQuantityUnit {
            return grocyVM.mdQuantityUnitConversions.filter({ $0.fromQuID == existingQuantityUnit.id })
        } else {
            return []
        }
    }
    
    private func finishForm() {
        self.dismiss()
    }
    
    private func markDeleteQUConversion(conversion: MDQuantityUnitConversion) {
        conversionToDelete = conversion
        showConversionDeleteAlert.toggle()
    }
    private func deleteQUConversion(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .quantity_unit_conversions, id: toDelID)
            grocyVM.postLog("QU conversion delete successful.", type: .info)
            await grocyVM.requestData(objects: [.quantity_unit_conversions])
        } catch {
            grocyVM.postLog("QU conversion delete failed. \(error)", type: .error)
        }
    }
    
    private func saveQuantityUnit() async {
        if quantityUnit.id == 0 {
            quantityUnit.id = grocyVM.findNextID(.quantity_units)
        }
        isProcessing = true
        isSuccessful = nil
        do {
            if existingQuantityUnit == nil {
                _ = try await grocyVM.postMDObject(object: .quantity_units, content: quantityUnit)
            } else {
                try await grocyVM.putMDObjectWithID(object: .quantity_units, id: quantityUnit.id, content: quantityUnit)
            }
            grocyVM.postLog("Quantity unit \(quantityUnit.name) successful.", type: .info)
            await updateData()
            isSuccessful = true
        } catch {
            grocyVM.postLog("Quantity unit \(quantityUnit.name) failed. \(error)", type: .error)
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
            MyTextField(textToEdit: $quantityUnit.name, description: "Name (in singular form)", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "A name is required", errorMessage: "Name already exists")
            MyTextField(textToEdit: $quantityUnit.namePlural, description: "Name (in plural form)", isCorrect: Binding.constant(true), leadingIcon: "tag")
            MyToggle(isOn: $quantityUnit.active, description: "Active")
            MyTextField(textToEdit: $quantityUnit.mdQuantityUnitDescription, description: "Description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
            
            if existingQuantityUnit != nil {
                Section(content: {
                    ForEach(quConversions, id:\.id) { quConversion in
                        NavigationLink(value: quConversion) {
                            Text("\(quConversion.factor.formattedAmount) \(grocyVM.mdQuantityUnits.first(where: { $0.id == quConversion.toQuID })?.name ?? "\(quConversion.id)")")
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                            Button(role: .destructive,
                                   action: { markDeleteQUConversion(conversion: quConversion) },
                                   label: { Label("Delete", systemImage: MySymbols.delete) }
                            )
                        })
                    }
                }, header: {
                    VStack(alignment: .leading) {
                        HStack(alignment: .top) {
                            Text("Default conversions")
                            Spacer()
                            Button(action: {
                                showAddQuantityUnitConversion.toggle()
                            }, label: {
                                Label("New quantity unit conversion", systemImage: MySymbols.new)
                            })
                        }
                        Text("1 \(quantityUnit.name) is the same as...")
                            .italic()
                    }
                })
            }
        }
        .formStyle(.grouped)
        .navigationDestination(isPresented: $showAddQuantityUnitConversion, destination: {
            MDQuantityUnitConversionFormView(quantityUnit: quantityUnit)
        })
        .navigationDestination(for: MDQuantityUnitConversion.self, destination: { quantityUnitConversion in
            MDQuantityUnitConversionFormView(quantityUnit: quantityUnit, existingQuantityUnitConversion: quantityUnitConversion)
        })
        .navigationTitle(existingQuantityUnit == nil ? "New quantity unit" : "Edit quantity unit")
        .onChange(of: quantityUnit.name) {
            isNameCorrect = checkNameCorrect()
        }
        .task {
            await updateData()
            self.isNameCorrect = checkNameCorrect()
        }
        .refreshable {
            await updateData()
        }
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    Task {
                        await saveQuantityUnit()
                    }
                }, label: {
                    if isProcessing == false {
                        Label("Save quantity unit", systemImage: MySymbols.save)
                    } else {
                        ProgressView()
                    }
                })
                .disabled(!isNameCorrect || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        })
        .confirmationDialog("Delete", isPresented: $showConversionDeleteAlert, actions: {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let deleteID = conversionToDelete?.id {
                    Task {
                        await deleteQUConversion(toDelID: deleteID)
                    }
                }
            }
        }, message: {
            if let conversionToDelete = conversionToDelete {
                Text("\(conversionToDelete.factor.formattedAmount) \(grocyVM.mdQuantityUnits.first(where: { $0.id == conversionToDelete.toQuID })?.name ?? "\(conversionToDelete.id)")")
            } else {
                Text("Unknown error occured.")
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
