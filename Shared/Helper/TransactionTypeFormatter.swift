//
//  TransactionTypeFormatter.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 23.11.20.
//

import Foundation

func formatTransactionType(_ transactionType: TransactionType) -> String {
    switch transactionType {
    case .consume:
        return "tr.consume".localized
    case .purchase:
        return "tr.purchase".localized
    case .inventoryCorrection:
        return "tr.inventory".localized
    case .productOpened:
        return "tr.opened".localized
    case .stockEditOld:
        return "tr.editOld".localized
    case .stockEditNew:
        return "tr.editNew".localized
    }
}
