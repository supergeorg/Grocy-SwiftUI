//
//  StockEntryRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 22.10.23.
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
    
    var body: some View {
        NavigationLink(destination: {
            StockEntryFormView(stockEntry: stockEntry)
        }, label: {
            VStack(alignment: .leading) {
                Text("Product: \(product?.name ?? "")")
                    .font(.headline)
                
                Text("Amount: \(stockEntry.amount.formattedAmount) \(quantityUnit?.getName(amount: stockEntry.amount) ?? "")")
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
//#if os(macOS)
//                Button(action: { Task { await openEntry() } }, label: {
//                    Label("Mark this stock entry as open", systemImage: MySymbols.open)
//                })
//                .tint(Color(.GrocyColors.grocyBlue))
//                .help("Mark this stock entry as open")
//                .disabled(stockEntry.stockEntryOpen)
//                Button(action: { Task { await consumeEntry() } }, label: {
//                    Label("Consume this stock entry", systemImage: MySymbols.consume)
//                })
//                .tint(Color(.GrocyColors.grocyDelete))
//                .help("Consume this stock entry")
//#endif
            }
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

//#Preview {
//    StockEntryRowView()
//}
