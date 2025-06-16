//
//  InventoryProductView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 23.11.20.
//

import SwiftUI
import SwiftData

struct InventoryProductView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(filter: #Predicate<MDProduct>{$0.active}, sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(filter: #Predicate<MDQuantityUnit>{$0.active}, sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \MDQuantityUnitConversion.id, order: .forward) var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query(filter: #Predicate<MDStore>{$0.active}, sort: \MDStore.name, order: .forward) var mdStores: MDStores
    @Query(filter: #Predicate<MDLocation>{$0.active}, sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations
    @Query(sort: \StockElement.productID, order: .forward) var stock: Stock
    
    @Environment(\.dismiss) var dismiss
    
    @State private var isProcessingAction: Bool = false
    @State private var productInventory: ProductInventory
    
    @State private var productID: Int?
    @State private var quantityUnitID: Int?
    @State private var productNeverOverdue: Bool = false
    
    init(stockElement: StockElement? = nil) {
        _productID = State(initialValue: stockElement?.productID)
        let initialProductInventory = ProductInventory(
            newAmount: 1.0,
            bestBeforeDate: Date(),
            storeID: nil,
            locationID: nil,
            price: nil,
            note: ""
        )
        _productInventory = State(initialValue: initialProductInventory)
    }
    
    private let dataToUpdate: [ObjectEntities] = [.products, .shopping_locations, .locations, .quantity_units, .quantity_unit_conversions]
    private let additionalDataToUpdate: [AdditionalEntities] = [.stock, .volatileStock, .system_config, .system_info]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }
    
    private var product: MDProduct? {
        mdProducts.first(where: {$0.id == productID})
    }
    private var currentQuantityUnit: MDQuantityUnit? {
        return mdQuantityUnits.first(where: { $0.id == product?.quIDPurchase })
    }
    private var stockQuantityUnit: MDQuantityUnit? {
        return mdQuantityUnits.first(where: { $0.id == product?.quIDStock })
    }
    private var productName: String {
        product?.name ?? ""
    }
    
    private var quantityUnitConversions: [MDQuantityUnitConversion] {
        if let quIDStock = product?.quIDStock {
            return mdQuantityUnitConversions.filter({ $0.toQuID == quIDStock })
        } else { return [] }
    }
    private var quConversion: MDQuantityUnitConversion? {
        return quantityUnitConversions.first(where: { $0.fromQuID == quantityUnitID})
    }
    private var factoredAmount: Double {
        return productInventory.newAmount * (quConversion?.factor ?? 1)
    }
    
    private let priceFormatter = NumberFormatter()
    
    private var isFormValid: Bool {
        (productID != nil) && (factoredAmount > 0) && (quantityUnitID != nil) && (productInventory.locationID != nil) && factoredAmount != selectedProductStock?.amount
    }
    
    private var selectedProductStock: StockElement? {
        stock.first(where: {$0.productID == productID})
    }
    
    private var stockAmountDifference: Double {
        if let stockAmount = selectedProductStock?.amount {
            return factoredAmount - stockAmount
        } else { return factoredAmount }
    }
    
    private func resetForm() {
        productID = nil
        productInventory = ProductInventory(
            newAmount: 1.0,
            bestBeforeDate: Date(),
            storeID: nil,
            locationID: nil,
            price: nil,
            note: ""
        )
        quantityUnitID = nil
        productNeverOverdue = false
    }
    
    private func inventoryProduct() async {
        if productNeverOverdue {
            productInventory.bestBeforeDate = getNeverOverdueDate()
        }
        if let productID = productID {
            isProcessingAction = true
            do {
                try await grocyVM.postStockObject(id: productID, stockModePost: .inventory, content: productInventory)
                GrocyLogger.info("Inventory successful.")
                await grocyVM.requestData(additionalObjects: [.stock, .volatileStock])
                resetForm()
            } catch {
                GrocyLogger.error("Inventory failed: \(error)")
            }
            isProcessingAction = false
        }
    }
    
    var body: some View {
        Form {
            if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count > 0 || grocyVM.failedToLoadAdditionalObjects.filter({additionalDataToUpdate.contains($0)}).count > 0 {
                Section{
                    ServerProblemView(isCompact: true)
                }
            }
            
            ProductField(productID: $productID, description: "Product")
            
            if productID != nil {
                AmountSelectionView(productID: $productID, amount: $productInventory.newAmount, quantityUnitID: $quantityUnitID)
                
                if productID != nil {
                    if stockAmountDifference != 0 {
                        Text(stockAmountDifference > 0 ? "This means \(stockAmountDifference.formattedAmount) \(stockQuantityUnit?.getName(amount: factoredAmount) ?? "") will be added to stock" : "This means \((-stockAmountDifference).formattedAmount) \(stockQuantityUnit?.getName(amount: factoredAmount) ?? "") will be removed from stock")
                            .font(.caption)
                    } else {
                        Text("The selected amount is equal to the stock amount.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                
                Section("Due date") {
                    DatePicker("Due date", selection: $productInventory.bestBeforeDate, displayedComponents: .date)
                        .disabled(productNeverOverdue)
                    
                    MyToggle(isOn: $productNeverOverdue, description: "Never overdue", icon: MySymbols.doesntSpoil)
                }
                
                Section("Price") {
                    MyDoubleStepperOptional(amount: $productInventory.price, description: "Price", descriptionInfo: "Per stock quantity unit", minAmount: 0, amountStep: 1.0, amountName: "", systemImage: MySymbols.price, currencySymbol: getCurrencySymbol())
                }
                
                Section("Location") {
                    Picker(selection: $productInventory.storeID, label: Label("Store", systemImage: MySymbols.store).foregroundStyle(.primary), content: {
                        Text("")
                            .tag(nil as Int?)
                        ForEach(mdStores, id:\.id) { store in
                            Text(store.name)
                                .tag(store.id as Int?)
                        }
                    })
                    
                    Picker(selection: $productInventory.locationID, label: Label("Location", systemImage: MySymbols.location).foregroundStyle(.primary), content: {
                        Text("")
                            .tag(nil as Int?)
                        ForEach(mdLocations, id:\.id) { location in
                            Text(location.name)
                                .tag(location.id as Int?)
                        }
                    })
                }
                
                Section("Note") {
                    MyTextField(textToEdit: $productInventory.note, description: "Note", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
                }
            }
        }
        .formStyle(.grouped)
        .task {
            await updateData()
        }
        .onChange(of: productID) {
            if let productID = productID {
                Task {
                    try await grocyVM.getStockProductEntries(productID: productID)
                }
            }
            if let selectedProduct = mdProducts.first(where: {$0.id == productID}) {
                productInventory.storeID = selectedProduct.storeID
                productInventory.locationID = selectedProduct.locationID
                quantityUnitID = selectedProduct.quIDStock
            }
            productInventory.newAmount = selectedProductStock?.amount ?? 1
        }
        .toolbar(content: {
            ToolbarItem(id: "clear", placement: .cancellationAction) {
                if isProcessingAction {
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                } else {
                    Button(action: resetForm, label: {
                        Label("Clear", systemImage: MySymbols.cancel)
                            .help("Clear")
                    })
                    .keyboardShortcut("r", modifiers: [.command])
                }
            }
            if #available(iOS 26, macOS 26, *) {
                ToolbarSpacer(.fixed)
            }
            ToolbarItem(id: "inventory", placement: .primaryAction) {
                Button(action: {
                    Task {
                        await inventoryProduct()
                    }
                }, label: {
                    Label("Perform inventory", systemImage: MySymbols.inventory)
                })
                .labelStyle(.titleAndIcon)
                .fixedSize()
                .disabled(!isFormValid || isProcessingAction)
                .keyboardShortcut("s", modifiers: [.command])
            }
        })
        .navigationTitle("Inventory")
    }
}

#Preview {
    InventoryProductView()
}
