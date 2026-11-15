//
//  RecipeAmountConversion.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 14.11.26.
//

import Foundation

/// Grocy stores a recipe ingredient's amount in the product's **stock** unit. The ingredient's `qu_id` is only the unit it's shown in.
/// When "Only check if any amount is in stock" is on, any unit is allowed and the amount is stored as entered (like Grocy's web UI does).
enum RecipeAmountConversion {
    /// The factor to multiply an amount in the stock unit with to get it in `quID`, or `nil` when the units can't be converted.
    static func factorFromStockUnit(to quID: Int, product: MDProduct, conversions: MDQuantityUnitConversions) -> Double? {
        let stockQuID = product.quIDStock
        if quID == stockQuID { return 1 }

        // Product-specific conversions take precedence over general ones
        let productID = product.id
        let productConversions = conversions.filter { $0.productID == productID }
        let generalConversions = conversions.filter { $0.productID == nil }
        let candidates = productConversions + generalConversions
        for conversion in candidates where conversion.factor > 0 {
            // 1 `from` = `factor` × `to`
            if conversion.fromQuID == stockQuID, conversion.toQuID == quID {
                return conversion.factor
            }
            if conversion.fromQuID == quID, conversion.toQuID == stockQuID {
                return 1 / conversion.factor
            }
        }
        return nil
    }

    /// Converts an amount in the unit `quID` to the product's stock unit. Returns `nil` when there's no conversion.
    static func stockAmount(for amount: Double, quID: Int, product: MDProduct, conversions: MDQuantityUnitConversions) -> Double? {
        factorFromStockUnit(to: quID, product: product, conversions: conversions).map { amount / $0 }
    }

    /// The amount to save for an ingredient entered as `amount` in the unit `quID`.
    static func storedAmount(for amount: Double, quID: Int?, onlyCheckSingleUnitInStock: Bool, product: MDProduct?, conversions: MDQuantityUnitConversions) -> Double {
        guard !onlyCheckSingleUnitInStock, let quID, let product else { return amount }
        return stockAmount(for: amount, quID: quID, product: product, conversions: conversions) ?? amount
    }

    /// The amount to show for a saved ingredient, in its unit `quID`.
    static func displayAmount(forStored amount: Double, quID: Int?, onlyCheckSingleUnitInStock: Bool, product: MDProduct?, conversions: MDQuantityUnitConversions) -> Double {
        guard !onlyCheckSingleUnitInStock, let quID, let product,
            let factor = factorFromStockUnit(to: quID, product: product, conversions: conversions)
        else { return amount }
        return amount * factor
    }
}
