//
//  GrocyCode.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 04.12.21.
//

import Foundation

/// A Grocycode, Grocy's own code for its objects: `grcy:p:{productID}`, `grcy:p:{productID}:{stockID}` for a stock entry,
/// or `grcy:c:{choreID}`.
nonisolated struct GrocyCode: Equatable, Sendable {
    let entityType: GCEntityType
    let entityID: Int
    let stockID: String?

    enum GCEntityType: Equatable, Sendable {
        case product, battery, chore
    }

    init(entityType: GCEntityType, entityID: Int, stockID: String?) {
        self.entityType = entityType
        self.entityID = entityID
        self.stockID = stockID
    }

    /// Reads a scanned code. Nil when it isn't a product or chore Grocycode.
    init?(string: String) {
        let codeComponents = string.components(separatedBy: ":")
        if codeComponents.count >= 3,
            codeComponents[0] == "grcy",
            codeComponents[1] == "p",
            let productID = Int(codeComponents[2])
        {
            let stockID: String? = codeComponents.count == 4 ? codeComponents[3] : nil
            self.init(entityType: .product, entityID: productID, stockID: stockID)
        } else if codeComponents.count == 3, codeComponents[0] == "grcy", codeComponents[1] == "c", let choreID = Int(codeComponents[2]) {
            self.init(entityType: .chore, entityID: choreID, stockID: nil)
        } else {
            return nil
        }
    }
}
