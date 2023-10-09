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
    case expiringSoon = "str.stock.status.expiringSoon"
    case overdue = "str.stock.status.overdue"
    case expired = "str.stock.status.expired"
    case belowMinStock = "str.stock.status.belowMinStock"

    func getDescription(amount: Int, expiringDays: Int? = 5) -> LocalizedStringKey {
        switch self {
        case .all:
            return "no description"
        case .expiringSoon:
            return LocalizedStringKey("str.stock.info.expiringSoon \(amount) \(expiringDays ?? 5)")
        case .overdue:
            return LocalizedStringKey("str.stock.info.overdue \(amount)")
        case .expired:
            return LocalizedStringKey("str.stock.info.expired \(amount)")
        case .belowMinStock:
            return LocalizedStringKey("str.stock.info.belowMinStock \(amount)")
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
