//
//  StockEntriesView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 01.10.21.
//

import SwiftUI

struct StockEntryRowView: View {
    let grocyVM: GrocyViewModel = .shared
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    @Environment(\.colorScheme) var colorScheme
    
    var stockEntry: StockEntry
    var dueType: Int
    var fetchData: ()
    
    @Binding var toastType: ToastType?
    
    var backgroundColor: Color {
        if ((0..<(grocyVM.userSettings?.stockDueSoonDays ?? 5 + 1)) ~= getTimeDistanceFromNow(date: stockEntry.bestBeforeDate ?? Date()) ?? 100) {
            return colorScheme == .light ? Color.grocyYellowLight : Color.grocyYellowDark
        }
        if (dueType == 1 ? (getTimeDistanceFromNow(date: stockEntry.bestBeforeDate ?? Date()) ?? 100 < 0) : false) {
            return colorScheme == .light ? Color.grocyGrayLight : Color.grocyGrayDark
        }
        if (dueType == 2 ? (getTimeDistanceFromNow(date: stockEntry.bestBeforeDate ?? Date()) ?? 100 < 0) : false) {
            return colorScheme == .light ? Color.grocyRedLight : Color.grocyRedDark
        }
        return colorScheme == .light ? Color.white : Color.black
    }
    
    var product: MDProduct? {
        grocyVM.mdProducts.first(where: { $0.id == stockEntry.productID })
    }
    var quantityUnit: MDQuantityUnit? {
        grocyVM.mdQuantityUnits.first(where: { $0.id == product?.quIDStock })
    }
    
    private func consumeEntry() async {
        do {
            try await grocyVM.postStockObject(id: stockEntry.productID, stockModePost: .consume, content: ProductConsume(amount: stockEntry.amount, transactionType: .consume, spoiled: false, stockEntryID: stockEntry.stockID, recipeID: nil, locationID: nil, exactAmount: nil, allowSubproductSubstitution: nil))
            await grocyVM.requestData(additionalObjects: [.stock, .volatileStock])
            fetchData
        } catch {
            grocyVM.postLog("Consume stock entry failed. \(error)", type: .error)
            toastType = .failConsume
        }
    }
    
    private func openEntry() async {
        do {
            try await grocyVM.postStockObject(id: stockEntry.productID, stockModePost: .open, content: ProductOpen(amount: stockEntry.amount, stockEntryID: stockEntry.stockID, allowSubproductSubstitution: nil))
            await grocyVM.requestData(additionalObjects: [.stock, .volatileStock])
            fetchData
        } catch {
            grocyVM.postLog("Open stock entry failed. \(error)", type: .error)
            toastType = .failOpen
        }
    }
    
