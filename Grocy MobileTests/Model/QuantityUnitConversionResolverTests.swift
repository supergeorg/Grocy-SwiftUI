//
//  QuantityUnitConversionResolverTests.swift
//  Grocy MobileTests
//
//  Created by Georg Meißner on 25.11.26.
//

import Foundation
import Testing

@testable import Grocy_Mobile

@Suite("Quantity unit conversion resolver")
@MainActor
struct QuantityUnitConversionResolverTests {
    typealias Conversion = QuantityUnitConversionResolver.Conversion

    let piece = 1
    let pack = 2
    let box = 3
    let liter = 4
    let milliliter = 5

    /// Like Grocy stores them: both directions of every conversion.
    func bothWays(_ from: Int, _ to: Int, _ factor: Double, productID: Int? = nil) -> [Conversion] {
        [
            Conversion(fromQuID: from, toQuID: to, factor: factor, productID: productID),
            Conversion(fromQuID: to, toQuID: from, factor: 1 / factor, productID: productID),
        ]
    }

    var eggs: QuantityUnitConversionResolver {
        QuantityUnitConversionResolver(
            productID: 10,
            stockQuID: piece,
            conversions: bothWays(pack, piece, 4, productID: 10)
                + bothWays(box, pack, 6)
                + bothWays(pack, piece, 10, productID: 99)
                + bothWays(liter, milliliter, 1000)
        )
    }

    @Test("A purchase unit converts to the stock unit (#212, #121, #40)")
    func purchaseUnit() {
        #expect(eggs.factorToStock(from: pack) == 4)
        #expect(eggs.stockAmount(2, in: pack) == 8)
    }

    @Test("Conversions chain")
    func chained() throws {
        #expect(eggs.factorToStock(from: box) == 24)
        let pieceToBox = try #require(eggs.factor(from: piece, to: box))
        #expect(abs(pieceToBox - 1.0 / 24) < 1e-12)
    }

    @Test("Other products' conversions are ignored")
    func otherProducts() {
        #expect(eggs.factorToStock(from: pack) != 10)
        let noProduct = QuantityUnitConversionResolver(productID: nil, stockQuID: piece, conversions: bothWays(pack, piece, 3, productID: 7))
        #expect(noProduct.factorToStock(from: pack) == nil)
    }

    @Test("Units without a path to the stock unit can't be converted")
    func unrelatedUnit() {
        #expect(eggs.factorToStock(from: liter) == nil)
        #expect(eggs.stockAmount(2, in: liter) == 2)
        #expect(eggs.stockAmount(2, in: nil) == 2)
    }

    @Test("Only units that convert are offered, stock unit first and each once (#192)")
    func convertibleUnits() {
        #expect(eggs.convertibleQuIDs == [piece, pack, box])
    }

    @Test("The product's own conversion wins over a general one")
    func productOverride() {
        let resolver = QuantityUnitConversionResolver(
            productID: 1,
            stockQuID: piece,
            conversions: [
                Conversion(fromQuID: pack, toQuID: piece, factor: 8, productID: nil),
                Conversion(fromQuID: pack, toQuID: piece, factor: 5, productID: 1),
            ]
        )
        #expect(resolver.factorToStock(from: pack) == 5)
        // The inverse is added when only one direction is stored.
        #expect(resolver.factor(from: piece, to: pack) == 0.2)
    }

    @Test("A chain of the product's own conversions wins over a shorter general one")
    func productChain() {
        let resolver = QuantityUnitConversionResolver(
            productID: 1,
            stockQuID: piece,
            conversions: bothWays(box, piece, 100) + bothWays(box, pack, 2, productID: 1) + bothWays(pack, piece, 3, productID: 1)
        )
        #expect(resolver.factorToStock(from: box) == 6)
    }

    @Test("Conversions without a valid factor are ignored")
    func invalidFactor() {
        let resolver = QuantityUnitConversionResolver(
            productID: 1,
            stockQuID: piece,
            conversions: [Conversion(fromQuID: pack, toQuID: piece, factor: 0, productID: 1)]
        )
        #expect(resolver.factorToStock(from: pack) == nil)
        #expect(resolver.convertibleQuIDs == [piece])
    }

    @Test("The same unit converts with factor 1")
    func sameUnit() {
        #expect(eggs.factor(from: pack, to: pack) == 1)
        #expect(eggs.factorToStock(from: piece) == 1)
    }

    @Test("Matches Grocy 4.7.1's resolved conversions for a product")
    func matchesServer() {
        // Read from a Grocy 4.7.1 server's `quantity_unit_conversions_resolved` for a product with stock unit 2 (piece) and purchase unit 3 (pack).
        let conversions =
            bothWays(3, 2, 4, productID: 3)  // 1 pack = 4 pieces for this product
            + bothWays(4, 3, 6)  // 1 box = 6 packs
            + bothWays(5, 4, 10)  // 1 crate = 10 boxes
        let resolver = QuantityUnitConversionResolver(productID: 3, stockQuID: 2, conversions: conversions)
        let server: [(from: Int, to: Int, factor: Double)] = [
            (2, 3, 0.25), (3, 2, 4), (4, 2, 24), (4, 3, 6), (5, 2, 240), (5, 3, 60), (5, 4, 10), (2, 5, 1.0 / 240), (3, 4, 1.0 / 6),
        ]
        for row in server {
            let factor = resolver.factor(from: row.from, to: row.to)
            #expect(factor.map { abs($0 - row.factor) < 1e-9 } == true, "\(row.from) → \(row.to)")
        }
    }
}
