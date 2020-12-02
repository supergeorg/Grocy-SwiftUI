//
//  ProductDetailsObject.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 01.12.20.
//

//Text("\("str.details.amount".localized) \(formatAmount(stockEntriesAmount)) \(stockEntriesAmount == 1 ? quantityUnit.name : quantityUnit.namePlural)")
//Text("\("str.details.stockValue".localized): \("")")
//Text("\("str.details.defaultLocation".localized): \(grocyVM.mdLocations.first(where: {$0.id == product.locationID})?.name ?? "Location error")")
//Text("\("str.details.lastPurchaseDate".localized): \(formatDateOutput(stockEntries?.last?.purchasedDate ?? "") ?? "Never")")
//Text("\("str.details.lastUseDate".localized): \(formatDateOutput(lastUsedDate ?? "") ?? "Never")")
//Text("\("str.details.lastPrice".localized): \(stockEntries?.last?.price ?? "No last price")")
//Text("\("str.details.averagePrice".localized): \(String(format: "%.2f", averagePrice)) \(grocyVM.systemConfig?.currency ?? "[Currency]")")
//Text("\("str.details.averageShelfLife".localized): \("")")
//Text("\("str.details.spoilRate".localized): \("")")

import Foundation

class ProductDetailsModel: ObservableObject {
    let grocyVM: GrocyViewModel = .shared
    
    var product: MDProduct
    
    @Published var currency: String
    
    @Published var name: String
    @Published var stockEntriesAmount: Double
    @Published var stockValue: Double
    @Published var defaultLocationName: String
    @Published var lastPurchaseDate: String
    @Published var lastUseDate: String
    @Published var lastPrice: Double
    @Published var averagePrice: Double
    @Published var averageShelfLife: Int?
    //    //    @Published var spoilRate: Double
    @Published var quantityUnit: MDQuantityUnit
    
    init(product: MDProduct) {
        self.product = product
        grocyVM.getStockProductEntries(productID: product.id)
        
        self.currency = grocyVM.systemConfig?.currency ?? "[Currency]"
        
        self.name = product.name
        let stockEntries: StockEntries? =
            grocyVM
            .stockProductEntries[product.id]?
            .sorted(by: { $0.purchasedDate < $1.purchasedDate })
        
        self.defaultLocationName = grocyVM.mdLocations.first(where: {$0.id == product.locationID})?.name ?? "No location"
        
        self.lastPurchaseDate = stockEntries?.last?.purchasedDate ?? "Never"
        
        self.lastUseDate = stockEntries?.sorted(by: {$0.openedDate ?? "" < $1.openedDate ?? ""}).last?.openedDate ?? ""
        
        self.quantityUnit = grocyVM.mdQuantityUnits.first(where: {$0.id == product.quIDStock}) ?? MDQuantityUnit(id: "", name: "Error QU", mdQuantityUnitDescription: nil, rowCreatedTimestamp: "", namePlural: "Error QU", pluralForms: nil, userfields: nil)
        
        var amount: Double = 0
        var numPrice: Double = 0
        var price: Double = 0
        var lastPrice: Double = 0
        var numOpened: Double = 0
        var shelflife: Int = 0
        let calendar = Calendar.current
        if let entries = stockEntries {
            for entry in entries {
                amount += Double(entry.amount)!
                if let entryPrice = Double(entry.price ?? "") {
                    if entryPrice > 0 {
                        numPrice += Double(entry.amount)!
                        price += entryPrice
                        lastPrice = entryPrice
                    }
                }
                if let openDate = entry.openedDate {
                    let date1 = calendar.startOfDay(for: getDateFromString(openDate) ?? Date())
                    let date2 = calendar.startOfDay(for: getDateFromTimestamp(entry.rowCreatedTimestamp) ?? Date())
                    let components = calendar.dateComponents([.day], from: date1, to: date2)
                    if let days = components.day {
                        shelflife += days
                        numOpened += amount
                    }
                }
            }
        }
        self.stockEntriesAmount = amount
        self.stockValue = price
        self.averagePrice = price / numPrice
        self.lastPrice = lastPrice
        self.averageShelfLife = numOpened > 0 ? Int((Double(shelflife) / numOpened).rounded()) : nil
//            Int(Double(shelflife) / numOpened) : nil
    }
}
