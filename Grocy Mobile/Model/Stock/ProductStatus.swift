//
//  ProductStatus.swift
//  grocy-ios
//
//  Created by Georg Meissner on 12.11.20.
//

import Foundation
import SwiftUI

enum ProductStatus: LocalizedStringKey {
    case all = "All"
    case expiringSoon = "Due soon"
    case overdue = "Overdue"
    case expired = "Expired"
    case belowMinStock = "Below min. stock amount"

    func getDescription(amount: Int, dueSoonDays: Int? = 5) -> LocalizedStringKey {
        switch self {
        case .all:
            return "No description"
        case .expiringSoon:
            return "\(amount) products are due within the next \(dueSoonDays ?? 5) days"
        case .overdue:
            return "\(amount) products are overdue"
        case .expired:
            return "\(amount) products are expired"
        case .belowMinStock:
            return "\(amount) products are below min. defined stock amount"
        }
    }

    func getIconName() -> String {
        switch self {
        case .expiringSoon:
            return MySymbols.expiringSoon
        case .overdue:
            return MySymbols.overdue
        case .expired:
            return MySymbols.expired
        case .belowMinStock:
            return MySymbols.belowMinStock
        default:
            return "tag.fill"
        }
    }
}
