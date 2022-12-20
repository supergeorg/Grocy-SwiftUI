//
//  Recipe+FulfillmentModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 09.12.22.
//

import Foundation

extension Recipe {
    enum NeedFulfilled: Int {
        case none = 0
        case shoppingList = 1
        case fulfilled = 2
    }
    
    var fulfillment: RecipeFulfilment? {
        GrocyViewModel.shared.recipeFulfillments.first(where: { $0.recipeID == self.id })
    }
    
    var dueScore: Int {
        fulfillment?.dueScore ?? 0
    }
    var needFulfilled: NeedFulfilled {
        if fulfillment?.needFulfilled == 1 {
            return .fulfilled
        } else {
            if fulfillment?.needFulfilledWithShoppingList == 1 {
                return .shoppingList
            } else {
                return .none
            }
        }
    }
}
