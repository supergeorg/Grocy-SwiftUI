//
//  PriceTrend.swift
//  Grocy Mobile
//

import Foundation

/// The linear trend of a product's purchase prices, like the trendline on Grocy's product card (Grocy 4.4).
/// A least-squares line through all purchases, over time, drawn from the first to the last purchase.
nonisolated struct PriceTrend: Equatable, Sendable {
    let startDate: Date
    let startPrice: Double
    let endDate: Date
    let endPrice: Double

    /// Nil with fewer than two purchases, or when they all share one date, since there's no trend then.
    init?(points: [(date: Date, price: Double)]) {
        guard points.count >= 2, let first = points.map(\.date).min(), let last = points.map(\.date).max(), first < last else { return nil }
        // Seconds since the first purchase keep the numbers small.
        let xs = points.map { $0.date.timeIntervalSince(first) }
        let ys = points.map(\.price)
        let count = Double(points.count)
        let meanX = xs.reduce(0, +) / count
        let meanY = ys.reduce(0, +) / count
        var covariance = 0.0
        var variance = 0.0
        for (x, y) in zip(xs, ys) {
            covariance += (x - meanX) * (y - meanY)
            variance += (x - meanX) * (x - meanX)
        }
        guard variance > 0 else { return nil }
        let slope = covariance / variance
        let intercept = meanY - slope * meanX
        self.startDate = first
        self.startPrice = intercept
        self.endDate = last
        self.endPrice = intercept + slope * last.timeIntervalSince(first)
    }
}
