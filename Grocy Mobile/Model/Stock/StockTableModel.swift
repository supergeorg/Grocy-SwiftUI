//
//  StockTableModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 11.10.23.
//

import Foundation

struct StockTableElement: Identifiable {
    let id = UUID()
    let product: StockProduct
    let productGroup: MDProductGroup?
    let amount: Double
    let quantityUnit: MDQuantityUnit?
    let value: Double
    let nextDueDate: Date?
    let caloriesPerStockQU: Double?
    let calories: Double
    let lastPurchasedDate: Date?
    let lastPrice: Double?
    let minStockAmount: Double
    let productDescription: String
    let parentProduct: MDProduct?
    let defaultLocation: MDLocation?
    let averagePrice: Double?
}
