//
//  StockEntriesView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 01.10.21.
//

import SwiftData
import SwiftUI

struct StockEntriesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.grocyFeatures) private var features

    var stockElement: StockElement

    @Query var stockEntries: StockEntries
    /// Only the shown product: all entries here are of it.
    @Query var mdProducts: MDProducts
    var product: MDProduct? {
        mdProducts.first
    }
    @Query var mdQuantityUnits: MDQuantityUnits
    @Query var mdStores: MDStores
    @Query var mdLocations: MDLocations
    @Query var systemConfigList: [SystemConfig]
    var systemConfig: SystemConfig? {
        systemConfigList.first
    }
    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        userSettingsList.first
    }

    init(stockElement: StockElement) {
        self.stockElement = stockElement
        let predicate = #Predicate<StockEntry> { item in
            item.productID == stockElement.productID
        }
        let productID = stockElement.productID
        _mdProducts = Query(filter: #Predicate<MDProduct> { $0.id == productID })
        _stockEntries = Query(
            filter: predicate,
            sort: [SortDescriptor(\StockEntry.bestBeforeDate, order: .forward), SortDescriptor(\StockEntry.purchasedDate, order: .forward)]
        )
    }

    private let dataToUpdate: [ObjectEntities] = [.stock]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func consumeEntry(stockEntry: StockEntry) async {
        do {
            try await grocyVM.postStockObject(
                id: stockEntry.productID,
                stockModePost: .consume,
                content: ProductConsume(
                    amount: product?.quickConsumeAmount ?? stockEntry.amount,
                    transactionType: .consume,
                    spoiled: false,
                    stockEntryID: stockEntry.stockID
                )
            )
            await grocyVM.requestData(additionalObjects: [.stock, .volatileStock])
            await updateData()
        } catch {
            GrocyLogger.error("Consume stock entry failed. \(error)")
        }
    }

    private func openEntry(stockEntry: StockEntry) async {
        do {
            try await grocyVM.postStockObject(
                id: stockEntry.productID,
                stockModePost: .open,
                content: ProductOpen(
                    amount: product?.quickOpenAmount ?? stockEntry.amount,
                    stockEntryID: stockEntry.stockID,
                )
            )
            await grocyVM.requestData(additionalObjects: [.stock, .volatileStock])
            await updateData()
        } catch {
            GrocyLogger.error("Open stock entry failed. \(error)")
        }
    }

    var body: some View {
        // Looked up once for all entries, not per entry.
        let product = self.product
        let quantityUnit = product.flatMap { product in mdQuantityUnits.first(where: { $0.id == product.quIDStock }) }
        let locationsByID = Dictionary(mdLocations.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let storesByID = Dictionary(mdStores.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        List {
            if stockEntries.isEmpty {
                Text("No matching records found")
            }
            ForEach(stockEntries, id: \.id) { stockEntry in
                StockEntryRowView(
                    stockEntry: stockEntry,
                    stockElement: stockElement,
                    product: product,
                    quantityUnit: quantityUnit,
                    location: stockEntry.locationID.flatMap { locationsByID[$0] },
                    store: stockEntry.storeID.flatMap { storesByID[$0] },
                    currency: systemConfig?.currency,
                    userSettings: userSettings
                )
                .swipeActions(
                    edge: .leading,
                    allowsFullSwipe: true,
                    content: {
                        if features.openedTracking {
                            Button(
                                action: {
                                    Task {
                                        await openEntry(stockEntry: stockEntry)
                                    }
                                },
                                label: {
                                    Label("Open", systemImage: MySymbols.open)
                                }
                            )
                            .tint(Color(.GrocyColors.grocyBlue))
                            .help("Mark this stock entry as open")
                            .disabled(stockEntry.stockEntryOpen || product?.disableOpen == true)
                        }
                    }
                )
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: true,
                    content: {
                        Button(
                            action: {
                                Task {
                                    await consumeEntry(stockEntry: stockEntry)
                                }
                            },
                            label: {
                                Label("Consume", systemImage: MySymbols.consume)
                            }
                        )
                        .tint(Color(.GrocyColors.grocyDelete))
                        .help("Consume this stock entry")
                    }
                )
            }
        }
        #if os(macOS)
            .frame(minWidth: Constants.macOSStockEntriesMinWidth)
        #endif
        .navigationTitle(stockElement.product?.name ?? "Product")
        .refreshable {
            await updateData()
        }
        .animation(.default, value: stockEntries.count)
        .task {
            await updateData()
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        StockEntriesView(stockElement: StockElement(product: MDProduct(id: 4)))
    }
}
