//
//  StockEntriesDestination.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 23.11.26.
//

import SwiftData
import SwiftUI

/// Opens a product's stock entries (`NavigationLink(value:)`).
///
/// The link's value is the product ID, not the `StockElement`: SwiftUI keeps a link's value and compares it with `==`
/// on later updates, and a stock sync replaces all stock elements. Comparing an element that the sync deleted reads
/// its detached attributes, which crashes SwiftData.
struct StockEntriesDestination: Hashable {
    let productID: Int
}

/// The stock entries of a product, with its current stock element (or a stand-in with amount 0 if it isn't in stock).
struct StockEntriesDestinationView: View {
    @Query private var stock: Stock
    @Query private var products: MDProducts

    init(productID: Int) {
        _stock = Query(filter: #Predicate<StockElement> { $0.productID == productID })
        _products = Query(filter: #Predicate<MDProduct> { $0.id == productID })
    }

    var body: some View {
        if let stockElement = stock.first {
            StockEntriesView(stockElement: stockElement)
        } else if let product = products.first {
            StockEntriesView(stockElement: StockElement(notInStock: product))
        } else {
            ContentUnavailableView("Product is not on server", systemImage: MySymbols.product)
        }
    }
}

extension View {
    /// Shows the stock entries for a `StockEntriesDestination` link.
    func stockEntriesDestination() -> some View {
        navigationDestination(for: StockEntriesDestination.self) { destination in
            StockEntriesDestinationView(productID: destination.productID)
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        StockEntriesDestinationView(productID: 4)
    }
}
