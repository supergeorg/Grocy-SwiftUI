//
//  PriceTrendTests.swift
//  Grocy Mobile
//

import Foundation
import Testing

@testable import Grocy_Mobile

@Suite("Price trend")
struct PriceTrendTests {
    private let start = Date(timeIntervalSince1970: 1_700_000_000)
    private func day(_ offset: Double) -> Date { start.addingTimeInterval(offset * 86_400) }

    @Test("Prices on a line give that line")
    func exactLine() throws {
        let trend = try #require(PriceTrend(points: [(day(0), 1.0), (day(10), 2.0), (day(20), 3.0)]))
        #expect(trend.startDate == day(0))
        #expect(trend.endDate == day(20))
        #expect(abs(trend.startPrice - 1.0) < 1e-9)
        #expect(abs(trend.endPrice - 3.0) < 1e-9)
    }

    @Test("The order of the purchases doesn't matter")
    func unordered() throws {
        let trend = try #require(PriceTrend(points: [(day(20), 3.0), (day(0), 1.0), (day(10), 2.0)]))
        #expect(abs(trend.startPrice - 1.0) < 1e-9)
        #expect(abs(trend.endPrice - 3.0) < 1e-9)
    }

    @Test("Scattered prices give the least-squares line")
    func leastSquares() throws {
        // x = 0, 1, 2, 3 days; y = 1, 3, 2, 4 → slope 0.8 per day, intercept 1.3.
        let trend = try #require(PriceTrend(points: [(day(0), 1), (day(1), 3), (day(2), 2), (day(3), 4)]))
        #expect(abs(trend.startPrice - 1.3) < 1e-9)
        #expect(abs(trend.endPrice - 3.7) < 1e-9)
    }

    @Test("No trend with one purchase or one date")
    func noTrend() {
        #expect(PriceTrend(points: []) == nil)
        #expect(PriceTrend(points: [(day(0), 1.0)]) == nil)
        #expect(PriceTrend(points: [(day(0), 1.0), (day(0), 2.0)]) == nil)
    }
}
