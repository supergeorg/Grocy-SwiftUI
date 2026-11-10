//
//  StockEntryRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 22.10.23.
//

import SwiftData
import SwiftUI

struct StockEntryRowView: View {
    @AppStorage("localizationKey") var localizationKey: String = "en"
    @Environment(\.colorScheme) var colorScheme

    var stockEntry: StockEntry
    var stockElement: StockElement
    var product: MDProduct?
    var quantityUnit: MDQuantityUnit?
    var location: MDLocation?
    var store: MDStore?
    var currency: String?
    var userSettings: GrocyUserSettings?

    var backgroundColor: Color? {
        if (0..<(userSettings?.stockDueSoonDays ?? 5 + 1)) ~= getTimeDistanceFromNow(date: stockEntry.bestBeforeDate) ?? 100 {
            return Color(.GrocyColors.grocyYellowBackground)
        }
        if stockElement.dueType == .bestBefore ? (getTimeDistanceFromNow(date: stockEntry.bestBeforeDate) ?? 100 < 0) : false {
            return Color(.GrocyColors.grocyGrayBackground)
        }
        if stockElement.dueType == .expires ? (getTimeDistanceFromNow(date: stockEntry.bestBeforeDate) ?? 100 < 0) : false {
            return Color(.GrocyColors.grocyRedBackground)
        }
        return nil
    }

    var body: some View {
        NavigationLink(
            destination: {
                StockEntryFormView(existingStockEntry: stockEntry)
            },
            label: {
                VStack(alignment: .leading) {
                    Text("\(Text("Product")): \(product?.name ?? "")")
                        .font(.headline)

                    Text("\(Text("Amount")): \(stockEntry.amount.formattedAmount) \(quantityUnit?.getName(amount: stockEntry.amount) ?? "") \(Text(stockEntry.stockEntryOpen == true ? "Opened" : ""))")

                    if stockEntry.bestBeforeDate == Date.neverOverdue {
                        HStack(alignment: .bottom) {
                            Text("\(Text("Due date")): ")
                            Text("Never overdue")
                                .italic()
                        }
                    } else {
                        HStack(alignment: .bottom) {
                            Text("\(Text("Due date")): \(formatDateAsString(stockEntry.bestBeforeDate, localizationKey: localizationKey) ?? "")")
                            Text(getRelativeDateAsText(stockEntry.bestBeforeDate, localizationKey: localizationKey) ?? "")
                                .font(.caption).italic()
                        }
                    }

                    if let location {
                        Text("\(Text("Location")): \(location.name)")
                    }

                    if let store {
                        Text("\(Text("Store")): \(store.name)")
                    }

                    if let price = stockEntry.price, price > 0 {
                        Text("\(Text("Price")): \(price.formattedAmount) \(currency ?? "")")
                    }

                    HStack(alignment: .bottom) {
                        Text("\(Text("Purchased date")): \(formatDateAsString(stockEntry.purchasedDate, localizationKey: localizationKey) ?? "")")
                        Text(getRelativeDateAsText(stockEntry.purchasedDate, localizationKey: localizationKey) ?? "")
                            .font(.caption).italic()
                    }

                    if !stockEntry.note.isEmpty {
                        Text("\(Text("Note")): \(stockEntry.note)")
                    }
                }
            }
        )
        .listRowBackground(backgroundColor)
    }
}

//#Preview(traits: .previewData) {
//    Form {
//        StockEntryRowView(stockEntry: StockEntry(), dueType: 1, productID: 2)
//    }
//}
