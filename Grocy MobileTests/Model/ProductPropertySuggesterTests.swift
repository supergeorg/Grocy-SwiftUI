//
//  ProductPropertySuggesterTests.swift
//  Grocy MobileTests
//
//  Created by Georg Meißner on 17.11.26.
//

import Foundation
import Testing

@testable import Grocy_Mobile

@MainActor
@Suite("Product property suggestions")
struct ProductPropertySuggesterTests {
    private let products: MDProducts = [
        MDProduct(id: 1, name: "Tomate", locationID: 1, quIDPurchase: 1, quIDStock: 1, quIDConsume: 1),
        MDProduct(id: 2, name: "Kirschtomate", locationID: 1, quIDPurchase: 1, quIDStock: 1, quIDConsume: 1),
        MDProduct(id: 3, name: "Milch", locationID: 2, quIDPurchase: 2, quIDStock: 2, quIDConsume: 2),
    ]

    @Test("Products with similar names are the examples")
    func similarProducts() {
        let similar = ProductPropertySuggester.similarProducts(to: "Strauchtomaten", in: products)
        #expect(similar.map(\.id) == [1, 2] || similar.map(\.id) == [2, 1])
        // The product with the same name isn't an example of itself
        #expect(!ProductPropertySuggester.similarProducts(to: "Tomate", in: products).contains { $0.id == 1 })
    }

    @Test("The context has the task, examples and the recipe line")
    func context() {
        let context = ProductPropertySuggester.context(
            task: "Choose the unit.",
            examplesTitle: "Examples",
            examples: ["Tomate: Piece"],
            usage: "1 Paprikaschote"
        )
        #expect(context.contains("Choose the unit."))
        #expect(context.contains("- Tomate: Piece"))
        #expect(context.contains("1 Paprikaschote"))
    }

    @Test("With one option, it's chosen without asking the model")
    func singleOptions() async {
        let suggester = ProductPropertySuggester()
        suggester.start(
            productName: "Paprika",
            locations: [MDLocation(id: 4, name: "Kühlschrank")],
            productGroups: [MDProductGroup(id: 5, name: "Gemüse")],
            quantityUnits: [MDQuantityUnit(id: 6, name: "Stück", namePlural: "Stück")],
            products: products
        )
        for _ in 0..<1000 where suggester.isRunning {
            await Task.yield()
        }
        #expect(suggester.isFinished(for: "Paprika"))
        #expect(suggester.suggestions == ProductPropertySuggestions(locationID: 4, productGroupID: 5, quantityUnitID: 6))
    }

    @Test("Properties that are set, or have nothing to choose from, are skipped")
    func skipping() {
        let suggester = ProductPropertySuggester()
        suggester.start(
            productName: "Paprika",
            locations: [MDLocation(id: 4, name: "Kühlschrank")],
            productGroups: [],
            quantityUnits: [MDQuantityUnit(id: 6, name: "Stück", namePlural: "Stück")],
            products: products,
            skipping: [.location]
        )
        #expect(suggester.steps == [.quantityUnit])
        suggester.stop()

        suggester.start(productName: " ", locations: [MDLocation(id: 4, name: "Kühlschrank")], productGroups: [], quantityUnits: [], products: products)
        #expect(!suggester.isRunning)
    }
}
