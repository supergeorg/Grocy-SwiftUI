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

    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \MDQuantityUnitConversion.id, order: .forward) var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query(sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations
//    @Query(sort: \StockEntry.id, order: .forward) var stockProductEntries: StockEntries
    var stockProductEntries: StockEntries {
        if let productID = productID {
            return grocyVM.stockProductEntries[productID] ?? []
        } else {
            return []
        }
    }
    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        userSettingsList.first
    }

    @Environment(\.dismiss) var dismiss

    @AppStorage("localizationKey") var localizationKey: String = "en"
    @AppStorage("devMode") private var devMode: Bool = false

    @State private var firstAppear: Bool = true
    @State private var isProcessingAction: Bool = false

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
    var actionFinished: Binding<Bool>? = nil

    @State private var productID: Int?
    @State private var amount: Double = 1.0
    @State private var quantityUnitID: Int?
    @State private var locationID: Int?
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
        return amount * (quantityUnitConversions.first(where: { $0.fromQuID == quantityUnitID })?.factor ?? 1)
    }

    private var filteredLocations: MDLocations {
        if let productID = productID {
            return mdLocations.filter { location in
                stockProductEntries.contains(where: { 
                    $0.productID == productID && $0.locationID == location.id
                })
            }
        } else {
            return mdLocations
        }
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
        return (productID != nil) && (amount > 0) && (quantityUnitID != nil) && (locationID != nil) && !(useSpecificStockEntry && stockEntryID == nil) && !(useSpecificStockEntry && amount != 1.0) && !(amount > maxAmount ?? 0)
    }

    private var stockEntriesForLocation: StockEntries {
        if let productID = productID {
            if let locationID = locationID {
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
        productID = firstAppear ? productToConsumeID : nil
        amount = barcode?.amount ?? userSettings?.stockDefaultConsumeAmount ?? 1.0
        quantityUnitID = firstAppear ? product?.quIDStock : nil
        locationID = nil
        spoiled = false
        useSpecificStockEntry = false
        stockEntryID = nil
        recipeID = nil
        searchProductTerm = ""
    }

    private func openProduct() async {
        if let productID = productID {
            let openInfo = ProductOpen(amount: factoredAmount, stockEntryID: stockEntryID, allowSubproductSubstitution: nil)
            isProcessingAction = true
            do {
                try await grocyVM.postStockObject(id: productID, stockModePost: .open, content: openInfo)
                GrocyLogger.info("Opening successful.")
                await grocyVM.requestData(additionalObjects: [.stock])
                resetForm()
                if quickScan == true {
                    self.dismiss()
                }
            } catch {
                GrocyLogger.error("Opening failed: \(error)")
            }
            isProcessingAction = false
        }
    }

    private func consumeProduct() async {
        if let productID = productID {
            let consumeInfo = ProductConsume(amount: factoredAmount, transactionType: .consume, spoiled: spoiled, stockEntryID: stockEntryID, recipeID: recipeID, locationID: locationID, exactAmount: nil, allowSubproductSubstitution: nil)
            isProcessingAction = true
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
                    }
                }
                resetForm()
                if self.actionFinished != nil {
                    self.actionFinished?.wrappedValue = true
                }
            } catch {
                GrocyLogger.error("Consume failed: \(error)")
            }
            isProcessingAction = false
        }
    }

    var body: some View {
        Form {
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
                            try await grocyVM.getStockProductEntries(productID: productID)
                        }
                        if let product = product {
                            locationID = product.locationID
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
                            .tag(nil as Int?)
                        ForEach(filteredLocations, id: \.id) { location in
                            Text(product?.locationID == location.id ? "\(location.name) (\(Text("Default location")))" : "\(location.name) (\(getAmountForLocation(lID: location.id).formattedAmount))")
                                .tag(location.id as Int?)
                        }
                    }
                )

                Section("Details") {
                    if (consumeType == .consume) || (consumeType == .both) {
                        MyToggle(isOn: $spoiled, description: "Spoiled", icon: MySymbols.spoiled)
                    }

                    if devMode {
                        HStack {
                            Picker(
                                selection: $recipeID,
                                label: Label("Recipe", systemImage: "tag"),
                                content: {
                                    Text("Not implemented").tag(nil as Int?)
                                }
                            )
                            #if os(macOS)
                                Image(systemName: "questionmark.circle.fill")
                                    .help("This is for statistical purposes only")
                            #elseif os(iOS)
                                Image(systemName: "questionmark.circle.fill")
                                    .onTapGesture {
                                        showRecipeInfo.toggle()
                                    }
                                    .help("This is for statistical purposes only")
                                    .popover(
                                        isPresented: $showRecipeInfo,
                                        content: {
                                            Text("This is for statistical purposes only")
                                                .padding()
                                        }
                                    )
                            #endif
                        }
                    }

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
                                        if stockProduct.note != nil {
                                            Text("\(Text("Note")): \(stockProduct.note ?? "")")
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
            if directProductToConsumeID == nil {
                ToolbarItem(id: "clear", placement: .cancellationAction) {
                    if !quickScan {
                        if isProcessingAction {
                            ProgressView().progressViewStyle(.circular)
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
            } else {
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
                            Label("Mark as opened", systemImage: MySymbols.open)
                                .labelStyle(.titleAndIcon)
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
                            Label("Consume product", systemImage: MySymbols.consume)
                                .labelStyle(.titleAndIcon)
                        }
                    )
                    .disabled(!isFormValid || isProcessingAction)
                    .keyboardShortcut("s", modifiers: [.command])
                }
            }
        })
    }
}

#Preview {
    ConsumeProductView()
}
