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
    
    private var quConversions: MDQuantityUnitConversions? {
        if let existingQuantityUnit = existingQuantityUnit {
            return grocyVM.mdQuantityUnitConversions.filter({ $0.fromQuID == existingQuantityUnit.id })
        } else {
            return nil
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
        //        let id = isNewQuantityUnit ? grocyVM.findNextID(.quantity_units) : quantityUnit!.id
        //        let timeStamp = isNewQuantityUnit ? Date().iso8601withFractionalSeconds : quantityUnit!.rowCreatedTimestamp
        //        let quantityUnitPOST = MDQuantityUnit(
        //            id: id,
        //            name: name,
        //            namePlural: namePlural,
        //            active: isActive,
        //            mdQuantityUnitDescription: mdQuantityUnitDescription,
        //            rowCreatedTimestamp: timeStamp
        //        )
        isProcessing = true
        //        if isNewQuantityUnit {
        //            do {
        //                _ = try await grocyVM.postMDObject(object: .quantity_units, content: quantityUnitPOST)
        //                grocyVM.postLog("Quantity unit added successfully.", type: .info)
        //                await updateData()
        //                finishForm()
        //            } catch {
        //                grocyVM.postLog("Quantity unit add failed. \(error)", type: .error)
        //            }
        //        } else {
        //            do {
        //                try await grocyVM.putMDObjectWithID(object: .quantity_units, id: id, content: quantityUnitPOST)
        //                grocyVM.postLog("Quantity unit \(quantityUnitPOST.name) edited successfully.", type: .info)
        //                await updateData()
        //                finishForm()
        //            } catch {
        //                grocyVM.postLog("Quantity unit edit failed. \(error)", type: .error)
        //            }
        //        }
        isProcessing = false
    }
    
    var body: some View {
        Form {
            MyTextField(textToEdit: $quantityUnit.name, description: "Name (in singular form)", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "A name is required", errorMessage: "Name already exists")
            MyTextField(textToEdit: $quantityUnit.namePlural, description: "Name (in plural form)", isCorrect: Binding.constant(true), leadingIcon: "tag")
            MyToggle(isOn: $quantityUnit.active, description: "Active")
            MyTextField(textToEdit: $quantityUnit.mdQuantityUnitDescription, description: "Description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
            
            if let existingQuantityUnit = existingQuantityUnit {
                Section(header: VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        Text("Default conversions")
                        Spacer()
                        Button(action: {
                            //                                        showAddQuantityUnitConversion.toggle()
                            print("ADD")
                        }, label: {
                            Image(systemName: MySymbols.new)
                            //                                            .font(.body)
                        })
                    }
                    Text("1 \(quantityUnit.name) is the same as...")
                        .italic()
                })
            }
        }
        .formStyle(.grouped)
        .onChange(of: quantityUnit.name) {
            isNameCorrect = checkNameCorrect()
        }
        .navigationTitle(existingQuantityUnit == nil ? "New quantity unit" : "Edit quantity unit")
        .task {
            await updateData()
            
        }
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: { Task { await saveQuantityUnit() } }, label: {
                    Label("Save quantity unit", systemImage: MySymbols.save)
                        .labelStyle(.titleAndIcon)
                })
                .disabled(!isNameCorrect || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        })
    }
    //                {
    //#if os(macOS)
    //                    NavigationView {
    //                        List {
    //                            ForEach(quConversions ?? [], id:\.id) { quConversion in
    //                                NavigationLink(destination: {
    //                                    MDQuantityUnitConversionFormView(isNewQuantityUnitConversion: false, quantityUnit: quantityUnit, quantityUnitConversion: quConversion, showAddQuantityUnitConversion: $showAddQuantityUnitConversion)
    //                                }, label: {
    //                                    Text("\(quConversion.factor.formattedAmount) \(grocyVM.mdQuantityUnits.first(where: { $0.id == quConversion.toQuID })?.name ?? "\(quConversion.id)")")
    //                                })
    //                                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
    //                                    Button(role: .destructive,
    //                                           action: { markDeleteQUConversion(conversion: quConversion) },
    //                                           label: { Label("Delete", systemImage: MySymbols.delete) }
    //                                    )
    //                                })
    //                            }
    //                        }
    //                    }
    //#else
    //                    List {
    //                        ForEach(quConversions ?? [], id:\.id) { quConversion in
    //                            NavigationLink(destination: {
    //                                MDQuantityUnitConversionFormView(isNewQuantityUnitConversion: false, quantityUnit: quantityUnit, quantityUnitConversion: quConversion, showAddQuantityUnitConversion: $showAddQuantityUnitConversion)
    //                            }, label: {
    //                                Text("\(quConversion.factor.formattedAmount) \(grocyVM.mdQuantityUnits.first(where: { $0.id == quConversion.toQuID })?.name ?? "\(quConversion.id)")")
    //                            })
    //                            .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
    //                                Button(role: .destructive,
    //                                       action: { markDeleteQUConversion(conversion: quConversion) },
    //                                       label: { Label("Delete", systemImage: MySymbols.delete) }
    //                                )
    //                            })
    //                        }
    //                    }
    //#endif
    //                }
    //                .sheet(isPresented: $showAddQuantityUnitConversion, content: {
    //#if os(macOS)
    //                    MDQuantityUnitConversionFormView(isNewQuantityUnitConversion: true, quantityUnit: quantityUnit, showAddQuantityUnitConversion: $showAddQuantityUnitConversion)
    //#else
    //                    NavigationView {
    //                        MDQuantityUnitConversionFormView(isNewQuantityUnitConversion: true, quantityUnit: quantityUnit, showAddQuantityUnitConversion: $showAddQuantityUnitConversion)
    //                    }
    //#endif
    //                })
    //                .alert("Delete", isPresented: $showConversionDeleteAlert, actions: {
    //                    Button("Cancel", role: .cancel) { }
    //                    Button("Delete", role: .destructive) {
    //                        if let deleteID = conversionToDelete?.id {
    //                            Task {
    //                                await deleteQUConversion(toDelID: deleteID)
    //                            }
    //                        }
    //                    }
    //                }, message: {
    //                    if let conversionToDelete = conversionToDelete {
    //                        Text("\(conversionToDelete.factor.formattedAmount) \(grocyVM.mdQuantityUnits.first(where: { $0.id == conversionToDelete.toQuID })?.name ?? "\(conversionToDelete.id)")")
    //                    } else {
    //                        Text("Unknown error occured.")
    //                    }
    //                })
    //            }
    //        }
    //        .task {
    //            if firstAppear {
    //                await updateData()
    //                resetForm()
    //                firstAppear = false
    //            }
    //        }
    //    }
}
