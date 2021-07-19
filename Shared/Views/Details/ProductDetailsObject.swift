//
//  ProductDetailsObject.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 01.12.20.
//

import Foundation

class ProductDetailsModel: ObservableObject {
    let grocyVM: GrocyViewModel = .shared
    
    var product: MDProduct?
    
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
    @Published var pictureURL: String?
    
    init(product: MDProduct?) {
        if let product = product {
            self.product = product
            grocyVM.getStockProductEntries(productID: product.id)
            
            self.currency = grocyVM.systemConfig?.currency ?? "[Currency]"
            
            self.name = product.name
            let stockEntries: StockEntries? =
                grocyVM
                .stockProductEntries[product.id]?
                .sorted(by: { $0.purchasedDate ?? "" < $1.purchasedDate ?? "" })
            
            self.defaultLocationName = grocyVM.mdLocations.first(where: {$0.id == product.locationID})?.name ?? "No location"
            
            self.lastPurchaseDate = stockEntries?.last?.purchasedDate ?? "Never"
            
            self.lastUseDate = stockEntries?.sorted(by: {$0.openedDate ?? "" < $1.openedDate ?? ""}).last?.openedDate ?? ""
            
            self.quantityUnit = grocyVM.mdQuantityUnits.first(where: {$0.id == product.quIDStock}) ?? MDQuantityUnit(id: 0, name: "Error QU", mdQuantityUnitDescription: nil, rowCreatedTimestamp: "", namePlural: "Error QU", pluralForms: nil)
            
            if let pictureFileName = product.pictureFileName {
                let utf8str = pictureFileName.data(using: .utf8)
                if let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
                    self.pictureURL = grocyVM.getPictureURL(groupName: "productpictures", fileName: base64Encoded)
                }
            }
            
            var amount: Double = 0
            var numPrice: Double = 0
            var price: Double = 0
            var lastPrice: Double = 0
            var numOpened: Double = 0
            var shelflife: Int = 0
            let calendar = Calendar.current
            if let entries = stockEntries {
                for entry in entries {
                    amount += entry.amount
                    if let entryPrice = entry.price {
                        if entryPrice > 0 {
                            numPrice += entry.amount
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
        } else {
            self.currency = ""
            self.name = ""
            self.stockEntriesAmount = 0.0
            self.stockValue = 0.0
            self.defaultLocationName = ""
            self.lastPurchaseDate = ""
            self.lastUseDate = ""
            self.lastPrice = 0.0
            self.averagePrice = 0.0
            self.averageShelfLife = nil
            self.quantityUnit = MDQuantityUnit(id: 0, name: "", mdQuantityUnitDescription: nil, rowCreatedTimestamp: "", namePlural: "", pluralForms: nil)
            self.pictureURL = nil
        }
    }
}
