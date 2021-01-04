//
//  ProductStatus.swift
//  grocy-ios
//
//  Created by Georg Meissner on 12.11.20.
//

import Foundation
import SwiftUI

enum ProductStatus: String {
    case all = "str.stock.all"
    case expiringSoon = "str.stock.expiringSoon"
    case overdue = "str.stock.overdue"
    case expired = "str.stock.expired"
    case belowMinStock = "str.stock.belowMinStock"
    
    func getDescription(amount: Int, expiringDays: Int? = 5) -> LocalizedStringKey {
        switch self {
        case .all:
            return "no description"
        case .expiringSoon:
            return amount == 1 ? LocalizedStringKey("str.stock.1expiringSoon \(expiringDays ?? 5)") : LocalizedStringKey("str.stock.expiringSoon \(amount) \(expiringDays ?? 5)")
        case .overdue:
            return amount == 1 ? LocalizedStringKey("str.stock.1overdue") : LocalizedStringKey("str.stock.overdue \(amount)")
        case .expired:
            return amount == 1 ? LocalizedStringKey("str.stock.1expired") : LocalizedStringKey("str.stock.expired \(amount)")
        case .belowMinStock:
            return amount == 1 ? LocalizedStringKey("str.stock.1belowMinStock") : LocalizedStringKey("str.stock.belowMinStock \(amount)")
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
