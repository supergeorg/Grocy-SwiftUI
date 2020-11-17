//
//  ProductsModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation

// MARK: - MDProduct
struct MDProduct: Codable {
    let id, name: String
    let mdProductDescription: String?
    let locationID, quIDPurchase, quIDStock, quFactorPurchaseToStock: String
    let barcode: String?
    let minStockAmount, defaultBestBeforeDays, rowCreatedTimestamp: String
    let productGroupID, pictureFileName: String?
    let defaultBestBeforeDaysAfterOpen, allowPartialUnitsInStock, enableTareWeightHandling, tareWeight: String
    let notCheckStockFulfillmentForRecipes: String
    let parentProductID, calories: String?
    let cumulateMinStockAmountOfSubProducts, defaultBestBeforeDaysAfterFreezing, defaultBestBeforeDaysAfterThawing: String
    let shoppingLocationID: String?
    let userfields: Userfields?

    enum CodingKeys: String, CodingKey {
        case id, name
        case mdProductDescription = "description"
        case locationID = "location_id"
        case quIDPurchase = "qu_id_purchase"
        case quIDStock = "qu_id_stock"
        case quFactorPurchaseToStock = "qu_factor_purchase_to_stock"
        case barcode
        case minStockAmount = "min_stock_amount"
        case defaultBestBeforeDays = "default_best_before_days"
        case rowCreatedTimestamp = "row_created_timestamp"
        case productGroupID = "product_group_id"
        case pictureFileName = "picture_file_name"
        case defaultBestBeforeDaysAfterOpen = "default_best_before_days_after_open"
        case allowPartialUnitsInStock = "allow_partial_units_in_stock"
        case enableTareWeightHandling = "enable_tare_weight_handling"
        case tareWeight = "tare_weight"
        case notCheckStockFulfillmentForRecipes = "not_check_stock_fulfillment_for_recipes"
        case parentProductID = "parent_product_id"
        case calories
        case cumulateMinStockAmountOfSubProducts = "cumulate_min_stock_amount_of_sub_products"
        case defaultBestBeforeDaysAfterFreezing = "default_best_before_days_after_freezing"
        case defaultBestBeforeDaysAfterThawing = "default_best_before_days_after_thawing"
        case shoppingLocationID = "shopping_location_id"
        case userfields
    }
}

// MARK: - Userfields
// so geht das nicht!!!
struct Userfields: Codable {
    let cronometerid, sultanmarked: String
}

typealias MDProducts = [MDProduct]

// MARK: - MDProduct
struct MDProductPOST: Codable {
    let id: Int
    let name, mdProductDescription, locationID: String
    let quIDPurchase, quIDStock, quFactorPurchaseToStock, barcode: String
    let minStockAmount, defaultBestBeforeDays, rowCreatedTimestamp, productGroupID: String
    let pictureFileName: String?
    let defaultBestBeforeDaysAfterOpen, allowPartialUnitsInStock, enableTareWeightHandling, tareWeight: String
    let notCheckStockFulfillmentForRecipes: String
    let parentProductID: String?
    let calories, cumulateMinStockAmountOfSubProducts: String
    let defaultBestBeforeDaysAfterFreezing, defaultBestBeforeDaysAfterThawing, shoppingLocationID: String
    let userfields: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case mdProductDescription = "description"
        case locationID = "location_id"
        case quIDPurchase = "qu_id_purchase"
        case quIDStock = "qu_id_stock"
        case quFactorPurchaseToStock = "qu_factor_purchase_to_stock"
        case barcode
        case minStockAmount = "min_stock_amount"
        case defaultBestBeforeDays = "default_best_before_days"
        case rowCreatedTimestamp = "row_created_timestamp"
        case productGroupID = "product_group_id"
        case pictureFileName = "picture_file_name"
        case defaultBestBeforeDaysAfterOpen = "default_best_before_days_after_open"
        case allowPartialUnitsInStock = "allow_partial_units_in_stock"
        case enableTareWeightHandling = "enable_tare_weight_handling"
        case tareWeight = "tare_weight"
        case notCheckStockFulfillmentForRecipes = "not_check_stock_fulfillment_for_recipes"
        case parentProductID = "parent_product_id"
        case calories
        case cumulateMinStockAmountOfSubProducts = "cumulate_min_stock_amount_of_sub_products"
        case defaultBestBeforeDaysAfterFreezing = "default_best_before_days_after_freezing"
        case defaultBestBeforeDaysAfterThawing = "default_best_before_days_after_thawing"
        case shoppingLocationID = "shopping_location_id"
        case userfields
    }
}
