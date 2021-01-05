//
//  TransactionType.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

import Foundation
import SwiftUI

enum TransactionType: String, Codable {
    case purchase = "purchase"
    case consume = "consume"
    case inventoryCorrection = "inventory-correction"
    case productOpened = "product-opened"
    case stockEditOld = "stock-edit-old"
    case stockEditNew = "stock-edit-new"
    case transferFrom = "transfer_from"
    case transferTo = "transfer_to"
    
    func formatTransactionType() -> LocalizedStringKey {
        switch self {
        case .consume:
            return LocalizedStringKey("tr.consume")
        case .purchase:
            return LocalizedStringKey("tr.purchase")
        case .inventoryCorrection:
            return LocalizedStringKey("tr.inventory")
        case .productOpened:
            return LocalizedStringKey("tr.opened")
        case .stockEditOld:
            return LocalizedStringKey("tr.editOld")
        case .stockEditNew:
            return LocalizedStringKey("tr.editNew")
        case .transferFrom:
            return LocalizedStringKey("tr.transferFrom")
        case .transferTo:
            return LocalizedStringKey("tr.transferTo")
        }
    }
}
