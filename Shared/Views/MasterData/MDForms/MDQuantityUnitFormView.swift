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
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var name: String = ""
    @State private var namePlural: String = ""
    @State private var isActive: Bool = true
    @State private var mdQuantityUnitDescription: String = ""
    
    var isNewQuantityUnit: Bool
    var quantityUnit: MDQuantityUnit?
    
    @Binding var showAddQuantityUnit: Bool
    
    
    @State private var showAddQuantityUnitConversion: Bool = false
    
    @State private var conversionToDelete: MDQuantityUnitConversion? = nil
    @State private var showConversionDeleteAlert: Bool = false
    
    @State private var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundQuantityUnit = grocyVM.mdQuantityUnits.first(where: {$0.name == name})
        return isNewQuantityUnit ? !(name.isEmpty || foundQuantityUnit != nil) : !(name.isEmpty || (foundQuantityUnit != nil && foundQuantityUnit!.id != quantityUnit!.id))
    }
    
    private func resetForm() {
        self.name = quantityUnit?.name ?? ""
        self.namePlural = quantityUnit?.namePlural ?? ""
        self.isActive = quantityUnit?.active ?? true
        self.mdQuantityUnitDescription = quantityUnit?.mdQuantityUnitDescription ?? ""
        isNameCorrect = checkNameCorrect()
    }
    
    private let dataToUpdate: [ObjectEntities] = [.quantity_units, .quantity_unit_conversions]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var quConversions: MDQuantityUnitConversions? {
        if !isNewQuantityUnit, let quantityUnitID = quantityUnit?.id {
            return grocyVM.mdQuantityUnitConversions.filter({ $0.fromQuID == quantityUnitID })
        } else {
            return nil
        }
    }
    
    private func finishForm() {
#if os(iOS)
        self.dismiss()
#elseif os(macOS)
        if isNewQuantityUnit {
            showAddQuantityUnit = false
        }
#endif
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
        let id = isNewQuantityUnit ? grocyVM.findNextID(.quantity_units) : quantityUnit!.id
        let timeStamp = isNewQuantityUnit ? Date().iso8601withFractionalSeconds : quantityUnit!.rowCreatedTimestamp
        let quantityUnitPOST = MDQuantityUnit(
            id: id,
            name: name,
            namePlural: namePlural,
            active: isActive,
            mdQuantityUnitDescription: mdQuantityUnitDescription,
            rowCreatedTimestamp: timeStamp
        )
        isProcessing = true
        if isNewQuantityUnit {
            do {
                _ = try await grocyVM.postMDObject(object: .quantity_units, content: quantityUnitPOST)
                grocyVM.postLog("Quantity unit added successfully.", type: .info)
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Quantity unit add failed. \(error)", type: .error)
            }
        } else {
            do {
                try await grocyVM.putMDObjectWithID(object: .quantity_units, id: id, content: quantityUnitPOST)
                grocyVM.postLog("Quantity unit \(quantityUnitPOST.name) edited successfully.", type: .info)
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Quantity unit edit failed. \(error)", type: .error)
            }
        }
        isProcessing = false
    }
    
    var body: some View {
        content
            .navigationTitle(isNewQuantityUnit ? "New quantity unit" : "Edit quantity unit")
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { Task { await saveQuantityUnit() } }, label: {
                        Label("Save quantity unit", systemImage: MySymbols.save)
                            .labelStyle(.titleAndIcon)
                    })
                    .disabled(!isNameCorrect || isProcessing)
                    .keyboardShortcut(.defaultAction)
                }
