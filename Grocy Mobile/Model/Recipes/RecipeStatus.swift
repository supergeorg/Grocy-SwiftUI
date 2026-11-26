//
//  RecipeStatus.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 05.02.26.
//

import Foundation
import SwiftUI

enum RecipeStatus: LocalizedStringKey {
    case all = "All"
    case enoughInStock = "Enough in stock"
    case alreadyOnShoppingList = "Not enough in stock, but already on the shopping list"
    case notEnoughInStock = "Not enough in stock"

    func getIconName() -> String {
        switch self {
        case .enoughInStock:
            return MySymbols.fulfilled
        case .alreadyOnShoppingList:
            return MySymbols.partiallyFulfilled
        case .notEnoughInStock:
            return MySymbols.notFulfilled
        default:
            return MySymbols.allEntries
        }
    }
}
