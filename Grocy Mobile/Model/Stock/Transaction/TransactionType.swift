//
//  TransactionType.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.11.20.
//

import Foundation
import SwiftUI

enum TransactionType: String, Codable, CaseIterable {
    case consume = "consume"
    case inventoryCorrection = "inventory-correction"
    case productOpened = "product-opened"
    case purchase = "purchase"
    case selfProduction = "self-production"
    case stockEditNew = "stock-edit-new"
    case stockEditOld = "stock-edit-old"
    case transferFrom = "transfer_from"
    case transferTo = "transfer_to"

    func formatTransactionType() -> String {
        switch self {
        case .consume:
            return "Consume"
        case .inventoryCorrection:
            return "Inventory correction"
        case .productOpened:
            return "Product opened"
        case .purchase:
            return "Purchase"
        case .selfProduction:
            return "Self-production"
        case .stockEditNew:
            return "Stock entry edited (new values)"
        case .stockEditOld:
            return "Stock entry edited (old values)"
        case .transferFrom:
            return "Transfer from"
        case .transferTo:
            return "Transfer to"
        }
    }
}
