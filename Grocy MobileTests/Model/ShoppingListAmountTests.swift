//
//  ShoppingListAmountTests.swift
//  Grocy MobileTests
//
//  Created by Georg Meißner on 25.11.26.
//

import Foundation
import Testing

@testable import Grocy_Mobile

@Suite("Shopping list amounts")
@MainActor
struct ShoppingListAmountTests {
    // Eggs are stocked in pieces (1) and bought in packs (2): 1 pack = 10 pieces.
    let eggs = MDProduct(id: 1, name: "Eggs", quIDPurchase: 2, quIDStock: 1, quIDConsume: 1, quIDPrice: 2)
    let conversions = [
        MDQuantityUnitConversion(id: 1, fromQuID: 2, toQuID: 1, factor: 10, productID: 1),
        MDQuantityUnitConversion(id: 2, fromQuID: 1, toQuID: 2, factor: 0.1, productID: 1),
    ]

    @Test("The stored stock amount is shown in the item's unit (#114)")
    func showsItemUnit() {
        // Grocy stores 1 pack as 10 pieces, with the pack as the item's unit.
        let item = ShoppingListItem(id: 1, productID: 1, amount: 10, shoppingListID: 1, quID: 2)
        #expect(item.displayAmount(roundUp: false, product: eggs, conversions: conversions) == 1)
        #expect(item.amount(in: 1, product: eggs, conversions: conversions) == 10)
    }

    @Test("Rounding up happens after the conversion")
    func roundsUpConvertedAmount() {
        let item = ShoppingListItem(id: 1, productID: 1, amount: 15, shoppingListID: 1, quID: 2)
        #expect(item.displayAmount(roundUp: false, product: eggs, conversions: conversions) == 1.5)
        #expect(item.displayAmount(roundUp: true, product: eggs, conversions: conversions) == 2)
    }

    @Test("The purchase form gets the amount in the purchase unit")
    func purchaseAmount() {
        let item = ShoppingListItem(id: 1, productID: 1, amount: 20, shoppingListID: 1, quID: 1)
        #expect(item.purchaseAmount(product: eggs, conversions: conversions) == 2)
    }

    @Test("Free-text items and units without a conversion keep the amount")
    func keepsAmount() {
        let note = ShoppingListItem(id: 1, note: "Bread", amount: 3, shoppingListID: 1)
        #expect(note.displayAmount(roundUp: false, product: nil, conversions: conversions) == 3)
        let unknownUnit = ShoppingListItem(id: 2, productID: 1, amount: 3, shoppingListID: 1, quID: 9)
        #expect(unknownUnit.displayAmount(roundUp: false, product: eggs, conversions: conversions) == 3)
    }
}
