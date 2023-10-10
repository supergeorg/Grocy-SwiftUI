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

    func getDescription(amount: Int, expiringDays: Int? = 5) -> String {
        switch self {
        case .all:
            return "no description"
        case .expiringSoon:
            return "\(amount) products are due within the next \(expiringDays ?? 5) days"
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
