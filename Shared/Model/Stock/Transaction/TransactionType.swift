//
//  TransactionType.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

import Foundation

enum TransactionType: String, Codable {
    case purchase = "purchase"
    case consume = "consume"
    case inventoryCorrection = "inventory-correction"
    case productOpened = "product-opened"
    case stockEditOld = "stock-edit-old"
    case stockEditNew = "stock-edit-new"
}
