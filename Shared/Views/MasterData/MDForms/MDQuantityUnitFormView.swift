//
//  MDQuantityUnitFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDQuantityUnitFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
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
    @Binding var toastType: ToastType?
    
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
            toastType = .successEdit
        } catch {
            grocyVM.postLog("QU conversion delete failed. \(error)", type: .error)
            toastType = .failEdit
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
                toastType = .successAdd
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Quantity unit add failed. \(error)", type: .error)
                toastType = .failAdd
            }
        } else {
            do {
                try await grocyVM.putMDObjectWithID(object: .quantity_units, id: id, content: quantityUnitPOST)
                grocyVM.postLog("Quantity unit \(quantityUnitPOST.name) edited successfully.", type: .info)
                toastType = .successAdd
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Quantity unit edit failed. \(error)", type: .error)
                toastType = .failAdd
            }
        }
        isProcessing = false
    }
    
    var body: some View {
        content
            .navigationTitle(isNewQuantityUnit ? LocalizedStringKey("str.md.quantityUnit.new") : LocalizedStringKey("str.md.quantityUnit.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { Task { await saveQuantityUnit() } }, label: {
                        Label(LocalizedStringKey("str.md.quantityUnit.save"), systemImage: MySymbols.save)
                            .labelStyle(.titleAndIcon)
                    })
                    .disabled(!isNameCorrect || isProcessing)
                    .keyboardShortcut(.defaultAction)
                }
#if os(iOS)
                ToolbarItem(placement: .cancellationAction) {
                    if isNewQuantityUnit {
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
            Text(isNewQuantityUnit ? LocalizedStringKey("str.md.quantityUnit.new") : LocalizedStringKey("str.md.quantityUnit.edit"))
                .font(.title)
                .bold()
                .padding(.bottom, 20.0)
#endif
            Section(header: Text(LocalizedStringKey("str.md.quantityUnit.info"))){
                MyTextField(textToEdit: $name, description: "str.md.quantityUnit.name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "str.md.quantityUnit.name.required", errorMessage: "str.md.quantityUnit.name.exists")
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
                MyTextField(textToEdit: $namePlural, description: "str.md.quantityUnit.namePlural", isCorrect: Binding.constant(true), leadingIcon: "tag")
                MyToggle(isOn: $isActive, description: "str.md.product.active")
                MyTextField(textToEdit: $mdQuantityUnitDescription, description: "str.md.description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
            }
            if !isNewQuantityUnit, let quantityUnit = quantityUnit {
                Section(header: VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        Text(LocalizedStringKey("str.md.quantityUnit.conversions"))
                        Spacer()
                        Button(action: {
                            showAddQuantityUnitConversion.toggle()
                        }, label: {
                            Image(systemName: MySymbols.new)
                                .font(.body)
                        })
                    }
                    Text(LocalizedStringKey("str.md.quantityUnit.conversions.hint \("1 \(quantityUnit.name)")"))
                        .italic()
                })
                {
#if os(macOS)
                    NavigationView {
                        List {
                            ForEach(quConversions ?? [], id:\.id) { quConversion in
                                NavigationLink(destination: {
                                    MDQuantityUnitConversionFormView(isNewQuantityUnitConversion: false, quantityUnit: quantityUnit, quantityUnitConversion: quConversion, showAddQuantityUnitConversion: $showAddQuantityUnitConversion, toastType: $toastType)
                                }, label: {
                                    Text("\(quConversion.factor.formattedAmount) \(grocyVM.mdQuantityUnits.first(where: { $0.id == quConversion.toQuID })?.name ?? "\(quConversion.id)")")
                                })
                                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                                    Button(role: .destructive,
                                           action: { markDeleteQUConversion(conversion: quConversion) },
                                           label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) }
                                    )
                                })
                            }
                        }
                    }
#else
                    List {
                        ForEach(quConversions ?? [], id:\.id) { quConversion in
                            NavigationLink(destination: {
                                MDQuantityUnitConversionFormView(isNewQuantityUnitConversion: false, quantityUnit: quantityUnit, quantityUnitConversion: quConversion, showAddQuantityUnitConversion: $showAddQuantityUnitConversion, toastType: $toastType)
                            }, label: {
                                Text("\(quConversion.factor.formattedAmount) \(grocyVM.mdQuantityUnits.first(where: { $0.id == quConversion.toQuID })?.name ?? "\(quConversion.id)")")
                            })
                            .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                                Button(role: .destructive,
                                       action: { markDeleteQUConversion(conversion: quConversion) },
                                       label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) }
                                )
                            })
                        }
                    }
#endif
                }
                .sheet(isPresented: $showAddQuantityUnitConversion, content: {
#if os(macOS)
                    MDQuantityUnitConversionFormView(isNewQuantityUnitConversion: true, quantityUnit: quantityUnit, showAddQuantityUnitConversion: $showAddQuantityUnitConversion, toastType: $toastType)
#else
                    NavigationView {
                        MDQuantityUnitConversionFormView(isNewQuantityUnitConversion: true, quantityUnit: quantityUnit, showAddQuantityUnitConversion: $showAddQuantityUnitConversion, toastType: $toastType)
                    }
#endif
                })
                .alert(LocalizedStringKey("str.delete"), isPresented: $showConversionDeleteAlert, actions: {
                    Button(LocalizedStringKey("str.cancel"), role: .cancel) { }
                    Button(LocalizedStringKey("str.delete"), role: .destructive) {
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
                        Text(LocalizedStringKey("str.error.other"))
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
            MDQuantityUnitFormView(isNewQuantityUnit: true, showAddQuantityUnit: Binding.constant(true), toastType: Binding.constant(.successAdd))
            MDQuantityUnitFormView(isNewQuantityUnit: false, quantityUnit: MDQuantityUnit(id: 0, name: "Quantity unit", namePlural: "QU Plural", active: true, mdQuantityUnitDescription: "Description", rowCreatedTimestamp: ""), showAddQuantityUnit: Binding.constant(false), toastType: Binding.constant(.successAdd))
        }
#else
        Group {
            NavigationView {
                MDQuantityUnitFormView(isNewQuantityUnit: true, showAddQuantityUnit: Binding.constant(true), toastType: Binding.constant(.successAdd))
            }
            NavigationView {
                MDQuantityUnitFormView(isNewQuantityUnit: false, quantityUnit: MDQuantityUnit(id: 0, name: "Quantity unit", namePlural: "QU Plural", active: true, mdQuantityUnitDescription: "Description", rowCreatedTimestamp: ""), showAddQuantityUnit: Binding.constant(false), toastType: Binding.constant(.successAdd))
            }
        }
#endif
    }
}
