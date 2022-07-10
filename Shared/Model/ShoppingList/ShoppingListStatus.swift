//
//  ShoppingListStatus.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 27.11.20.
//

import Foundation
import SwiftUI

enum ShoppingListStatus: String {
    case all = "str.shL.filter.all"
    case belowMinStock = "str.shL.filter.belowMinStock"
    case done = "str.shL.filter.done"
    case undone = "str.shL.filter.undone"

    func getDescription(amount: Int) -> LocalizedStringKey {
        switch self {
        case .all:
            return LocalizedStringKey("no description")
        case .belowMinStock:
            return amount == 1 ? LocalizedStringKey("str.shL.filter.info.1belowMinStock") : LocalizedStringKey("str.shL.filter.info.belowMinStock \(amount)")
        case .done:
            return amount == 1 ? LocalizedStringKey("str.shL.filter.info.1done") : LocalizedStringKey("str.shL.filter.info.done \(amount)")
        case .undone:
            return amount == 1 ? LocalizedStringKey("str.shL.filter.info.1undone") : LocalizedStringKey("str.shL.filter.info.undone \(amount)")
        }
    }
}
