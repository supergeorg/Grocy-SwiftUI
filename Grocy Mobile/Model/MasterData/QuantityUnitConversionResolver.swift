//
//  QuantityUnitConversionResolver.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 25.11.26.
//

import Foundation

/// Resolves the quantity unit conversions of one product, like Grocy's `quantity_unit_conversions_resolved` view does on the server.
///
/// - Conversions chain: 1 box = 6 packs and 1 pack = 4 pieces give 1 box = 24 pieces.
/// - Conversions work in both directions: 1 pack = 4 pieces also gives 1 piece = 0.25 packs.
/// - The product's own conversions win over general ones. General conversions are only used when the product's own can't convert.
/// - Conversions of other products are ignored.
/// - The shortest chain wins when there is more than one.
nonisolated struct QuantityUnitConversionResolver {
    /// One conversion: 1 `fromQuID` = `factor` × `toQuID`.
    struct Conversion: Equatable {
        var fromQuID: Int
        var toQuID: Int
        var factor: Double
        var productID: Int?
    }

    let productID: Int?
    let stockQuID: Int

    private let productGraph: [Int: [(to: Int, factor: Double)]]
    private let combinedGraph: [Int: [(to: Int, factor: Double)]]

    init(productID: Int?, stockQuID: Int, conversions: [Conversion]) {
        self.productID = productID
        self.stockQuID = stockQuID
        let productConversions = conversions.filter { productID != nil && $0.productID == productID }
        let generalConversions = conversions.filter { $0.productID == nil }
        productGraph = Self.graph(productConversions)
        // The product's own conversions come first, so they win between chains of the same length.
        combinedGraph = Self.graph(productConversions + generalConversions)
    }

    /// The factor to multiply an amount in `fromQuID` with to get it in `toQuID`, or `nil` when the units can't be converted.
    func factor(from fromQuID: Int, to toQuID: Int) -> Double? {
        if fromQuID == toQuID { return 1 }
        return Self.shortestFactor(from: fromQuID, to: toQuID, in: productGraph) ?? Self.shortestFactor(from: fromQuID, to: toQuID, in: combinedGraph)
    }

    /// The factor to multiply an amount in `quID` with to get it in the product's stock unit, or `nil` when there's no conversion.
    func factorToStock(from quID: Int) -> Double? {
        factor(from: quID, to: stockQuID)
    }

    /// Converts an amount in `quID` to the product's stock unit. Keeps the amount when there's no conversion.
    func stockAmount(_ amount: Double, in quID: Int?) -> Double {
        guard let quID, let factor = factorToStock(from: quID) else { return amount }
        return amount * factor
    }

    /// The units an amount of this product can be entered in: the stock unit first, then every unit that converts to it, in a stable order.
    var convertibleQuIDs: [Int] {
        let units = Set(productGraph.keys).union(combinedGraph.keys).subtracting([stockQuID])
        return [stockQuID] + units.filter { factorToStock(from: $0) != nil }.sorted()
    }

    private static func graph(_ conversions: [Conversion]) -> [Int: [(to: Int, factor: Double)]] {
        var graph: [Int: [(to: Int, factor: Double)]] = [:]
        func add(_ from: Int, _ to: Int, _ factor: Double) {
            guard from != to, factor.isFinite, factor > 0 else { return }
            if graph[from, default: []].contains(where: { $0.to == to }) { return }
            graph[from, default: []].append((to, factor))
        }
        // Grocy stores both directions of a conversion. The inverse is only added where a direction is missing.
        for conversion in conversions {
            add(conversion.fromQuID, conversion.toQuID, conversion.factor)
        }
        for conversion in conversions {
            add(conversion.toQuID, conversion.fromQuID, 1 / conversion.factor)
        }
        return graph
    }

    /// Breadth-first search, so the chain with the fewest steps wins.
    private static func shortestFactor(from: Int, to: Int, in graph: [Int: [(to: Int, factor: Double)]]) -> Double? {
        var factors: [Int: Double] = [from: 1]
        var queue: [Int] = [from]
        var index = 0
        while index < queue.count {
            let unit = queue[index]
            index += 1
            guard let unitFactor = factors[unit] else { continue }
            for edge in graph[unit] ?? [] where factors[edge.to] == nil {
                let factor = unitFactor * edge.factor
                if edge.to == to { return factor }
                factors[edge.to] = factor
                queue.append(edge.to)
            }
        }
        return nil
    }
}

nonisolated extension QuantityUnitConversionResolver {
    /// The resolver for `product`, built from the synced conversions.
    init(product: MDProduct, conversions: MDQuantityUnitConversions) {
        self.init(
            productID: product.id,
            stockQuID: product.quIDStock,
            conversions: conversions.map { Conversion(fromQuID: $0.fromQuID, toQuID: $0.toQuID, factor: $0.factor, productID: $0.productID) }
        )
    }
}