    var body: some View {
        NavigationLink(destination: {
            StockEntryFormView(stockEntry: stockEntry)
        }, label: {
            VStack(alignment: .leading) {
                Text(LocalizedStringKey("str.stock.entries.product \(product?.name ?? "")"))
                    .font(.headline)
                
                Text(LocalizedStringKey("str.stock.entries.amount \("\(stockEntry.amount.formattedAmount) \(stockEntry.amount == 1 ? quantityUnit?.name ?? "" : quantityUnit?.namePlural ?? "")")"))
                +
                Text(" ")
                +
                Text(LocalizedStringKey(stockEntry.stockEntryOpen == true ? "tr.opened" : ""))
                    .font(.caption)
                    .italic()
                
                if stockEntry.bestBeforeDate == getNeverOverdueDate() {
                    Text(LocalizedStringKey("str.stock.entries.dueDate \("")"))
                    +
                    Text(LocalizedStringKey("str.stock.buy.product.doesntSpoil"))
                        .italic()
                } else {
                    Text(LocalizedStringKey("str.stock.entries.dueDate \(formatDateAsString(stockEntry.bestBeforeDate, localizationKey: localizationKey) ?? "")"))
                    +
                    Text(" ")
                    +
                    Text(getRelativeDateAsText(stockEntry.bestBeforeDate, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                }
                
                if let locationID = stockEntry.locationID, let location = grocyVM.mdLocations.first(where: { $0.id == locationID }) {
                    Text(LocalizedStringKey("str.stock.entries.location \(location.name)"))
                }
                
                if let storeID = stockEntry.storeID, let store = grocyVM.mdStores.first(where: { $0.id == storeID }) {
                    Text(LocalizedStringKey("str.stock.entries.store \(store.name)"))
                }
                
                if let price = stockEntry.price, price > 0 {
                    Text(LocalizedStringKey("str.stock.entries.price \("\(price.formattedAmount) \(grocyVM.systemConfig?.currency ?? "")")"))
                }
                
                Text(LocalizedStringKey("str.stock.entries.purchasedDate \(formatDateAsString(stockEntry.purchasedDate, localizationKey: localizationKey) ?? "")"))
                +
                Text(" ")
                +
                Text(getRelativeDateAsText(stockEntry.purchasedDate, localizationKey: localizationKey) ?? "")
                    .font(.caption)
                    .italic()
                
                if let note = stockEntry.note {
                    Text("str.stock.entries.note \(note)")
                }
#if os(macOS)
                Button(action: openEntry, label: {
                    Label(LocalizedStringKey("str.stock.entry.open"), systemImage: MySymbols.open)
                })
                .tint(Color.grocyBlue)
                .help(LocalizedStringKey("str.stock.entry.open"))
                .disabled(stockEntry.stockEntryOpen)
                Button(action: consumeEntry, label: {
                    Label(LocalizedStringKey("str.stock.entry.consume"), systemImage: MySymbols.consume)
                })
                .tint(Color.grocyDelete)
                .help(LocalizedStringKey("str.stock.entry.consume"))
#endif
            }
        })
        .swipeActions(edge: .leading, allowsFullSwipe: true, content: {
            Button(action: { Task { await openEntry() } }, label: {
                Label(LocalizedStringKey("str.stock.entry.open"), systemImage: MySymbols.open)
            })
            .tint(Color.grocyBlue)
            .help(LocalizedStringKey("str.stock.entry.open"))
            .disabled(stockEntry.stockEntryOpen)
        })
        .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
            Button(action: { Task { await consumeEntry() } }, label: {
                Label(LocalizedStringKey("str.stock.entry.consume"), systemImage: MySymbols.consume)
            })
            .tint(Color.grocyDelete)
            .help(LocalizedStringKey("str.stock.entry.consume"))
        })
#if os(macOS)
        .listRowBackground(backgroundColor.clipped().cornerRadius(5))
        .foregroundColor(colorScheme == .light ? Color.black : Color.white)
        .padding(.horizontal)
#else
        .listRowBackground(backgroundColor)
#endif
    }
}

struct StockEntriesView: View {
    let grocyVM: GrocyViewModel = .shared
    
    var stockElement: StockElement
    
#if os(iOS)
    @Binding var activeSheet: StockInteractionSheet?
#elseif os(macOS)
    @Binding var activeSheet: StockInteractionPopover?
#endif
    
    @State private var selectedStockElement: StockElement? = nil
    @State private var stockEntries: StockEntries = []
    @State private var toastType: ToastType?
    
    func fetchData(ignoreCachedStock: Bool = true) {
        Task {
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
    }
    
    var body: some View {
        List {
            if stockEntries.isEmpty {
                Text(LocalizedStringKey("str.stock.entries.empty"))
            }
            ForEach(stockEntries, id:\.id) { entry in
                StockEntryRowView(stockEntry: entry, dueType: stockElement.dueType, fetchData: fetchData(ignoreCachedStock: true), toastType: $toastType)
            }
        }
#if os(macOS)
        .frame(minWidth: 350)
#endif
        .navigationTitle(LocalizedStringKey("str.stock.entries"))
        .refreshable {
            Task {
                fetchData(ignoreCachedStock: true)
            }
        }
        .animation(.default, value: stockEntries.count)
        .onAppear(perform: {
            Task {
                fetchData(ignoreCachedStock: false)
            }
        })
        .toast(
            item: $toastType,
            isSuccess: Binding.constant(toastType != ToastType.failEdit),
            isShown: [.failEdit].contains(toastType),
            text: { item in
                switch item {
                case .failEdit:
                    return LocalizedStringKey("str.failed")
                default:
                    return LocalizedStringKey("")
                }
            })
    }
}

//struct StockEntriesView_Previews: PreviewProvider {
//    static var previews: some View {
//        StockEntriesView(stockElement: )
//    }
//}
