//
//  ProductStatus.swift
//  grocy-ios
//
//  Created by Georg Meissner on 12.11.20.
//

import Foundation

enum ProductStatus: String {
    case all = "str.stock.all"
    case expiringSoon = "str.stock.expiringSoon"
    case overdue = "str.stock.overdue"
    case expired = "str.stock.expired"
    case belowMinStock = "str.stock.belowMinStock"
    
    func getDescription(amount: Int) -> String {
        let amountString = amount > 1 ? "\(amount) \("str.stock.productAmount".localized)" : "str.stock.productAmount1".localized
        //        let amountString = amount > 1 ? "str.stock.productAmount \(amount)".localized : "str.stock.productAmount1".localized
        switch self {
        case .all:
            return "\(amountString)"
        case .expiringSoon:
            return "\(amountString) \("str.stock.expiringSoon".localized)"
        case .overdue:
            return "\(amountString) \("str.stock.overdue".localized)"
        case .expired:
            return "\(amountString) \("str.stock.expired".localized)"
        case .belowMinStock:
            return "\(amountString) \("str.stock.belowMinStock".localized)"
        }
    }
    
    func getIconName() -> String {
        switch self {
        case .expiringSoon:
            return "clock.fill"
        case .overdue, .expired:
            return "xmark.circle.fill"
        case .belowMinStock:
            return "exclamationmark.circle.fill"
        default:
            return "tag.fill"
        }
    }
}
