//
//  ShoppingListStatus.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 27.11.20.
//

import Foundation
import SwiftUI

enum ShoppingListStatus: String {
    case all = "All"
    case belowMinStock = "Below min. stock amount"
    case done = "Only done items"
    case undone = "Only undone items"

    func getDescription(amount: Int) -> LocalizedStringKey {
        switch self {
        case .all:
            return "No description"
        case .belowMinStock:
            return "\(amount) products are below defined min. stock amount"
        case .done:
            return "\(amount) items are done"
        case .undone:
            return "\(amount) items are undone"
        }
    }
    func getIcon() -> String {
        switch self {
        case .all:
            return "list.bullet"
        case .belowMinStock:
            return "exclamationmark.triangle"
        case .done:
            return "checkmark.circle"
        case .undone:
            return "circle"
        }
    }
}
