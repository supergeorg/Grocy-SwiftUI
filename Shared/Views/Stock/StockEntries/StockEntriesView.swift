//
//  StockEntriesView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 01.10.21.
//

import SwiftUI
import SwiftData

struct StockEntriesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \StockEntry.id, order: .forward) var stockProductEntries: StockEntries
    
    var stockElement: StockElement
    
    @State private var selectedStockElement: StockElement? = nil
    @State private var stockEntries: StockEntries = []
    
    func fetchData(ignoreCachedStock: Bool = false) async {
        // This local management is needed due to the SwiftUI Views not updating correctly.
        if stockEntries.isEmpty || ignoreCachedStock {
            do {
                let productEntriesResult: StockEntries = try await grocyVM.getStockProductInfo(mode: .entries, productID: stockElement.productID)
                self.stockEntries = productEntriesResult
            } catch {
                grocyVM.grocyLog.error("Data request failed for getting the stock entries. Message: \("\(error)")")
            }
        }
    }
    
    private func consumeEntry(stockEntry: StockEntry) async {
        do {
            try await grocyVM.postStockObject(id: stockEntry.productID, stockModePost: .consume, content: ProductConsume(amount: stockEntry.amount, transactionType: .consume, spoiled: false, stockEntryID: stockEntry.stockID, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil))
            await grocyVM.requestData(additionalObjects: [.stock, .volatileStock])
            await fetchData(ignoreCachedStock: false)
        } catch {
            await grocyVM.postLog("Consume stock entry failed. \(error)", type: .error)
        }
    }
    
    private func openEntry(stockEntry: StockEntry) async {
        do {
            try await grocyVM.postStockObject(id: stockEntry.productID, stockModePost: .open, content: ProductOpen(amount: stockEntry.amount, stockEntryID: stockEntry.stockID, allowSubproductSubstitution: nil))
            await grocyVM.requestData(additionalObjects: [.stock, .volatileStock])
            await fetchData(ignoreCachedStock: false)
        } catch {
            await grocyVM.postLog("Open stock entry failed. \(error)", type: .error)
        }
    }
    
    var body: some View {
        List {
            if stockEntries.isEmpty {
                Text("No matching records found")
            }
            ForEach(stockEntries, id:\.id) { stockEntry in
                StockEntryRowView(stockEntry: stockEntry, dueType: stockElement.dueType, productID: stockElement.productID, stockEntries: $stockEntries)
                    .swipeActions(edge: .leading, allowsFullSwipe: true, content: {
                        Button(action: {
                            Task {
                                await openEntry(stockEntry: stockEntry)
                            }
                        }, label: {
                            Label("Mark this stock entry as open", systemImage: MySymbols.open)
                        })
                        .tint(Color(.GrocyColors.grocyBlue))
                        .help("Mark this stock entry as open")
                        .disabled(stockEntry.stockEntryOpen)
                    })
                    .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                        Button(action: {
                            Task {
                                await consumeEntry(stockEntry: stockEntry)
                            }
                        }, label: {
                            Label("Consume this stock entry", systemImage: MySymbols.consume)
                        })
                        .tint(Color(.GrocyColors.grocyDelete))
                        .help("Consume this stock entry")
                    })
            }
        }
#if os(macOS)
        .frame(minWidth: 350)
#endif
        .navigationTitle(stockElement.product?.name ?? "Product")
        .refreshable {
            await fetchData()
        }
        .animation(.default, value: stockEntries.count)
        .task {
            await fetchData()
        }
    }
}

//struct StockEntriesView_Previews: PreviewProvider {
//    static var previews: some View {
//        StockEntriesView(stockElement: )
//    }
//}
