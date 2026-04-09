//
//  ConsumeProductView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 23.11.20.
//

import SwiftData
import SwiftUI

struct ConsumeProductView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \MDQuantityUnitConversion.id, order: .forward) var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query(sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations
    @Query var allStockProductEntries: StockEntries
    var stockProductEntries: StockEntries {
        allStockProductEntries.filter({ $0.productID == productID })
    }
    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        userSettingsList.first
    }
    @Query(sort: \Recipe.name) var allRecipes: Recipes
    var recipes: Recipes {
        allRecipes.filter { $0.type == .normal }
    }

    @Environment(\.dismiss) var dismiss

    @AppStorage("localizationKey") var localizationKey: String = "en"
    @AppStorage("devMode") private var devMode: Bool = false

    @State private var firstAppear: Bool = true
    @State private var actionPending: Bool = true
    @State private var isProcessingAction: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var stockElement: StockElement? = nil
    var directProductToConsumeID: Int? = nil
    var productToConsumeID: Int? {
        return directProductToConsumeID ?? stockElement?.productID
    }
    var directStockEntryID: String? = nil

    var barcode: MDProductBarcode? = nil

    enum ConsumeType: Identifiable {
        case both, consume, open

        var id: Int {
            self.hashValue
        }
    }
    var consumeType: ConsumeType = .both
    var quickScan: Bool = false
    var isPopup: Bool = false

    @State private var productID: Int?
    @State private var amount: Double = 1.0
    @State private var quantityUnitID: Int?
    @State private var locationID: Int = -1
    @State private var spoiled: Bool = false
    @State private var useSpecificStockEntry: Bool = false
    @State private var stockEntryID: String?
    @State private var recipeID: Int?

    @State private var searchProductTerm: String = ""

    @State private var showRecipeInfo: Bool = false

    private let dataToUpdate: [ObjectEntities] = [.products, .quantity_units, .quantity_unit_conversions, .locations]
    private let additionalDataToUpdate: [AdditionalEntities] = [.user_settings, .stock]

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
        return mdQuantityUnits.first(where: { $0.id == quantityUnitID })
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
    private var factoredAmount: Double {
        return amount * (quantityUnitConversions.first(where: { $0.fromQuID == quantityUnitID && $0.toQuID == product?.quIDStock })?.factor ?? 1)
    }

    private var maxAmount: Double? {
        var maxAmount: Double = 0
        let filtEntries =
            stockProductEntries
            .filter({ $0.productID == productID })
            .filter({ $0.locationID == locationID })
        for filtEntry in filtEntries {
            maxAmount += filtEntry.amount
        }
        return maxAmount
    }

    private let priceFormatter = NumberFormatter()

    private var isFormValid: Bool {
        return (productID != nil) && (amount > 0) && (quantityUnitID != nil) && (locationID != -1) && !(useSpecificStockEntry && stockEntryID == nil) && !(useSpecificStockEntry && amount != 1.0) && !(amount > maxAmount ?? 0)
    }

    private var stockEntriesForLocation: StockEntries {
        if let productID = productID {
            if locationID != -1 {
                return
                    stockProductEntries
                    .filter({ $0.productID == productID })
                    .filter({ $0.locationID == locationID })
            } else {
                return stockProductEntries.filter({ $0.productID == productID })
            }
        } else {
            return []
        }
    }

    private func getAmountForLocation(lID: Int) -> Double {
        var maxAmount: Double = 0
        let filtEntries = stockProductEntries.filter({ $0.productID == productID }).filter { $0.locationID == lID }
        for filtEntry in filtEntries {
            maxAmount += filtEntry.amount
        }
        return maxAmount
    }

    private func resetForm() {
        productID = actionPending ? productToConsumeID : nil
        amount = (actionPending ? barcode?.amount : nil) ?? userSettings?.stockDefaultConsumeAmount ?? 1.0
        quantityUnitID = actionPending ? product?.quIDStock : nil
        locationID = actionPending ? product?.defaultConsumeLocationID ?? -1 : -1
        spoiled = false
        useSpecificStockEntry = actionPending ? directStockEntryID != nil : false
        stockEntryID = actionPending ? directStockEntryID ?? nil : nil
        recipeID = nil
        searchProductTerm = ""
    }

    private func openProduct() async {
        if let productID = productID {
            let openInfo = ProductOpen(amount: factoredAmount, stockEntryID: stockEntryID, allowSubproductSubstitution: nil)
            isProcessingAction = true
            isSuccessful = nil
            do {
                try await grocyVM.postStockObject(id: productID, stockModePost: .open, content: openInfo)
                GrocyLogger.info("Opening successful.")
                await grocyVM.requestData(additionalObjects: [.stock])
                isSuccessful = true
                if quickScan || productToConsumeID != nil {
                    finishForm()
                }
                actionPending = false
                resetForm()
            } catch {
                GrocyLogger.error("Opening failed: \(error)")
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

    private func consumeProduct() async {
        if let productID = productID {
            let consumeInfo = ProductConsume(amount: factoredAmount, transactionType: .consume, spoiled: spoiled, stockEntryID: stockEntryID, recipeID: recipeID, locationID: locationID, exactAmount: nil, allowSubproductSubstitution: nil)
            isProcessingAction = true
            isSuccessful = nil
            var shlActionSuccessful: Bool = false
            do {
                try await grocyVM.postStockObject(id: productID, stockModePost: .consume, content: consumeInfo)
                GrocyLogger.info("Consume \(amount.formattedAmount) \(productName) successful.")
                if let autoAddBelowMinStock = userSettings?.shoppingListAutoAddBelowMinStockAmount, autoAddBelowMinStock == true, let shlID = userSettings?.shoppingListAutoAddBelowMinStockAmountListID {
                    do {
                        try await grocyVM.shoppingListAction(content: ShoppingListAction(listID: shlID), actionType: .addMissing)
                        GrocyLogger.info("SHLAction successful.")
                        await grocyVM.requestData(objects: [.shopping_list])
                    } catch {
                        GrocyLogger.error("SHLAction failed. \(error)")
                        shlActionSuccessful = false
                        if let apiError = error as? APIError {
                            errorMessage = apiError.displayMessage
                        } else {
                            errorMessage = error.localizedDescription
                        }
                    }
                } else {
                    shlActionSuccessful = true
                }
                isSuccessful = true && shlActionSuccessful
                if quickScan || productToConsumeID != nil {
                    self.dismiss()
                }
                actionPending = false
                resetForm()
            } catch {
                GrocyLogger.error("Consume failed: \(error)")
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
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                Section {
                    ServerProblemView(isCompact: true)
                }
            }

            ProductField(productID: $productID, description: "Product")
                .disabled(quickScan)
                .onChange(of: productID) {
                    if let productID = productID {
                        Task {
                            await grocyVM.requestStockInfo(stockModeGet: .entries, productID: productID, queries: ["include_sub_products=true"])
                        }
                        if let product = product {
                            locationID = product.defaultConsumeLocationID ?? product.locationID
                            quantityUnitID = product.quIDStock
                            amount = userSettings?.stockDefaultConsumeAmountUseQuickConsumeAmount ?? false ? (product.quickConsumeAmount ?? 1.0) : Double(userSettings?.stockDefaultConsumeAmount ?? 1)
                        }
                    }
                }

            if productID != nil {

                AmountSelectionView(productID: $productID, amount: $amount, quantityUnitID: $quantityUnitID)

                Picker(
                    selection: $locationID,
                    label: HStack {
                        Image(systemName: MySymbols.location)
                            .foregroundStyle(.primary)
                        Text("Location")
                    },
                    content: {
                        Text("")
                            .tag(-1 as Int)
                        ForEach(mdLocations, id: \.id) { location in
                            let isDisabled =
                                useSpecificStockEntry
                                && productID != nil
                                && !stockProductEntries.contains(where: {
                                    $0.productID == productID && $0.locationID == location.id
                                })

                            if location.id == product?.defaultConsumeLocationID {
                                Text("\(location.name) (\(getAmountForLocation(lID: location.id).formattedAmount)) (\(Text("Default consume location")))")
                                    .tag(location.id as Int)
                                    .disabled(isDisabled)
                            } else {
                                Text("\(location.name) (\(getAmountForLocation(lID: location.id).formattedAmount))")
                                    .tag(location.id as Int)
                                    .disabled(isDisabled)
                            }
                        }
                    }
                )

                Section("Details") {
                    if (consumeType == .consume) || (consumeType == .both) {
                        MyToggle(isOn: $spoiled, description: "Spoiled", icon: MySymbols.spoiled)
                    }

                    Picker(
                        selection: $recipeID,
                        label: Label {
                            HStack {
                                Text("Recipe")
                                FieldDescription(description: "This is for statistical purposes only")
                            }
                        } icon: {
                            Image(systemName: MySymbols.recipe)
                                .foregroundStyle(.primary)
                        },
                        content: {
                            Text("").tag(nil as Int?)
                            ForEach(recipes, id: \.id) { recipe in
                                Text(recipe.name).tag(recipe.id as Int?)
                            }
                        }
                    )

                    if productID != nil {
                        MyToggle(
                            isOn: $useSpecificStockEntry,
                            description: "Use a specific stock item",
                            descriptionInfo: "The first item in this list would be picked by the default rule which is \"Opened first, then first due first, then first in first out\"",
                            icon: "tag"
                        )
                    }
                }

                if useSpecificStockEntry {
                    Section("Stock entry") {
                        Picker(
                            selection: $stockEntryID,
                            label: Text("Stock entry"),
                            content: {
                                Text("").tag(nil as String?)
                                ForEach(stockEntriesForLocation, id: \.stockID) { stockProduct in
                                    VStack(alignment: .leading) {
                                        Text("\(Text("Amount")): \(stockProduct.amount.formattedAmount); ")
                                        Text("Due on \(formatDateAsString(stockProduct.bestBeforeDate, localizationKey: localizationKey) ?? "?")")
                                        Text(stockProduct.stockEntryOpen == true ? "Opened" : "Not opened")
                                        if !stockProduct.note.isEmpty {
                                            Text("\(Text("Note")): \(stockProduct.note)")
                                        }
                                    }
                                    .tag(stockProduct.stockID as String?)
                                }
                            }
                        )
                        .pickerStyle(.inline)
                    }
                }
            }
        }
        .navigationTitle(consumeType == .open ? "Open" : "Consume")
        .formStyle(.grouped)
        .task {
            if firstAppear {
                await updateData()
                resetForm()
                firstAppear = false
            }
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
            if productToConsumeID == nil {
                ToolbarItem(id: "clear", placement: .cancellationAction) {
                    if !quickScan {
                        if isProcessingAction {
                            ProgressView().progressViewStyle(.circular)
                        } else {
                            Button(
                                action: {
                                    actionPending = false
                                    resetForm()
                                },
                                label: {
                                    Label("Clear", systemImage: MySymbols.cancel)
                                        .help("Clear")
                                }
                            )
                            .keyboardShortcut("r", modifiers: [.command])
                        }
                    }
                }
            }
            if (consumeType == .open) || (consumeType == .both) {
                ToolbarItem(id: "open", placement: .primaryAction) {
                    Button(
                        role: .confirm,
                        action: {
                            Task {
                                await openProduct()
                            }
                        },
                        label: {
                            if !isProcessingAction {
                                Label("Mark as opened", systemImage: MySymbols.open)
                                    .labelStyle(.titleAndIcon)
                            } else {
                                ProgressView().progressViewStyle(.circular)
                            }
                        }
                    )
                    .disabled(!isFormValid || isProcessingAction)
                    .keyboardShortcut("o", modifiers: [.command])
                }
            }
            if (consumeType == .consume) || (consumeType == .both) {
                ToolbarItem(id: "consume", placement: .primaryAction) {
                    Button(
                        role: .confirm,
                        action: {
                            Task {
                                await consumeProduct()
                            }
                        },
                        label: {
                            if !isProcessingAction {
                                Label("Consume product", systemImage: MySymbols.consume)
                                    .labelStyle(.titleAndIcon)
                            } else {
                                ProgressView().progressViewStyle(.circular)
                            }
                        }
                    )
                    .disabled(!isFormValid || isProcessingAction)
                    .keyboardShortcut("s", modifiers: [.command])
                }
            }
        })
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        ConsumeProductView()
    }
}
