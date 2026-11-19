//
//  StockProductPriceHistoryView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 19.11.26.
//

import Charts
import SwiftUI

/// The purchase prices of a product: a chart per store, then every purchase, newest first.
/// Shown as a section of the product overview; prices are per stock quantity unit.
struct StockProductPriceHistoryView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @AppStorage("localizationKey") var localizationKey: String = "en"

    var priceHistory: ProductPriceHistories
    var quantityUnitName: String?

    private var sortedHistory: ProductPriceHistories {
        priceHistory.sorted { $0.date > $1.date }
    }

    private func storeName(_ entry: ProductPriceHistory) -> String {
        entry.storeName ?? String(localized: "No store")
    }

    var body: some View {
        Section {
            Chart(priceHistory) { entry in
                LineMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Price", entry.price)
                )
                .foregroundStyle(by: .value("Store", storeName(entry)))
                PointMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Price", entry.price)
                )
                .foregroundStyle(by: .value("Store", storeName(entry)))
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let price = value.as(Double.self) {
                            Text(grocyVM.getFormattedCurrency(amount: price))
                        }
                    }
                }
            }
            .frame(height: Sizes.priceHistoryChartHeight)
            .padding(.vertical, Spacing.small)

            ForEach(sortedHistory) { entry in
                LabeledContent(
                    content: {
                        Text(grocyVM.getFormattedCurrency(amount: entry.price))
                    },
                    label: {
                        Text(formatDateAsString(entry.date, localizationKey: localizationKey) ?? "")
                        Text(storeName(entry))
                    }
                )
            }
        } header: {
            Label("Price history", systemImage: MySymbols.priceHistory)
        } footer: {
            if let quantityUnitName, !quantityUnitName.isEmpty {
                Text("Prices per \(quantityUnitName)")
            }
        }
    }
}

#Preview(traits: .previewData) {
    let calendar = Calendar.current
    let today = Date()
    Form {
        StockProductPriceHistoryView(
            priceHistory: [
                ProductPriceHistory(date: calendar.date(byAdding: .day, value: -60, to: today) ?? today, price: 1.29, storeID: 1, storeName: "Store 1"),
                ProductPriceHistory(date: calendar.date(byAdding: .day, value: -30, to: today) ?? today, price: 1.49, storeID: 1, storeName: "Store 1"),
                ProductPriceHistory(date: calendar.date(byAdding: .day, value: -20, to: today) ?? today, price: 1.19, storeID: 2, storeName: "Store 2"),
                ProductPriceHistory(date: calendar.date(byAdding: .day, value: -2, to: today) ?? today, price: 1.39, storeID: 1, storeName: "Store 1"),
                ProductPriceHistory(date: today, price: 1.59),
            ],
            quantityUnitName: "Pack"
        )
    }
    .formStyle(.grouped)
}