#if os(iOS)
                ToolbarItem(placement: .cancellationAction) {
                    if isNewQuantityUnit {
                        Button("Cancel") {
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
            Text(isNewQuantityUnit ? "New quantity unit" : "Edit quantity unit")
                .font(.title)
                .bold()
                .padding(.bottom, 20.0)
#endif
            Section(header: Text("Quantity unit info")){
                MyTextField(textToEdit: $name, description: "Name (in singular form)", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "A name is required", errorMessage: "Name already exists")
                    .onChange(of: name) {
                        isNameCorrect = checkNameCorrect()
                    }
                MyTextField(textToEdit: $namePlural, description: "Name (in plural form)", isCorrect: Binding.constant(true), leadingIcon: "tag")
                MyToggle(isOn: $isActive, description: "Active")
                MyTextField(textToEdit: $mdQuantityUnitDescription, description: "Description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
            }
            if !isNewQuantityUnit, let quantityUnit = quantityUnit {
                Section(header: VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        Text("Default conversions")
                        Spacer()
                        Button(action: {
                            showAddQuantityUnitConversion.toggle()
                        }, label: {
                            Image(systemName: MySymbols.new)
                                .font(.body)
                        })
                    }
                    Text("str.md.quantityUnit.conversions.hint \("1 \(quantityUnit.name)""))
                        .italic()
                })
                {
#if os(macOS)
                    NavigationView {
                        List {
                            ForEach(quConversions ?? [], id:\.id) { quConversion in
                                NavigationLink(destination: {
                                    MDQuantityUnitConversionFormView(isNewQuantityUnitConversion: false, quantityUnit: quantityUnit, quantityUnitConversion: quConversion, showAddQuantityUnitConversion: $showAddQuantityUnitConversion)
                                }, label: {
                                    Text("\(quConversion.factor.formattedAmount) \(grocyVM.mdQuantityUnits.first(where: { $0.id == quConversion.toQuID })?.name ?? "\(quConversion.id)")")
                                })
                                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                                    Button(role: .destructive,
                                           action: { markDeleteQUConversion(conversion: quConversion) },
                                           label: { Label("Delete", systemImage: MySymbols.delete) }
                                    )
                                })
                            }
                        }
                    }
#else
                    List {
                        ForEach(quConversions ?? [], id:\.id) { quConversion in
                            NavigationLink(destination: {
                                MDQuantityUnitConversionFormView(isNewQuantityUnitConversion: false, quantityUnit: quantityUnit, quantityUnitConversion: quConversion, showAddQuantityUnitConversion: $showAddQuantityUnitConversion)
                            }, label: {
                                Text("\(quConversion.factor.formattedAmount) \(grocyVM.mdQuantityUnits.first(where: { $0.id == quConversion.toQuID })?.name ?? "\(quConversion.id)")")
                            })
                            .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                                Button(role: .destructive,
                                       action: { markDeleteQUConversion(conversion: quConversion) },
                                       label: { Label("Delete", systemImage: MySymbols.delete) }
                                )
                            })
                        }
                    }
#endif
                }
                .sheet(isPresented: $showAddQuantityUnitConversion, content: {
#if os(macOS)
                    MDQuantityUnitConversionFormView(isNewQuantityUnitConversion: true, quantityUnit: quantityUnit, showAddQuantityUnitConversion: $showAddQuantityUnitConversion)
#else
                    NavigationView {
                        MDQuantityUnitConversionFormView(isNewQuantityUnitConversion: true, quantityUnit: quantityUnit, showAddQuantityUnitConversion: $showAddQuantityUnitConversion)
                    }
#endif
                })
                .alert("Delete", isPresented: $showConversionDeleteAlert, actions: {
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
            }
        }
        .refreshable {
            await updateData()
        }
        .task {
            if firstAppear {
                await updateData()
                resetForm()
                firstAppear = false
            }
        }
    }
}

struct MDQuantityUnitFormView_Previews: PreviewProvider {
    static var previews: some View {
#if os(macOS)
        Group {
            MDQuantityUnitFormView(isNewQuantityUnit: true, showAddQuantityUnit: Binding.constant(true))
            MDQuantityUnitFormView(isNewQuantityUnit: false, quantityUnit: MDQuantityUnit(id: 0, name: "Quantity unit", namePlural: "QU Plural", active: true, mdQuantityUnitDescription: "Description", rowCreatedTimestamp: ""), showAddQuantityUnit: Binding.constant(false))
        }
#else
        Group {
            NavigationView {
                MDQuantityUnitFormView(isNewQuantityUnit: true, showAddQuantityUnit: Binding.constant(true))
            }
            NavigationView {
                MDQuantityUnitFormView(isNewQuantityUnit: false, quantityUnit: MDQuantityUnit(id: 0, name: "Quantity unit", namePlural: "QU Plural", active: true, mdQuantityUnitDescription: "Description", rowCreatedTimestamp: ""), showAddQuantityUnit: Binding.constant(false))
            }
        }
#endif
    }
}
