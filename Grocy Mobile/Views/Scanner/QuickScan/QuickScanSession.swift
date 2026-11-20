//
//  QuickScanSession.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 20.11.26.
//

import Foundation
import Observation

/// What the user chose in Quick Scan, so the next scans start with it.
///
/// Held by `GrocyViewModel`, so it lasts until the app quits, also when Quick Scan is closed in between:
/// scanning a whole shopping trip keeps the store, and scanning the same product again keeps its location, due date and price.
/// Forgotten with the cached data (logout, server change), because the IDs belong to one server.
@Observable
final class QuickScanSession {
    /// The choices for one product, from its last purchase.
    struct PurchaseChoice: Equatable {
        var locationID: Int?
        var dueDate: Date?
        var neverOverdue: Bool
        var unitPrice: Double?
    }

    /// The store of the last purchase, used for every product. `nil` when nothing is remembered.
    private(set) var purchaseStoreID: Int?
    private(set) var purchaseChoices: [Int: PurchaseChoice] = [:]
    /// The location of the last consume, used when the scanned product is in stock there.
    private(set) var consumeLocationID: Int?

    var isEmpty: Bool {
        purchaseStoreID == nil && purchaseChoices.isEmpty && consumeLocationID == nil
    }

    /// Remembers a purchase. A self-produced purchase has no store and keeps the remembered one.
    func rememberPurchase(productID: Int, storeID: Int?, isSelfProduction: Bool, choice: PurchaseChoice) {
        if !isSelfProduction {
            purchaseStoreID = storeID
        }
        purchaseChoices[productID] = choice
    }

    func rememberConsume(locationID: Int?) {
        consumeLocationID = locationID
    }

    func reset() {
        purchaseStoreID = nil
        purchaseChoices = [:]
        consumeLocationID = nil
    }
}
