//
//  InventoryProductView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 23.11.20.
//

import SwiftUI

struct InventoryProductView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessingAction: Bool = false
    
    var stockElement: Binding<StockElement?>? = nil
    var productToInventoryID: Int? {
        return stockElement?.wrappedValue?.productID
    }
    var isPopup: Bool = false
    
    @State private var productID: Int?
    @State private var amount: Double = 1.0
    @State private var quantityUnitID: Int?
    @State private var dueDate: Date = Date()
    @State private var productNeverOverdue: Bool = false
    @State private var price: Double?
    @State private var storeID: Int?
    @State private var locationID: Int?
    @State private var note: String = ""
    
    @State private var searchProductTerm: String = ""
    
    private let dataToUpdate: [ObjectEntities] = [.products, .shopping_locations, .locations, .quantity_units, .quantity_unit_conversions]
    private let additionalDataToUpdate: [AdditionalEntities] = [.stock, .volatileStock, .system_config, .system_info]
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }
    
    private var product: MDProduct? {
        grocyVM.mdProducts.first(where: {$0.id == productID})
    }
    private var currentQuantityUnit: MDQuantityUnit? {
        return grocyVM.mdQuantityUnits.first(where: { $0.id == product?.quIDPurchase })
    }
    private var stockQuantityUnit: MDQuantityUnit? {
        return grocyVM.mdQuantityUnits.first(where: { $0.id == product?.quIDStock })
    }
    private func getQUString(stockQU: Bool) -> String {
        if stockQU {
            return factoredAmount == 1.0 ? stockQuantityUnit?.name ?? "" : stockQuantityUnit?.namePlural ?? stockQuantityUnit?.name ?? ""
        } else {
            return amount == 1.0 ? currentQuantityUnit?.name ?? "" : currentQuantityUnit?.namePlural ?? currentQuantityUnit?.name ?? ""
        }
    }
    private var productName: String {
        product?.name ?? ""
    }
    
    private var quantityUnitConversions: [MDQuantityUnitConversion] {
        if let quIDStock = product?.quIDStock {
            return grocyVM.mdQuantityUnitConversions.filter({ $0.toQuID == quIDStock })
        } else { return [] }
    }
    private var quConversion: MDQuantityUnitConversion? {
        return quantityUnitConversions.first(where: { $0.fromQuID == quantityUnitID})
    }
    private var factoredAmount: Double {
        return amount * (quConversion?.factor ?? 1)
    }
    
    private let priceFormatter = NumberFormatter()
    
    private var isFormValid: Bool {
        (productID != nil) && (factoredAmount > 0) && (quantityUnitID != nil) && (locationID != nil) && factoredAmount != selectedProductStock?.amount
    }
    
    private var selectedProductStock: StockElement? {
        grocyVM.stock.first(where: {$0.product.id == productID})
    }
    
    private var stockAmountDifference: Double {
        if let stockAmount = selectedProductStock?.amount {
            return factoredAmount - stockAmount
        } else { return factoredAmount }
    }
    
    private func resetForm() {
        productID = firstAppear ? productToInventoryID : nil
        amount = selectedProductStock?.amount ?? 1.0
        quantityUnitID = firstAppear ? product?.quIDStock : nil
        dueDate = Date()
        productNeverOverdue = false
        price = nil
        storeID = nil
        locationID = nil
        note = ""
        searchProductTerm = ""
    }
    
    private func inventoryProduct() async {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let strDueDate = productNeverOverdue ? "2999-12-31" : dateFormatter.string(from: dueDate)
        let noteText = note.isEmpty ? nil : note
        if let productID = productID {
            let inventoryInfo = ProductInventory(newAmount: factoredAmount, bestBeforeDate: strDueDate, storeID: storeID, locationID: locationID, price: price, note: noteText)
            isProcessingAction = true
            do {
                try await grocyVM.postStockObject(id: productID, stockModePost: .inventory, content: inventoryInfo)
                grocyVM.postLog("Inventory successful.", type: .info)
                await grocyVM.requestData(additionalObjects: [.stock, .volatileStock])
                resetForm()
            } catch {
                grocyVM.postLog("Inventory failed: \(error)", type: .error)
            }
            isProcessingAction = false
        }
    }
    
    var body: some View {
        content
            .formStyle(.grouped)
            .toolbar(content: {
#if os(iOS)
                ToolbarItem(placement: .cancellationAction, content: {
                    Button("Cancel", action: { self.dismiss() })
                })
#endif
            })
    }
    
    var content: some View {
        Form {
            if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count > 0 || grocyVM.failedToLoadAdditionalObjects.filter({additionalDataToUpdate.contains($0)}).count > 0 {
                Section{
                    ServerProblemView(isCompact: true)
                }
            }
            
            ProductField(productID: $productID, description: "Product")
                .onChange(of: productID) {
                    if let productID = productID {
                        Task {
                            try await grocyVM.getStockProductEntries(productID: productID)
                        }
                    }
                    if let selectedProduct = grocyVM.mdProducts.first(where: {$0.id == productID}) {
                        storeID = selectedProduct.storeID
                        locationID = selectedProduct.locationID
                        quantityUnitID = selectedProduct.quIDStock
                    }
                    amount = selectedProductStock?.amount ?? 1
                }
            
            AmountSelectionView(productID: $productID, amount: $amount, quantityUnitID: $quantityUnitID)
            
            if productID != nil {
                if stockAmountDifference != 0 {
                    Text(stockAmountDifference > 0 ? "str.stock.inventory.product.amount.higher \("\(stockAmountDifference.formattedAmount) \(getQUString(stockQU: true))"") : "str.stock.inventory.product.amount.lower \("\((-stockAmountDifference).formattedAmount) \(getQUString(stockQU: true))""))
                        .font(.caption)
                } else {
                    Text("The selected amount is equal to the stock amount.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            Section(header: Text("Due date").font(.headline)) {
                HStack {
                    Image(systemName: MySymbols.date)
                    DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                        .disabled(productNeverOverdue)
                }
                
                MyToggle(isOn: $productNeverOverdue, description: "Never overdue", icon: MySymbols.doesntSpoil)
            }
            
            MyDoubleStepperOptional(amount: $price, description: "Price", descriptionInfo: "Per stock quantity unit", minAmount: 0, amountStep: 1.0, amountName: "", systemImage: MySymbols.price, currencySymbol: grocyVM.getCurrencySymbol())
            
            Section(header: Text("Location").font(.headline)) {
                Picker(selection: $storeID, label: Label("Store", systemImage: MySymbols.store).foregroundStyle(.primary), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdStores.filter({$0.active}), id:\.id) { store in
                        Text(store.name).tag(store.id as Int?)
                    }
                })
                
                Picker(selection: $locationID, label: Label("Location", systemImage: MySymbols.location).foregroundStyle(.primary), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdLocations.filter({$0.active}), id:\.id) { location in
                        Text(location.name).tag(location.id as Int?)
                    }
                })
            }
            MyTextField(textToEdit: $note, description: "Note", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
            
#if os(macOS)
            if isPopup {
                Button(action: { Task { await inventoryProduct() } }, label: {Text("Perform inventory")})
                    .disabled(!isFormValid || isProcessingAction)
                    .keyboardShortcut(.defaultAction)
            }
#endif
        }
        .task {
            if firstAppear {
                await updateData()
                resetForm()
                firstAppear = false
            }
        }
        .toolbar(content: {
            if isProcessingAction {
                ProgressView().progressViewStyle(CircularProgressViewStyle())
            } else {
                Button(action: resetForm, label: {
                    Label("Clear", systemImage: MySymbols.cancel)
                        .help("Clear")
                })
                .keyboardShortcut("r", modifiers: [.command])
            }
            Button(action: {
                Task {
                    await inventoryProduct()
                }
            }, label: {
                Label("Perform inventory", systemImage: MySymbols.inventory)
                    .labelStyle(.titleAndIcon)
            })
            .disabled(!isFormValid || isProcessingAction)
            .keyboardShortcut("s", modifiers: [.command])
        })
        .navigationTitle("Inventory")
    }
}

struct InventoryProductView_Previews: PreviewProvider {
    static var previews: some View {
        InventoryProductView()
    }
}
