//
//  ShoppingListStatus.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 27.11.20.
//

import Foundation

enum ShoppingListStatus: String {
    case all = "str.shL.filter.all"
    case belowMinStock = "str.shL.filter.belowMinStock"
    case undone = "str.shL.filter.undone"
    
    func getDescription(amount: Int) -> String {
        let amountString = amount > 1 ? "\(amount) \("str.shL.filter.productAmount".localized)" : "str.shL.filter.productAmount1".localized
        switch self {
        case .all:
            return "\(amountString)"
        case .belowMinStock:
            return "\(amountString) \("str.shL.filter.belowMinStock".localized)"
        case .undone:
            return "\(amountString) \("str.shL.filter.undone".localized)"
        }
    }
}
