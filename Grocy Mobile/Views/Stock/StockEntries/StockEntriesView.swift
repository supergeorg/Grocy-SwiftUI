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

    var stockElement: StockElement

    @Query var stockEntries: StockEntries

    init(stockElement: StockElement) {
        self.stockElement = stockElement
        let predicate = #Predicate<StockEntry> { item in
            item.productID == stockElement.productID
        }
        _stockEntries = Query(filter: predicate, sort: [SortDescriptor(\StockEntry.bestBeforeDate, order: .forward), SortDescriptor(\StockEntry.purchasedDate, order: .forward)])
    }

    private func updateData() async {
        await grocyVM.requestStockInfo(stockModeGet: .entries, productID: stockElement.productID)
    }

    private func consumeEntry(stockEntry: StockEntry) async {
        do {
            try await grocyVM.postStockObject(
                id: stockEntry.productID,
                stockModePost: .consume,
                content: ProductConsume(amount: stockEntry.amount, transactionType: .consume, spoiled: false, stockEntryID: stockEntry.stockID, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil)
            )
            await grocyVM.requestData(additionalObjects: [.stock, .volatileStock])
            await updateData()
        } catch {
            GrocyLogger.error("Consume stock entry failed. \(error)")
        }
    }

    private func openEntry(stockEntry: StockEntry) async {
        do {
            try await grocyVM.postStockObject(id: stockEntry.productID, stockModePost: .open, content: ProductOpen(amount: stockEntry.amount, stockEntryID: stockEntry.stockID, allowSubproductSubstitution: nil))
            await grocyVM.requestData(additionalObjects: [.stock, .volatileStock])
            await updateData()
        } catch {
            GrocyLogger.error("Open stock entry failed. \(error)")
        }
    }

    var body: some View {
        List {
            if stockEntries.isEmpty {
                Text("No matching records found")
            }
            ForEach(stockEntries, id: \.id) { stockEntry in
                StockEntryRowView(stockEntry: stockEntry, dueType: stockElement.dueType, productID: stockElement.productID)
                    .swipeActions(
                        edge: .leading,
                        allowsFullSwipe: true,
                        content: {
                            Button(
                                action: {
                                    Task {
                                        await openEntry(stockEntry: stockEntry)
                                    }
                                },
                                label: {
                                    Label("Mark this stock entry as open", systemImage: MySymbols.open)
                                }
                            )
                            .tint(Color(.GrocyColors.grocyBlue))
                            .help("Mark this stock entry as open")
                            .disabled(stockEntry.stockEntryOpen)
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
                                    Label("Consume this stock entry", systemImage: MySymbols.consume)
                                }
                            )
                            .tint(Color(.GrocyColors.grocyDelete))
                            .help("Consume this stock entry")
                        }
                    )
            }
        }
        #if os(macOS)
            .frame(minWidth: 350)
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

//struct StockEntriesView_Previews: PreviewProvider {
//    static var previews: some View {
//        StockEntriesView(stockElement: )
//    }
//}
