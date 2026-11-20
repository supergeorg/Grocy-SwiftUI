//
//  QuickScanSessionTests.swift
//  Grocy MobileTests
//
//  Created by Georg Meißner on 20.11.26.
//

import Foundation
import Testing

@testable import Grocy_Mobile

@MainActor
@Suite("Quick Scan remembers the last choices")
struct QuickScanSessionTests {
    private let choice = QuickScanSession.PurchaseChoice(locationID: 2, dueDate: Date(timeIntervalSince1970: 0), neverOverdue: false, unitPrice: 1.5)

    @Test("A purchase remembers the store for all products and the rest for its product")
    func purchase() {
        let session = QuickScanSession()
        #expect(session.isEmpty)

        session.rememberPurchase(productID: 7, storeID: 3, isSelfProduction: false, choice: choice)
        #expect(session.purchaseStoreID == 3)
        #expect(session.purchaseChoices[7] == choice)
        #expect(session.purchaseChoices[8] == nil)
        #expect(!session.isEmpty)
    }

    @Test("A self-produced purchase keeps the remembered store")
    func selfProduction() {
        let session = QuickScanSession()
        session.rememberPurchase(productID: 7, storeID: 3, isSelfProduction: false, choice: choice)
        session.rememberPurchase(productID: 8, storeID: nil, isSelfProduction: true, choice: choice)
        #expect(session.purchaseStoreID == 3)
        #expect(session.purchaseChoices[8] == choice)
    }

    @Test("Forgetting clears every choice")
    func reset() {
        let session = QuickScanSession()
        session.rememberPurchase(productID: 7, storeID: 3, isSelfProduction: false, choice: choice)
        session.rememberConsume(locationID: 4)
        #expect(session.consumeLocationID == 4)

        session.reset()
        #expect(session.isEmpty)
    }
}
