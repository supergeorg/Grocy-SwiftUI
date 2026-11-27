//
//  PurchaseProductView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.11.20.
//

import SwiftData
import SwiftUI

struct PurchaseProductView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query(filter: #Predicate<MDProduct> { $0.active }, sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(filter: #Predicate<MDQuantityUnit> { $0.active }, sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \MDQuantityUnitConversion.id, order: .forward) var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query(filter: #Predicate<MDStore> { $0.active }, sort: \MDStore.id, order: .forward) var mdStores: MDStores
    @Query(filter: #Predicate<MDLocation> { $0.active }, sort: \MDLocation.id, order: .forward) var mdLocations: MDLocations
    @Query() var detailsList: [StockProductDetails]
    var productDetails: StockProductDetails? {
        return detailsList.first(where: { $0.productID == stockElement?.productID })
    }
    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        userSettingsList.first
    }

    @Environment(\.dismiss) var dismiss
    @Environment(\.grocyFeatures) private var features
    @AppStorage("localizationKey") var localizationKey: String = "en"

    @State private var firstAppear: Bool = true
    @State private var actionPending: Bool = true
    @State private var isProcessingAction: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var stockElement: StockElement? = nil
    var directProductToPurchaseID: Int? = nil
    var productToPurchaseID: Int? {
        return directProductToPurchaseID ?? stockElement?.productID
    }

    var productToPurchaseAmount: Double?
    var autoPurchase: Bool = false
    var barcode: MDProductBarcode? = nil
    var quickScan: Bool = false
    /// The choices of the earlier Quick Scan purchases, used as defaults and updated after a purchase.
    var quickScanSession: QuickScanSession? = nil
    var isPopup: Bool = false
    /// Called after a successful purchase instead of closing the form (used to purchase a whole shopping list).
    var onPurchased: (() -> Void)? = nil

    @State private var productID: Int?
    @State private var amount: Double = 0.0
    @State private var quantityUnitID: Int?
    @State private var dueDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var purchasedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var productDoesntSpoil: Bool = false
    @State private var price: Double?
    @State private var isTotalPrice: Bool = false
    @State private var storeID: Int = -1
    @State private var locationID: Int = -1
    @State private var note: String = ""
    @State private var selfProduction: Bool = false

    private let dataToUpdate: [ObjectEntities] = [.products, .quantity_units, .quantity_unit_conversions, .locations, .shopping_locations, .product_barcodes]
    private let additionalDataToUpdate: [AdditionalEntities] = [.system_config, .system_info]

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    private func finishForm() {
        self.dismiss()
    }

    /// The store is the one of the last Quick Scan purchase.
    private var isStoreFromSession: Bool {
        storeID != -1 && quickScanSession?.purchaseStoreID == storeID
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

    /// The amount in the product's stock unit, which is what Grocy books. Conversions chain and work both ways.
    private var factoredAmount: Double {
        guard let product else { return amount }
        return QuantityUnitConversionResolver(product: product, conversions: mdQuantityUnitConversions).stockAmount(amount, in: quantityUnitID)
    }

    /// How many stock units one selected unit is (1 for the stock unit, 10 for a pack of 10 pieces).
    private var stockAmountPerSelectedUnit: Double {
        guard let product else { return 1 }
        let perUnit = QuantityUnitConversionResolver(product: product, conversions: mdQuantityUnitConversions).stockAmount(1, in: quantityUnitID)
        return perUnit > 0 ? perUnit : 1
    }

    /// The price per stock unit, which is what Grocy stores. A unit price is entered per selected unit, like in Grocy's web form.
    private var unitPrice: Double? {
        if isTotalPrice {
            // No price stays no price (unknown), as in Grocy's web form, instead of a price of 0.
            return price.map { $0 / factoredAmount }
        } else {
            return price.map { $0 / stockAmountPerSelectedUnit }
        }
    }

    /// A price per stock unit (Grocy's last price, a Quick Scan choice) as the price per selected unit, for the price field.
    private func priceInSelectedUnit(_ stockUnitPrice: Double?) -> Double? {
        stockUnitPrice.map { $0 * stockAmountPerSelectedUnit }
    }

    var isFormValid: Bool {
        (productID != nil) && (amount > 0) && (quantityUnitID != nil)
    }

    /// The scanned barcode while it belongs to the selected product: its unit is the default then (#257).
    private var productBarcode: MDProductBarcode? {
        guard actionPending, let barcode, barcode.productID == productID else { return nil }
        return barcode
    }

    /// Grocy's user setting "Show purchased date on purchase and inventory page".
    private var showsPurchasedDate: Bool {
        userSettings?.showPurchasedDateOnPurchase == true
    }

    private func resetForm() {
        self.purchasedDate = Calendar.current.startOfDay(for: Date())
        self.productID = actionPending ? productToPurchaseID : nil
        self.amount =
            actionPending
            ? (productToPurchaseAmount ?? barcode?.amount ?? userSettings?.stockDefaultPurchaseAmount ?? 1.0)
            : (userSettings?.stockDefaultPurchaseAmount ?? 1.0)
        self.quantityUnitID = barcode?.quID ?? (actionPending ? product?.quIDPurchase : nil)
        if product?.defaultDueDays ?? 0 == -1 {
            self.productDoesntSpoil = true
            self.dueDate = Calendar.current.startOfDay(for: Date())
        } else {
            self.productDoesntSpoil = false
            let dateComponents = DateComponents(day: product?.defaultDueDays ?? 0)
            self.dueDate =
                Calendar.current.date(byAdding: dateComponents, to: Calendar.current.startOfDay(for: Date())) ?? Calendar.current.startOfDay(for: Date())
        }
        self.price = actionPending ? priceInSelectedUnit(productDetails?.lastPrice) : nil
        self.isTotalPrice = false
        // Grocy's web form saves the price as entered on the barcode and reads it back as a total price.
        if let barcodePrice = productBarcode?.lastPrice {
            self.price = barcodePrice
            self.isTotalPrice = true
        }
        self.storeID = actionPending ? (barcode?.storeID ?? product?.storeID ?? -1) : -1
        self.locationID = actionPending ? product?.locationID ?? -1 : -1
        self.note = ""
        applyDefaultPurchasePriceType(convertingPrefilledPrice: true)
        if actionPending {
            applyQuickScanSession()
        }
        if autoPurchase, actionPending, product?.defaultDueDays != nil, productID != nil, isFormValid {
            self.price = priceInSelectedUnit(productDetails?.lastPrice)
            self.isTotalPrice = false
            Task {
                await purchaseProduct()
            }
        }
    }

    /// Starts with the product's "Default purchase price type", like Grocy's web form. A scanned barcode's own price keeps its type,
    /// and an automatic purchase keeps the last unit price.
    /// - Parameter convertingPrefilledPrice: The price field holds the prefilled price per unit, which becomes the total for the amount.
    private func applyDefaultPurchasePriceType(convertingPrefilledPrice: Bool = false) {
        guard !autoPurchase, productBarcode?.lastPrice == nil, let type = product?.defaultPurchasePriceType else { return }
        switch type {
        case .unspecified:
            break
        case .unitPrice:
            isTotalPrice = false
        case .totalPrice:
            if !isTotalPrice {
                if convertingPrefilledPrice {
                    price = price.map { $0 * amount }
                }
                isTotalPrice = true
            }
        }
    }

    /// Uses the store of the last Quick Scan purchase, and the location, due date and price of this product's last one.
    private func applyQuickScanSession() {
        guard let quickScanSession else { return }
        if let storeID = quickScanSession.purchaseStoreID, mdStores.contains(where: { $0.id == storeID }) {
            self.storeID = storeID
        }
        guard let productID, let choice = quickScanSession.purchaseChoices[productID] else { return }
        if let locationID = choice.locationID, mdLocations.contains(where: { $0.id == locationID }) {
            self.locationID = locationID
        }
        self.productDoesntSpoil = choice.neverOverdue
        if let dueDate = choice.dueDate {
            self.dueDate = dueDate
        }
        if let unitPrice = choice.unitPrice {
            self.price = priceInSelectedUnit(unitPrice)
            self.isTotalPrice = false
        }
    }

    private func rememberInQuickScanSession() {
        guard let quickScanSession, let productID else { return }
        quickScanSession.rememberPurchase(
            productID: productID,
            storeID: storeID == -1 ? nil : storeID,
            isSelfProduction: selfProduction,
            choice: QuickScanSession.PurchaseChoice(
                locationID: features.locationTracking && locationID != -1 ? locationID : nil,
                dueDate: features.dueDateTracking && !productDoesntSpoil ? dueDate : nil,
                neverOverdue: features.dueDateTracking && productDoesntSpoil,
                unitPrice: selfProduction ? nil : unitPrice
            )
        )
    }

    private func purchaseProduct() async {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        // Without due date tracking, Grocy picks the due date (the product's default due days), like its web frontend.
        let strDueDate: String? = features.dueDateTracking ? (productDoesntSpoil ? "2999-12-31" : dateFormatter.string(from: dueDate)) : nil
        let noteText = note.isEmpty ? nil : note
        let purchasePrice = selfProduction ? nil : unitPrice
        // -1 is the picker's "no store": Grocy would store it as the store's ID.
        let purchaseStoreID = selfProduction || storeID == -1 ? nil : storeID
        let purchaseInfo = ProductBuy(
            amount: factoredAmount,
            bestBeforeDate: strDueDate,
            transactionType: selfProduction ? .selfProduction : .purchase,
            price: purchasePrice,
            // Without location tracking, the product's default location is used.
            locationID: features.locationTracking && locationID != -1 ? locationID : nil,
            storeID: purchaseStoreID,
            note: noteText,
            purchasedDate: showsPurchasedDate ? dateFormatter.string(from: purchasedDate) : nil
        )
        if let productID = productID {
            isProcessingAction = true
            isSuccessful = nil
            do {
                try await grocyVM.postStockObject(id: productID, stockModePost: .add, content: purchaseInfo)
                GrocyLogger.info("Purchase \(product?.name ?? String(productID)) successful.")
                await grocyVM.requestData(additionalObjects: [.stock, .volatileStock])
                isSuccessful = true
                rememberInQuickScanSession()
                if let onPurchased {
                    onPurchased()
                } else if autoPurchase || quickScan || productToPurchaseID != nil {
                    self.finishForm()
                }
                actionPending = false
                resetForm()
            } catch {
                GrocyLogger.error("Purchase failed: \(error)")
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

            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0
                || grocyVM.failedToLoadAdditionalObjects.filter({ additionalDataToUpdate.contains($0) }).count > 0
            {
                Section {
                    ServerProblemView(isCompact: true)
                }
            }

            ProductField(productID: $productID, description: "Product", excludeNoOwnStock: true)
                .disabled(quickScan)
                .onChange(of: productID) {
                    if let selectedProduct = mdProducts.first(where: { $0.id == productID }) {
                        if locationID == -1 { locationID = selectedProduct.locationID }
                        if storeID == -1 { storeID = selectedProduct.storeID ?? -1 }
                        // A scanned barcode's unit wins over the default purchase unit, like its amount does (#257).
                        quantityUnitID = productBarcode?.quID ?? selectedProduct.quIDPurchase
                        if product?.defaultDueDays == -1 {
                            productDoesntSpoil = true
                            dueDate = Calendar.current.startOfDay(for: Date())
                        } else {
                            productDoesntSpoil = false
                            dueDate = Calendar.current.startOfDay(
                                for: Calendar.current.date(byAdding: .day, value: product?.defaultDueDays ?? 0, to: Date()) ?? Date()
                            )
                        }
                        applyDefaultPurchasePriceType()
                        applyQuickScanSession()
                    }
                }

            if productID != nil {
                AmountSelectionView(productID: $productID, amount: $amount, quantityUnitID: $quantityUnitID)

                if showsPurchasedDate {
                    DatePicker(
                        selection: $purchasedDate,
                        displayedComponents: .date,
                        label: {
                            Label("Purchased date", systemImage: MySymbols.purchase)
                                .foregroundStyle(.primary)
                        }
                    )
                }

                if features.dueDateTracking {
                    Section("Due date") {
                        HStack {
                            DatePicker(
                                selection: $dueDate,
                                displayedComponents: .date,
                                label: {
                                    Label {
                                        Text("Due date")
                                        if !productDoesntSpoil {
                                            Text(getRelativeDateAsText(dueDate, localizationKey: localizationKey) ?? "")
                                                .foregroundStyle(.secondary)
                                                .italic()
                                        }
                                    } icon: {
                                        Image(systemName: MySymbols.date)
                                    }
                                }
                            )
                            .foregroundStyle(.primary)
                            DueDateScanner(dueDate: $dueDate)
                        }
                        .disabled(productDoesntSpoil)

                        MyToggle(isOn: $productDoesntSpoil, description: "Never overdue", descriptionInfo: nil, icon: MySymbols.doesntSpoil)
                    }
                }

                if !selfProduction {
                    Section("Price") {
                        VStack(alignment: .leading) {
                            MyDoubleStepperOptional(
                                amount: $price,
                                description: "Price",
                                minAmount: 0,
                                amountStep: 1.0,
                                amountName: "",
                                systemImage: MySymbols.price,
                                currencySymbol: grocyVM.getCurrencySymbol()
                            )

                            if productID != nil, price != nil, isTotalPrice || quantityUnitID != product?.quIDStock {
                                Text("means \(grocyVM.getFormattedCurrency(amount: unitPrice ?? 0)) per \(stockQuantityUnit?.name ?? "")")
                                    .font(.caption)
                                    .foregroundStyle(Color(.GrocyColors.grocyGray))
                            }
                        }

                        if price != nil {
                            Picker(
                                "",
                                selection: $isTotalPrice,
                                content: {
                                    Text("\(currentQuantityUnit?.name ?? "Unit") price")
                                        .tag(false)
                                    Text("Total price")
                                        .tag(true)
                                }
                            )
                            .pickerStyle(.segmented)
                        }
                    }
                }

                Section(features.locationTracking ? LocalizedStringKey("Location") : LocalizedStringKey("Store")) {
                    if !selfProduction {
                        Picker(
                            selection: $storeID,
                            label: Label("Store", systemImage: MySymbols.store).foregroundStyle(.primary),
                            content: {
                                Text("").tag(-1 as Int)
                                ForEach(mdStores, id: \.id) { store in
                                    Text(store.name).tag(store.id as Int)
                                }
                            }
                        )
                        if isStoreFromSession {
                            Text("Store of your last scan")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if features.locationTracking {
                        Picker(
                            selection: $locationID,
                            label: Label("Location", systemImage: MySymbols.location).foregroundStyle(.primary),
                            content: {
                                Text("").tag(-1 as Int)
                                ForEach(mdLocations, id: \.id) { location in
                                    if location.id == product?.locationID {
                                        Text("\(location.name) (\(Text("Default location")))")
                                            .tag(location.id as Int)
                                    } else {
                                        Text(location.name)
                                            .tag(location.id as Int)
                                    }
                                }
                            }
                        )
                    }
                }
                MyTextField(textToEdit: $note, description: "Note", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)

                MyToggle(isOn: $selfProduction, description: "Self-production", icon: MySymbols.selfProduction)
            }
        }
        .navigationTitle("Purchase")
        .disabled(autoPurchase)
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
            if productToPurchaseID == nil {
                ToolbarItem(id: "clear", placement: .clearFormAction) {
                    if !quickScan {
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
                        // Stays in place while the action runs (the confirm button shows the progress), so the bar doesn't change.
                        .disabled(isProcessingAction)
                    }
                }
            }
            #if os(macOS)
                // Apart from the actions, so clearing the form isn't clicked by mistake.
                if productToPurchaseID == nil {
                    ToolbarSpacer(.fixed, placement: .primaryAction)
                }
            #endif
            ToolbarItem(placement: .primaryAction) {
                Button(
                    role: .confirm,
                    action: {
                        Task {
                            await purchaseProduct()
                        }
                    },
                    label: {
                        // While it runs, the icon becomes an animated progress symbol. It stays an image: with a ProgressView as its icon,
                        // the item loses its icon and leaves iPhone Duo's vertical bar for a text-only button at the bottom.
                        Label("Purchase product", systemImage: isProcessingAction ? MySymbols.progress : MySymbols.purchase)
                            .symbolEffect(.variableColor.iterative, isActive: isProcessingAction)
                            .labelStyle(.titleAndIcon)
                    }
                )
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
        PurchaseProductView()
    }
}
