//
//  TransactionType.swift
//  Grocy-SwiftUI
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
    
    func formatTransactionType() -> LocalizedStringKey {
        switch self {
        case .consume:
            return LocalizedStringKey("tr.consume")
        case .inventoryCorrection:
            return LocalizedStringKey("tr.inventoryCorrection")
        case .productOpened:
            return LocalizedStringKey("tr.opened")
        case .purchase:
            return LocalizedStringKey("tr.purchase")
        case .selfProduction:
            return LocalizedStringKey("tr.selfProduction")
        case .stockEditNew:
            return LocalizedStringKey("tr.stockEditNew")
        case .stockEditOld:
            return LocalizedStringKey("tr.stockEditOld")
        case .transferFrom:
            return LocalizedStringKey("tr.transferFrom")
        case .transferTo:
            return LocalizedStringKey("tr.transferTo")
        }
    }
}
