//
//  StockEntriesView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 01.10.21.
//

import SwiftUI

struct StockEntryRowView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    @Environment(\.colorScheme) var colorScheme
    
    var stockEntry: StockEntry
    var dueType: Int
    var productID: Int
    
    @Binding var stockEntries: StockEntries
    
    
    var backgroundColor: Color {
        if ((0..<(grocyVM.userSettings?.stockDueSoonDays ?? 5 + 1)) ~= getTimeDistanceFromNow(date: stockEntry.bestBeforeDate ?? Date()) ?? 100) {
            return Color(.GrocyColors.grocyYellowBackground)
        }
        if (dueType == 1 ? (getTimeDistanceFromNow(date: stockEntry.bestBeforeDate ?? Date()) ?? 100 < 0) : false) {
            return Color(.GrocyColors.grocyGrayBackground)
        }
        if (dueType == 2 ? (getTimeDistanceFromNow(date: stockEntry.bestBeforeDate ?? Date()) ?? 100 < 0) : false) {
            return Color(.GrocyColors.grocyRedBackground)
        }
        return colorScheme == .light ? Color.white : Color.black
    }
    
    var product: MDProduct? {
        grocyVM.mdProducts.first(where: { $0.id == stockEntry.productID })
    }
    var quantityUnit: MDQuantityUnit? {
        grocyVM.mdQuantityUnits.first(where: { $0.id == product?.quIDStock })
    }
    
    func fetchData(ignoreCachedStock: Bool = true) async {
        // This local management is needed due to the SwiftUI Views not updating correctly.
        if stockEntries.isEmpty || ignoreCachedStock {
            do {
                let productEntriesResult: StockEntries = try await grocyVM.getStockProductInfo(mode: .entries, productID: productID)
                grocyVM.stockProductEntries[productID] = productEntriesResult
                self.stockEntries = productEntriesResult
            } catch {
                grocyVM.grocyLog.error("Data request failed for getting the stock entries. Message: \("\(error)")")
            }
        }
    }
    
    private func consumeEntry() async {
        do {
            try await grocyVM.postStockObject(id: stockEntry.productID, stockModePost: .consume, content: ProductConsume(amount: stockEntry.amount, transactionType: .consume, spoiled: false, stockEntryID: stockEntry.stockID, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil))
            await grocyVM.requestData(additionalObjects: [.stock, .volatileStock])
            await fetchData()
        } catch {
            grocyVM.postLog("Consume stock entry failed. \(error)", type: .error)
        }
    }
    
    private func openEntry() async {
        do {
            try await grocyVM.postStockObject(id: stockEntry.productID, stockModePost: .open, content: ProductOpen(amount: stockEntry.amount, stockEntryID: stockEntry.stockID, allowSubproductSubstitution: nil))
            await grocyVM.requestData(additionalObjects: [.stock, .volatileStock])
            await fetchData()
        } catch {
            grocyVM.postLog("Open stock entry failed. \(error)", type: .error)
        }
    }
    
    var body: some View {
        NavigationLink(destination: {
            StockEntryFormView(stockEntry: stockEntry)
        }, label: {
            VStack(alignment: .leading) {
                Text("Product: \(product?.name ?? "")")
                    .font(.headline)
                
                Text("Amount: \(stockEntry.amount.formattedAmount) \(stockEntry.amount == 1 ? quantityUnit?.name ?? "" : quantityUnit?.namePlural ?? "")")
                +
                Text(" ")
                +
                Text(LocalizedStringKey(stockEntry.stockEntryOpen == true ? "Opened" : ""))
                    .font(.caption)
                    .italic()
                
                if stockEntry.bestBeforeDate == getNeverOverdueDate() {
                    Text("Due date: \("")")
                    +
                    Text("Never overdue")
                        .italic()
                } else {
                    Text("Due date: \(formatDateAsString(stockEntry.bestBeforeDate, localizationKey: localizationKey) ?? "")")
                    +
                    Text(" ")
                    +
                    Text(getRelativeDateAsText(stockEntry.bestBeforeDate, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                }
                
                if let locationID = stockEntry.locationID, let location = grocyVM.mdLocations.first(where: { $0.id == locationID }) {
                    Text("Location: \(location.name)")
                }
                
                if let storeID = stockEntry.storeID, let store = grocyVM.mdStores.first(where: { $0.id == storeID }) {
                    Text("Store: \(store.name)")
                }
                
                if let price = stockEntry.price, price > 0 {
                    Text("Price: \(price.formattedAmount) \(grocyVM.systemConfig?.currency ?? "")")
                }
                
                Text("Purchased date: \(formatDateAsString(stockEntry.purchasedDate, localizationKey: localizationKey) ?? "")")
                +
                Text(" ")
                +
                Text(getRelativeDateAsText(stockEntry.purchasedDate, localizationKey: localizationKey) ?? "")
                    .font(.caption)
                    .italic()
                
                if let note = stockEntry.note {
                    Text("Note: \(note)")
                }
#if os(macOS)
                Button(action: { Task { await openEntry() } }, label: {
                    Label("Mark this stock entry as open", systemImage: MySymbols.open)
                })
                .tint(Color(.GrocyColors.grocyBlue))
                .help("Mark this stock entry as open")
                .disabled(stockEntry.stockEntryOpen)
                Button(action: { Task { await consumeEntry() } }, label: {
                    Label("Consume this stock entry", systemImage: MySymbols.consume)
                })
                .tint(Color(.GrocyColors.grocyDelete))
                .help("Consume this stock entry")
#endif
            }
        })
        .swipeActions(edge: .leading, allowsFullSwipe: true, content: {
            Button(action: { Task { await openEntry() } }, label: {
                Label("Mark this stock entry as open", systemImage: MySymbols.open)
            })
            .tint(Color(.GrocyColors.grocyBlue))
            .help("Mark this stock entry as open")
            .disabled(stockEntry.stockEntryOpen)
        })
        .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
            Button(action: { Task { await consumeEntry() } }, label: {
                Label("Consume this stock entry", systemImage: MySymbols.consume)
            })
            .tint(Color(.GrocyColors.grocyDelete))
            .help("Consume this stock entry")
        })
#if os(macOS)
        .listRowBackground(backgroundColor.clipped().cornerRadius(5))
        .foregroundStyle(colorScheme == .light ? Color.black : Color.white)
        .padding(.horizontal)
#else
        .listRowBackground(backgroundColor)
#endif
    }
}

