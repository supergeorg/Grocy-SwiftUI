//
//  GrocyIntentSupport.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 21.11.26.
//

import AppIntents
import Foundation
import SwiftData

/// Errors Siri and Shortcuts show to the person. `CustomLocalizedStringResourceConvertible` makes the system show the
/// message instead of a generic failure.
nonisolated enum GrocyIntentError: Error, CustomLocalizedStringResourceConvertible {
    case notLoggedIn
    case productNotFound
    case openedTrackingDisabled
    case invalidAmount
    case server(message: String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notLoggedIn:
            "Grocy Mobile isn't connected to a Grocy server. Open the app and log in first."
        case .productNotFound:
            "The product wasn't found on your Grocy server."
        case .openedTrackingDisabled:
            "Opening products is turned off on your Grocy server."
        case .invalidAmount:
            "The amount must be greater than zero."
        case .server(let message):
            "Grocy couldn't do that: \(message)"
        }
    }
}

/// The stock of one product, read from the server, with the names Siri says.
struct ProductStockState {
    let productName: String
    let amount: Double
    let amountOpened: Double
    let quantityUnit: MDQuantityUnit?
    let quickConsumeAmount: Double
    let quickOpenAmount: Double

    /// For example "2 Packs".
    func amountDescription(_ amount: Double) -> String {
        let unitName = quantityUnit?.getName(amount: amount) ?? ""
        return unitName.isEmpty ? amount.formattedAmount : "\(amount.formattedAmount) \(unitName)"
    }
}

extension GrocyViewModel {
    /// Waits for the login started at launch (Siri may launch the app without UI) and fails if there's no server.
    func ensureLoggedInForIntent() async throws {
        await waitForLogin()
        guard grocyApi.isLoggedIn else {
            throw GrocyIntentError.notLoggedIn
        }
    }

    /// Reads the product's current stock from the server, so Siri never answers from an outdated cache.
    func productStockStateForIntent(productID: Int) async throws -> ProductStockState {
        let details: StockProductDetails
        do {
            details = try await grocyApi.getStockProductInfo(stockModeGet: .details, productID: productID, queries: nil)
        } catch {
            GrocyLogger.error("Getting the stock of product \(productID) for an intent failed. \(error)")
            throw GrocyIntentError.productNotFound
        }
        let quantityUnitID = details.quantityUnitStockID
        let quantityUnit =
            details.quantityUnitStock
            ?? (try? modelContext.fetch(FetchDescriptor<MDQuantityUnit>(predicate: #Predicate { $0.id == quantityUnitID })).first)
        let product =
            details.product
            ?? (try? modelContext.fetch(FetchDescriptor<MDProduct>(predicate: #Predicate { $0.id == productID })).first)
        return ProductStockState(
            productName: product?.name ?? "",
            amount: details.stockAmountAggregated ?? details.stockAmount,
            amountOpened: details.stockAmountOpenedAggregated ?? details.stockAmountOpened ?? 0,
            quantityUnit: quantityUnit,
            quickConsumeAmount: product?.quickConsumeAmount ?? 1,
            quickOpenAmount: product?.quickOpenAmount ?? product?.quickConsumeAmount ?? 1
        )
    }

    /// Whether the server tracks opened products. Without a synced config, Grocy's default (on) applies.
    var isOpenedTrackingEnabled: Bool {
        let config = try? modelContext.fetch(FetchDescriptor<SystemConfig>()).first
        return GrocyFeatures(config).openedTracking
    }

    /// Posts a stock action and resyncs the stock, so the app and the widgets show the new amount.
    func postStockActionForIntent<T: Codable>(productID: Int, stockModePost: StockProductPost, content: T) async throws {
        do {
            try await postStockObject(id: productID, stockModePost: stockModePost, content: content)
        } catch let error as APIError {
            GrocyLogger.error("Stock action \(stockModePost.rawValue) from an intent failed. \(error)")
            throw GrocyIntentError.server(message: error.displayMessage)
        }
        await requestData(additionalObjects: [.stock, .volatileStock])
    }
}
