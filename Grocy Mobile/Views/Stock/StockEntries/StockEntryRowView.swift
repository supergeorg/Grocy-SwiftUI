//
//  StockEntryRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 22.10.23.
//

import SwiftData
import SwiftUI

struct StockEntryRowView: View {
    @Query var systemConfigList: [SystemConfig]
    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        userSettingsList.first
    }

    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \MDStore.name, order: .forward) var mdStores: MDStores
    @Query(sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations

    @AppStorage("localizationKey") var localizationKey: String = "en"
    @Environment(\.colorScheme) var colorScheme

    var stockEntry: StockEntry
    var dueType: Int
    var productID: Int

    var backgroundColor: Color {
        if (0..<(userSettings?.stockDueSoonDays ?? 5 + 1)) ~= getTimeDistanceFromNow(date: stockEntry.bestBeforeDate) ?? 100 {
            return Color(.GrocyColors.grocyYellowBackground)
        }
        if dueType == 1 ? (getTimeDistanceFromNow(date: stockEntry.bestBeforeDate) ?? 100 < 0) : false {
            return Color(.GrocyColors.grocyGrayBackground)
        }
        if dueType == 2 ? (getTimeDistanceFromNow(date: stockEntry.bestBeforeDate) ?? 100 < 0) : false {
            return Color(.GrocyColors.grocyRedBackground)
        }
        return colorScheme == .light ? Color.white : Color.black
    }

    var product: MDProduct? {
        mdProducts.first(where: { $0.id == stockEntry.productID })
    }
    var quantityUnit: MDQuantityUnit? {
        mdQuantityUnits.first(where: { $0.id == product?.quIDStock })
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

                    if stockEntry.bestBeforeDate == getNeverOverdueDate() {
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

                    if let locationID = stockEntry.locationID, let location = mdLocations.first(where: { $0.id == locationID }) {
                        Text("\(Text("Location")): \(location.name)")
                    }

                    if let storeID = stockEntry.storeID, let store = mdStores.first(where: { $0.id == storeID }) {
                        Text("\(Text("Store")): \(store.name)")
                    }

                    if let price = stockEntry.price, price > 0 {
                        Text("\(Text("Price")): \(price.formattedAmount) \(systemConfigList.first?.currency ?? "")")
                    }

                    HStack(alignment: .bottom) {
                        Text("\(Text("Purchased date")): \(formatDateAsString(stockEntry.purchasedDate, localizationKey: localizationKey) ?? "")")
                        Text(getRelativeDateAsText(stockEntry.purchasedDate, localizationKey: localizationKey) ?? "")
                            .font(.caption).italic()
                    }

                    if let note = stockEntry.note {
                        Text("\(Text("Note")): \(note)")
                    }
                }
            }
        )
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