struct StockEntriesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    var stockElement: StockElement
    
#if os(iOS)
    @Binding var activeSheet: StockInteractionSheet?
#endif
    
    @State private var selectedStockElement: StockElement? = nil
    @State private var stockEntries: StockEntries = []
    
    func fetchData(ignoreCachedStock: Bool = true) async {
        // This local management is needed due to the SwiftUI Views not updating correctly.
        if stockEntries.isEmpty || ignoreCachedStock {
            do {
                let productEntriesResult: StockEntries = try await grocyVM.getStockProductInfo(mode: .entries, productID: stockElement.productID)
                grocyVM.stockProductEntries[stockElement.productID] = productEntriesResult
                self.stockEntries = productEntriesResult
            } catch {
                grocyVM.grocyLog.error("Data request failed for getting the stock entries. Message: \("\(error)")")
            }
        }
    }
    
    var body: some View {
        List {
            if stockEntries.isEmpty {
                Text("No matching records found")
            }
            ForEach(stockEntries, id:\.id) { entry in
                StockEntryRowView(stockEntry: entry, dueType: stockElement.dueType, productID: stockElement.productID, stockEntries: $stockEntries)
            }
        }
#if os(macOS)
        .frame(minWidth: 350)
#endif
        .navigationTitle("Stock entries")
        .refreshable {
            await fetchData(ignoreCachedStock: true)
        }
        .animation(.default, value: stockEntries.count)
        .task {
            Task {
                await fetchData(ignoreCachedStock: false)
            }
        }
    }
}

//struct StockEntriesView_Previews: PreviewProvider {
//    static var previews: some View {
//        StockEntriesView(stockElement: )
//    }
//}
