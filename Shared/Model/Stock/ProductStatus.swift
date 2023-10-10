//
//  ProductStatus.swift
//  grocy-ios
//
//  Created by Georg Meissner on 12.11.20.
//

import Foundation
import SwiftUI

enum ProductStatus: String {
    case all = "All"
    case expiringSoon = "Due soon"
    case overdue = "Overdue"
    case expired = "Expired"
    case belowMinStock = "Below min. stock amount"

    func getDescription(amount: Int, expiringDays: Int? = 5) -> LocalizedStringKey {
        switch self {
        case .all:
            return "no description"
        case .expiringSoon:
            return "str.stock.info.expiringSoon \(amount) \(expiringDays ?? 5)"
        case .overdue:
            return "str.stock.info.overdue \(amount)"
        case .expired:
            return "str.stock.info.expired \(amount)"
        case .belowMinStock:
            return "str.stock.info.belowMinStock \(amount)"
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
