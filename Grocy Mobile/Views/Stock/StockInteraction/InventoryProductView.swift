//
//  InventoryProductView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 23.11.20.
//

import SwiftData
import SwiftUI

struct InventoryProductView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query(filter: #Predicate<MDProduct> { $0.active }, sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(filter: #Predicate<MDQuantityUnit> { $0.active }, sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \MDQuantityUnitConversion.id, order: .forward) var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query(filter: #Predicate<MDStore> { $0.active }, sort: \MDStore.name, order: .forward) var mdStores: MDStores
    @Query(filter: #Predicate<MDLocation> { $0.active }, sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations
    @Query(sort: \StockElement.productID, order: .forward) var stock: Stock

    @Environment(\.dismiss) var dismiss

    @State private var firstAppear: Bool = true
    @State private var actionPending: Bool = true
    @State private var isProcessingAction: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    @State private var productInventory: ProductInventory = ProductInventory()

    @State private var productID: Int?
    @State private var quantityUnitID: Int?
    @State private var productNeverOverdue: Bool = false

    var stockElement: StockElement? = nil
    var directProductToInventoryID: Int? = nil
    var productToInventoryID: Int? {
        return directProductToInventoryID ?? stockElement?.productID
    }
    var directStockEntryID: String? = nil
    var isPopup: Bool = false

    private let dataToUpdate: [ObjectEntities] = [.products, .shopping_locations, .locations, .quantity_units, .quantity_unit_conversions]
    private let additionalDataToUpdate: [AdditionalEntities] = [.stock, .volatileStock, .system_config, .system_info]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    private func finishForm() {
        self.dismiss()
    }

    private var product: MDProduct? {
        mdProducts.first(where: { $0.id == productID })
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
        } else {
            return []
        }
    }
    private var quConversion: MDQuantityUnitConversion? {
        return quantityUnitConversions.first(where: { $0.fromQuID == quantityUnitID })
    }
    private var factoredAmount: Double {
        return productInventory.newAmount * (quConversion?.factor ?? 1)
    }

    private let priceFormatter = NumberFormatter()

    private var isFormValid: Bool {
        (productID != nil) && (factoredAmount > 0) && (quantityUnitID != nil) && (productInventory.locationID != nil) && factoredAmount != selectedProductStock?.amount
    }

    private var selectedProductStock: StockElement? {
        stock.first(where: { $0.productID == productID })
    }

    private var stockAmountDifference: Double {
        if let stockAmount = selectedProductStock?.amount {
            return factoredAmount - stockAmount
        } else {
            return factoredAmount
        }
    }

    private func resetForm() {
        productID = actionPending ? productToInventoryID : nil
        productInventory = ProductInventory()
        quantityUnitID = nil
        productNeverOverdue = false
    }

    private func inventoryProduct() async {
        if productNeverOverdue {
            productInventory.bestBeforeDate = Date.neverOverdue
        }
        if let productID = productID {
            isProcessingAction = true
            isSuccessful = nil
            do {
                try await grocyVM.postStockObject(id: productID, stockModePost: .inventory, content: productInventory)
                GrocyLogger.info("Inventory successful.")
                await grocyVM.requestData(additionalObjects: [.stock, .volatileStock])
                isSuccessful = true
                if directProductToInventoryID != nil || stockElement != nil {
                    finishForm()
                }
                actionPending = false
                resetForm()
            } catch {
                GrocyLogger.error("Inventory failed: \(error)")
                isSuccessful = false
                if let apiError = error as? APIError {
                    errorMessage = apiError.displayMessage
                } else {
                    errorMessage = error.localizedDescription
                }
            }
            isProcessingAction = false
        }
    }

    var body: some View {
        Form {
            if isSuccessful == false, let errorMessage = errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }

            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 || grocyVM.failedToLoadAdditionalObjects.filter({ additionalDataToUpdate.contains($0) }).count > 0 {
                Section {
                    ServerProblemView(isCompact: true)
                }
            }

            ProductField(productID: $productID, description: "Product")

            if productID != nil {
                Section("Amount") {
                    AmountSelectionView(productID: $productID, amount: $productInventory.newAmount, quantityUnitID: $quantityUnitID)

                    if productID != nil {
                        if stockAmountDifference != 0 {
                            Text(
                                stockAmountDifference > 0
                                    ? "This means \(Text("\(stockAmountDifference.formattedAmount) \(stockQuantityUnit?.getName(amount: factoredAmount) ?? "")")) will be added to stock"
                                    : "This means \(Text("\((-stockAmountDifference).formattedAmount) \(stockQuantityUnit?.getName(amount: factoredAmount) ?? "")")) will be removed from stock"
                            )
                            .font(.caption)
                        } else {
                            Text("The selected amount is equal to the stock amount.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                Section("Due date") {
                    HStack {
                        DatePicker("Due date", selection: $productInventory.bestBeforeDate, displayedComponents: .date)
                        DueDateScanner(dueDate: $productInventory.bestBeforeDate)
                    }
                        .disabled(productNeverOverdue)

                    MyToggle(isOn: $productNeverOverdue, description: "Never overdue", icon: MySymbols.doesntSpoil)
                }

                Section("Price") {
                    MyDoubleStepperOptional(
                        amount: $productInventory.price,
                        description: "Price",
                        descriptionInfo: "Per stock quantity unit",
                        minAmount: 0,
                        amountStep: 1.0,
                        amountName: "",
                        systemImage: MySymbols.price,
                        currencySymbol: grocyVM.getCurrencySymbol()
                    )
                }

                Section("Location") {
                    Picker(
                        selection: $productInventory.storeID,
                        label: Label("Store", systemImage: MySymbols.store).foregroundStyle(.primary),
                        content: {
                            Text("")
                                .tag(nil as Int?)
                            ForEach(mdStores, id: \.id) { store in
                                Text(store.name)
                                    .tag(store.id as Int?)
                            }
                        }
                    )

                    Picker(
                        selection: $productInventory.locationID,
                        label: Label("Location", systemImage: MySymbols.location).foregroundStyle(.primary),
                        content: {
                            Text("")
                                .tag(nil as Int?)
                            ForEach(mdLocations, id: \.id) { location in
                                Text(location.name)
                                    .tag(location.id as Int?)
                            }
                        }
                    )
                }

                Section("Note") {
                    MyTextField(textToEdit: $productInventory.note, description: "Note", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
                }
            }
        }
        .navigationTitle("Inventory")
        .formStyle(.grouped)
        .task {
            if firstAppear {
                await updateData()
                resetForm()
                firstAppear = false
            }
        }
        .onChange(of: productID) {
            if let productID = productID {
                Task {
                    await grocyVM.requestStockInfo(stockModeGet: .entries, productID: productID, queries: ["include_sub_products=true"])
                }
            }
            if let selectedProduct = mdProducts.first(where: { $0.id == productID }) {
                productInventory.storeID = selectedProduct.storeID
                productInventory.locationID = selectedProduct.locationID
                quantityUnitID = selectedProduct.quIDStock
            }
            productInventory.newAmount = selectedProductStock?.amount ?? 1
        }
        .toolbar(content: {
            if isPopup {
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
            if productToInventoryID == nil {
                ToolbarItem(id: "clear", placement: .cancellationAction) {
                    if isProcessingAction {
                        ProgressView().progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Button(
                            action: resetForm,
                            label: {
                                Label("Clear", systemImage: MySymbols.cancel)
                                    .help("Clear")
                            }
                        )
                        .keyboardShortcut("r", modifiers: [.command])
                    }
                }
            }
            ToolbarItem(id: "inventory", placement: .primaryAction) {
                Button(
                    role: .confirm,
                    action: {
                        Task {
                            await inventoryProduct()
                        }
                    },
                    label: {
                        if !isProcessingAction {
                            Label("Perform inventory", systemImage: MySymbols.inventory)
                                .labelStyle(.titleAndIcon)
                        } else {
                            ProgressView().progressViewStyle(.circular)
                        }
                    }
                )
                .labelStyle(.titleAndIcon)
                .fixedSize()
                .disabled(!isFormValid || isProcessingAction)
                .keyboardShortcut("s", modifiers: [.command])
            }
        })
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        InventoryProductView()
    }
}
