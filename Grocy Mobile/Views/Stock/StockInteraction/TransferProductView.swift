//
//  TransferProductView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 23.11.20.
//

import SwiftData
import SwiftUI

struct TransferProductView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.grocyFeatures) private var features

    @Query(filter: #Predicate<MDProduct> { $0.active }, sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(filter: #Predicate<MDQuantityUnit> { $0.active }, sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \MDQuantityUnitConversion.id, order: .forward) var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query(filter: #Predicate<MDLocation> { $0.active }, sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations
    @Query var allStockProductEntries: StockEntries
    var stockProductEntries: StockEntries {
        allStockProductEntries.filter({ $0.productID == productID })
    }

    @AppStorage("localizationKey") var localizationKey: String = "en"

    @State private var firstAppear: Bool = true
    @State private var actionPending: Bool = true
    @State private var isProcessingAction: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var stockElement: StockElement? = nil
    var directProductToTransferID: Int? = nil
    var productToTransferID: Int? {
        return directProductToTransferID ?? stockElement?.productID
    }
    var isPopup: Bool = false

    @State private var productID: Int?
    @State private var locationIDFrom: Int?
    @State private var amount: Double = 1.0
    @State private var quantityUnitID: Int?
    @State private var locationIDTo: Int?
    @State private var useSpecificStockEntry: Bool = false
    @State private var stockEntryID: String?

    @State private var searchProductTerm: String = ""
    /// A scanned product Grocycode. A stock entry code preselects that entry and its location, like Grocy's web transfer page.
    @State private var scannedGrocyCode: GrocyCode?

    private let dataToUpdate: [ObjectEntities] = [.products, .locations, .quantity_units, .quantity_unit_conversions]

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
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

    private var locationTo: MDLocation? {
        mdLocations.first(where: { $0.id == locationIDTo })
    }

    /// The amount in the product's stock unit, which is what Grocy books. Conversions chain and work both ways.
    private var factoredAmount: Double {
        guard let product else { return amount }
        return QuantityUnitConversionResolver(product: product, conversions: mdQuantityUnitConversions).stockAmount(amount, in: quantityUnitID)
    }

    private let priceFormatter = NumberFormatter()

    var isFormValid: Bool {
        (productID != nil) && (amount > 0) && (quantityUnitID != nil) && (locationIDFrom != nil) && (locationIDTo != nil)
            && !(useSpecificStockEntry && stockEntryID == nil) && !(useSpecificStockEntry && amount != 1.0)
            && !(locationIDFrom == locationIDTo)
    }

    /// Uses the scanned stock entry Grocycode's entry and its location once the product's entries are loaded.
    private func applyScannedStockEntry() {
        guard let scannedGrocyCode, scannedGrocyCode.entityID == productID, let stockID = scannedGrocyCode.stockID else { return }
        let descriptor = FetchDescriptor<StockEntry>(predicate: #Predicate<StockEntry> { $0.stockID == stockID })
        guard let entry = try? modelContext.fetch(descriptor).first else { return }
        useSpecificStockEntry = true
        stockEntryID = stockID
        if let locationID = entry.locationID {
            locationIDFrom = locationID
        }
    }

    private func resetForm() {
        scannedGrocyCode = nil
        productID = actionPending ? productToTransferID : nil
        locationIDFrom = nil
        amount = 1.0
        quantityUnitID = actionPending ? product?.quIDStock : nil
        locationIDTo = nil
        useSpecificStockEntry = false
        stockEntryID = nil
        searchProductTerm = ""
    }

    private func transferProduct() async {
        if let productID = productID, let locationIDFrom = locationIDFrom, let locationIDTo = locationIDTo {
            let transferInfo = ProductTransfer(amount: factoredAmount, locationIDFrom: locationIDFrom, locationIDTo: locationIDTo, stockEntryID: stockEntryID)
            isProcessingAction = true
            isSuccessful = nil
            do {
                try await grocyVM.postStockObject(id: productID, stockModePost: .transfer, content: transferInfo)
                GrocyLogger.info("Transfer successful.")
                await grocyVM.requestData(additionalObjects: [.stock])
                isSuccessful = true
                if productToTransferID != nil {
                    finishForm()
                }
                actionPending = false
                resetForm()
            } catch {
                GrocyLogger.error("Transfer failed: \(error)")
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

            ProductField(productID: $productID, description: "Product", excludeNoOwnStock: true, scannedGrocyCode: $scannedGrocyCode)
                .onChange(of: productID) {
                    if scannedGrocyCode?.entityID != productID {
                        scannedGrocyCode = nil
                    }
                    Task {
                        if let productID {
                            await grocyVM.requestStockInfo(stockModeGet: .entries, productID: productID, queries: ["include_sub_products=true"])
                        }
                        if let selectedProduct = mdProducts.first(where: { $0.id == productID }) {
                            locationIDFrom = selectedProduct.locationID
                            quantityUnitID = selectedProduct.quIDStock
                        }
                        applyScannedStockEntry()
                    }
                }
                // Scanning another entry of the selected product doesn't change the product.
                .onChange(of: scannedGrocyCode) {
                    guard let productID, scannedGrocyCode?.entityID == productID else { return }
                    Task {
                        await grocyVM.requestStockInfo(stockModeGet: .entries, productID: productID, queries: ["include_sub_products=true"])
                        applyScannedStockEntry()
                    }
                }

            if productID != nil {

                VStack(alignment: .leading) {
                    Picker(
                        selection: $locationIDFrom,
                        label: HStack {
                            Image(systemName: MySymbols.transferFrom)
                                .foregroundStyle(.primary)
                            Text("From location")
                        },
                        content: {
                            Text("").tag(nil as Int?)
                            ForEach(mdLocations, id: \.id) { locationFrom in
                                Text(locationFrom.name).tag(locationFrom.id as Int?)
                            }
                        }
                    )

                    if locationIDFrom == nil {
                        Text("A location is required")
                            .font(.caption)
                            .foregroundStyle(Color(.GrocyColors.grocyRed))
                    }
                }

                AmountSelectionView(productID: $productID, amount: $amount, quantityUnitID: $quantityUnitID)

                VStack(alignment: .leading) {
                    Picker(
                        selection: $locationIDTo,
                        label: HStack {
                            Image(systemName: MySymbols.transferTo)
                                .foregroundStyle(.primary)
                            Text("To location")
                        },
                        content: {
                            Text("").tag(nil as Int?)
                            ForEach(mdLocations, id: \.id) { locationTo in
                                Text(locationTo.name).tag(locationTo.id as Int?)
                            }
                        }
                    )
                    if locationIDTo == nil {
                        Text("A location is required")
                            .font(.caption)
                            .foregroundStyle(Color(.GrocyColors.grocyRed))
                    }
                    if (locationIDFrom != nil) && (locationIDFrom == locationIDTo) {
                        Text("This cannot be the same as the \"From\" location")
                            .font(.caption)
                            .foregroundStyle(Color(.GrocyColors.grocyRed))
                    }
                    if features.freezing, product?.shouldNotBeFrozen == true,
                        locationTo?.isFreezer == true
                    {
                        Text("This product shouldn't be frozen")
                            .font(.caption)
                            .foregroundStyle(Color(.GrocyColors.grocyRed))
                    }
                }

                if productID != nil {
                    MyToggle(
                        isOn: $useSpecificStockEntry,
                        description: "Use a specific stock item",
                        descriptionInfo:
                            "The first item in this list would be picked by the default rule which is \"Opened first, then first due first, then first in first out\"",
                        icon: MySymbols.stockEntry
                    )

                    if useSpecificStockEntry {
                        Picker(
                            selection: $stockEntryID,
                            label: HStack {
                                Image(systemName: MySymbols.stockEntry)
                                    .foregroundStyle(.primary)
                                Text("Stock entry")
                            },
                            content: {
                                Text("").tag(nil as String?)
                                ForEach(stockProductEntries, id: \.stockID) { stockProduct in
                                    VStack(alignment: .leading) {
                                        Text("\(Text("Amount")): \(stockProduct.amount.formatted(.number.precision(.fractionLength(0...4))))")
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
        .navigationTitle("Transfer")
        .formStyle(.grouped)
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
            if productToTransferID == nil {
                ToolbarItem(id: "reset", placement: .cancellationAction) {
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
            ToolbarItem(id: "transfer", placement: .primaryAction) {
                Button(
                    role: .confirm,
                    action: {
                        Task {
                            await transferProduct()
                        }
                    },
                    label: {
                        // While it runs, the icon becomes an animated progress symbol. It stays an image: with a ProgressView as its icon,
                        // the item loses its icon and leaves iPhone Duo's vertical bar for a text-only button at the bottom.
                        Label("Transfer", systemImage: isProcessingAction ? MySymbols.progress : MySymbols.transfer)
                            .symbolEffect(.variableColor.iterative, isActive: isProcessingAction)
                            .labelStyle(.titleAndIcon)
                    }
                )
                .disabled(!isFormValid || isProcessingAction)
                .keyboardShortcut("s", modifiers: [.command])
            }
        })
        .task {
            if firstAppear {
                await updateData()
                resetForm()
                firstAppear = false
            }
        }
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        TransferProductView()
    }
}
