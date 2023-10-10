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
            return "no description"
        case .belowMinStock:
            return amount == 1 ? "1 product is below min. defined stock amount" : "str.shL.filter.info.belowMinStock \(amount)"
        case .done:
            return amount == 1 ? "1 entry is done" : "str.shL.filter.info.done \(amount)"
        case .undone:
            return amount == 1 ? "1 entry is undone" : "str.shL.filter.info.undone \(amount)"
        }
    }
}
