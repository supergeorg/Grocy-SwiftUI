//
//  TransactionType.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.11.20.
//

import Foundation
import SwiftUI

enum TransactionType: String, Codable, CaseIterable {
    case consume
    case inventoryCorrection = "inventory-correction"
    case productOpened = "product-opened"
    case purchase
    case selfProduction = "self-production"
    case stockEditNew = "stock-edit-new"
    case stockEditOld = "stock-edit-old"
    case transferFrom = "transfer_from"
    case transferTo = "transfer_to"

    func formatTransactionType() -> LocalizedStringKey {
        switch self {
        case .consume:
            return "Consume"
        case .inventoryCorrection:
            return "Inventory"
        case .productOpened:
            return "Opened"
        case .purchase:
            return "Purchase"
        case .selfProduction:
            return "Self-production"
        case .stockEditNew:
            return "Stock edit (new)"
        case .stockEditOld:
            return "Stock edit (old)"
        case .transferFrom:
            return "Transfer from"
        case .transferTo:
            return "Transfer to"
        }
    }
}
