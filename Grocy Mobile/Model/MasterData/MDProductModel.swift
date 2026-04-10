//
//  ProductsModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation
import SwiftData

@Model
class MDProduct: Codable, Equatable, Identifiable {
    @Attribute(.unique) var id: Int
    var name: String
    var mdProductDescription: String
    var productGroupID: Int?
    var active: Bool
    var locationID: Int
    var storeID: Int?
    var quIDPurchase: Int
    var quIDStock: Int
    var quIDConsume: Int
    var quIDPrice: Int
    var minStockAmount: Double
    var defaultDueDays: Int
    var defaultDueDaysAfterOpen: Int
    var defaultDueDaysAfterFreezing: Int
    var defaultDueDaysAfterThawing: Int
    var pictureFileName: String?
    var enableTareWeightHandling: Bool
    var tareWeight: Double?
    var notCheckStockFulfillmentForRecipes: Bool
    var parentProductID: Int?
    var calories: Double?
    var cumulateMinStockAmountOfSubProducts: Bool
    var dueType: DueType
    var quickConsumeAmount: Double?
    var quickOpenAmount: Double?
    var hideOnStockOverview: Bool
    var defaultStockLabelType: Int?
    var shouldNotBeFrozen: Bool
    var treatOpenedAsOutOfStock: Bool
    var noOwnStock: Bool
    var defaultConsumeLocationID: Int?
    var moveOnOpen: Bool
    var autoReprintStockLabel: Bool
    var rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case mdProductDescription = "description"
        case productGroupID = "product_group_id"
        case active
        case locationID = "location_id"
        case storeID = "shopping_location_id"
        case quIDPurchase = "qu_id_purchase"
        case quIDStock = "qu_id_stock"
        case quIDConsume = "qu_id_consume"
        case quIDPrice = "qu_id_price"
        case minStockAmount = "min_stock_amount"
        case defaultDueDays = "default_best_before_days"
        case defaultDueDaysAfterOpen = "default_best_before_days_after_open"
        case defaultDueDaysAfterFreezing = "default_best_before_days_after_freezing"
        case defaultDueDaysAfterThawing = "default_best_before_days_after_thawing"
        case pictureFileName = "picture_file_name"
        case enableTareWeightHandling = "enable_tare_weight_handling"
        case tareWeight = "tare_weight"
        case notCheckStockFulfillmentForRecipes = "not_check_stock_fulfillment_for_recipes"
        case parentProductID = "parent_product_id"
        case calories
        case cumulateMinStockAmountOfSubProducts = "cumulate_min_stock_amount_of_sub_products"
        case dueType = "due_type"
        case quickConsumeAmount = "quick_consume_amount"
        case quickOpenAmount = "quick_open_amount"
        case hideOnStockOverview = "hide_on_stock_overview"
        case defaultStockLabelType = "default_stock_label_type"
        case shouldNotBeFrozen = "should_not_be_frozen"
        case treatOpenedAsOutOfStock = "treat_opened_as_out_of_stock"
        case noOwnStock = "no_own_stock"
        case defaultConsumeLocationID = "default_consume_location_id"
        case moveOnOpen = "move_on_open"
        case autoReprintStockLabel = "auto_reprint_stock_label"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
            self.mdProductDescription = (try? container.decodeIfPresent(String.self, forKey: .mdProductDescription)) ?? ""
            self.productGroupID = try container.decodeFlexibleIntIfPresent(forKey: .productGroupID)
            self.active = try container.decodeFlexibleBool(forKey: .active)
            self.locationID = try container.decodeFlexibleInt(forKey: .locationID)
            self.storeID = try container.decodeFlexibleIntIfPresent(forKey: .storeID)
            self.quIDPurchase = try container.decodeFlexibleInt(forKey: .quIDPurchase)
            self.quIDStock = try container.decodeFlexibleInt(forKey: .quIDStock)
            self.minStockAmount = try container.decodeFlexibleDouble(forKey: .minStockAmount)
            self.defaultDueDays = try container.decodeFlexibleInt(forKey: .defaultDueDays)
            self.defaultDueDaysAfterOpen = try container.decodeFlexibleInt(forKey: .defaultDueDaysAfterOpen)
            self.defaultDueDaysAfterFreezing = try container.decodeFlexibleInt(forKey: .defaultDueDaysAfterFreezing)
            self.defaultDueDaysAfterThawing = try container.decodeFlexibleInt(forKey: .defaultDueDaysAfterThawing)
            self.pictureFileName = try? container.decodeIfPresent(String.self, forKey: .pictureFileName) ?? nil
            self.enableTareWeightHandling = try container.decodeFlexibleBool(forKey: .enableTareWeightHandling)
            self.tareWeight = try container.decodeFlexibleDoubleIfPresent(forKey: .tareWeight)
            self.notCheckStockFulfillmentForRecipes = try container.decodeFlexibleBool(forKey: .notCheckStockFulfillmentForRecipes)
            self.parentProductID = try container.decodeFlexibleIntIfPresent(forKey: .parentProductID)
            self.calories = try container.decodeFlexibleDoubleIfPresent(forKey: .calories)
            self.cumulateMinStockAmountOfSubProducts = try container.decodeFlexibleBool(forKey: .cumulateMinStockAmountOfSubProducts)
            self.dueType = DueType(rawValue: try container.decodeFlexibleInt(forKey: .dueType))!
            self.quickConsumeAmount = try container.decodeFlexibleDoubleIfPresent(forKey: .quickConsumeAmount)
            self.quickOpenAmount = try container.decodeFlexibleDoubleIfPresent(forKey: .quickOpenAmount)
            self.hideOnStockOverview = try container.decodeFlexibleBool(forKey: .hideOnStockOverview)
            self.defaultStockLabelType = try container.decodeFlexibleIntIfPresent(forKey: .defaultStockLabelType)
            self.shouldNotBeFrozen = try container.decodeFlexibleBool(forKey: .shouldNotBeFrozen)
            self.treatOpenedAsOutOfStock = try container.decodeFlexibleBool(forKey: .treatOpenedAsOutOfStock)
            self.noOwnStock = try container.decodeFlexibleBool(forKey: .noOwnStock)
            self.defaultConsumeLocationID = try container.decodeFlexibleIntIfPresent(forKey: .defaultConsumeLocationID)
            self.moveOnOpen = try container.decodeFlexibleBool(forKey: .moveOnOpen)
            self.quIDConsume = try container.decodeFlexibleInt(forKey: .quIDConsume)
            self.autoReprintStockLabel = try container.decodeFlexibleBool(forKey: .autoReprintStockLabel)
            self.quIDPrice = try container.decodeFlexibleInt(forKey: .quIDPrice)
            self.rowCreatedTimestamp = getDateFromString(try container.decode(String.self, forKey: .rowCreatedTimestamp))!
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(mdProductDescription, forKey: .mdProductDescription)
        try container.encode(productGroupID, forKey: .productGroupID)
        try container.encode(active, forKey: .active)
        try container.encode(locationID, forKey: .locationID)
        try container.encode(storeID, forKey: .storeID)
        try container.encode(quIDPurchase, forKey: .quIDPurchase)
        try container.encode(quIDStock, forKey: .quIDStock)
        try container.encode(quIDConsume, forKey: .quIDConsume)
        try container.encode(quIDPrice, forKey: .quIDPrice)
        try container.encode(minStockAmount, forKey: .minStockAmount)
        try container.encode(defaultDueDays, forKey: .defaultDueDays)
        try container.encode(defaultDueDaysAfterOpen, forKey: .defaultDueDaysAfterOpen)
        try container.encode(defaultDueDaysAfterFreezing, forKey: .defaultDueDaysAfterFreezing)
        try container.encode(defaultDueDaysAfterThawing, forKey: .defaultDueDaysAfterThawing)
        try container.encode(pictureFileName, forKey: .pictureFileName)
        try container.encode(enableTareWeightHandling, forKey: .enableTareWeightHandling)
        try container.encode(tareWeight, forKey: .tareWeight)
        try container.encode(notCheckStockFulfillmentForRecipes, forKey: .notCheckStockFulfillmentForRecipes)
        try container.encode(parentProductID, forKey: .parentProductID)
        try container.encode(calories, forKey: .calories)
        try container.encode(cumulateMinStockAmountOfSubProducts, forKey: .cumulateMinStockAmountOfSubProducts)
        try container.encode(dueType, forKey: .dueType)
        try container.encode(quickConsumeAmount, forKey: .quickConsumeAmount)
        try container.encode(quickOpenAmount, forKey: .quickOpenAmount)
        try container.encode(hideOnStockOverview, forKey: .hideOnStockOverview)
        try container.encode(defaultStockLabelType, forKey: .defaultStockLabelType)
        try container.encode(shouldNotBeFrozen, forKey: .shouldNotBeFrozen)
        try container.encode(treatOpenedAsOutOfStock, forKey: .treatOpenedAsOutOfStock)
        try container.encode(noOwnStock, forKey: .noOwnStock)
        try container.encode(defaultConsumeLocationID, forKey: .defaultConsumeLocationID)
        try container.encode(moveOnOpen, forKey: .moveOnOpen)
        try container.encode(autoReprintStockLabel, forKey: .autoReprintStockLabel)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }

    init(
        id: Int = -1,
        name: String = "",
        mdProductDescription: String = "",
        productGroupID: Int? = nil,
        active: Bool = true,
        locationID: Int = -1,
        storeID: Int = -1,
        quIDPurchase: Int = -1,
        quIDStock: Int = -1,
        quIDConsume: Int = -1,
        quIDPrice: Int = -1,
        minStockAmount: Double = 0.0,
        defaultDueDays: Int = 0,
        defaultDueDaysAfterOpen: Int = 0,
        defaultDueDaysAfterFreezing: Int = 0,
        defaultDueDaysAfterThawing: Int = 0,
        pictureFileName: String? = nil,
        enableTareWeightHandling: Bool = false,
        tareWeight: Double? = nil,
        notCheckStockFulfillmentForRecipes: Bool = false,
        parentProductID: Int? = nil,
        calories: Double? = nil,
        cumulateMinStockAmountOfSubProducts: Bool = false,
        dueType: DueType = DueType.bestBefore,
        quickConsumeAmount: Double? = nil,
        quickOpenAmount: Double? = nil,
        hideOnStockOverview: Bool = false,
        defaultStockLabelType: Int? = nil,
        shouldNotBeFrozen: Bool = false,
        treatOpenedAsOutOfStock: Bool = false,
        noOwnStock: Bool = false,
        defaultConsumeLocationID: Int? = -1,
        moveOnOpen: Bool = false,
        autoReprintStockLabel: Bool = false,
        rowCreatedTimestamp: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.mdProductDescription = mdProductDescription
        self.productGroupID = productGroupID
        self.active = active
        self.locationID = locationID
        self.storeID = storeID
        self.quIDPurchase = quIDPurchase
        self.quIDStock = quIDStock
        self.minStockAmount = minStockAmount
        self.defaultDueDays = defaultDueDays
        self.defaultDueDaysAfterOpen = defaultDueDaysAfterOpen
        self.defaultDueDaysAfterFreezing = defaultDueDaysAfterFreezing
        self.defaultDueDaysAfterThawing = defaultDueDaysAfterThawing
        self.pictureFileName = pictureFileName
        self.enableTareWeightHandling = enableTareWeightHandling
        self.tareWeight = tareWeight
        self.notCheckStockFulfillmentForRecipes = notCheckStockFulfillmentForRecipes
        self.parentProductID = parentProductID
        self.calories = calories
        self.cumulateMinStockAmountOfSubProducts = cumulateMinStockAmountOfSubProducts
        self.dueType = dueType
        self.quickConsumeAmount = quickConsumeAmount
        self.quickOpenAmount = quickOpenAmount
        self.hideOnStockOverview = hideOnStockOverview
        self.defaultStockLabelType = defaultStockLabelType
        self.shouldNotBeFrozen = shouldNotBeFrozen
        self.treatOpenedAsOutOfStock = treatOpenedAsOutOfStock
        self.noOwnStock = noOwnStock
        self.defaultConsumeLocationID = defaultConsumeLocationID
        self.moveOnOpen = moveOnOpen
        self.quIDConsume = quIDConsume
        self.autoReprintStockLabel = autoReprintStockLabel
        self.quIDPrice = quIDPrice
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }

    static func == (lhs: MDProduct, rhs: MDProduct) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.mdProductDescription == rhs.mdProductDescription && lhs.productGroupID == rhs.productGroupID && lhs.active == rhs.active && lhs.locationID == rhs.locationID
            && lhs.storeID == rhs.storeID && lhs.quIDPurchase == rhs.quIDPurchase && lhs.quIDStock == rhs.quIDStock && lhs.minStockAmount == rhs.minStockAmount && lhs.defaultDueDays == rhs.defaultDueDays
            && lhs.defaultDueDaysAfterOpen == rhs.defaultDueDaysAfterOpen && lhs.defaultDueDaysAfterFreezing == rhs.defaultDueDaysAfterFreezing && lhs.defaultDueDaysAfterThawing == rhs.defaultDueDaysAfterThawing
            && lhs.pictureFileName == rhs.pictureFileName && lhs.enableTareWeightHandling == rhs.enableTareWeightHandling && lhs.tareWeight == rhs.tareWeight
            && lhs.notCheckStockFulfillmentForRecipes == rhs.notCheckStockFulfillmentForRecipes && lhs.parentProductID == rhs.parentProductID && lhs.calories == rhs.calories
            && lhs.cumulateMinStockAmountOfSubProducts == rhs.cumulateMinStockAmountOfSubProducts && lhs.dueType == rhs.dueType && lhs.quickConsumeAmount == rhs.quickConsumeAmount && lhs.quickOpenAmount == rhs.quickOpenAmount
            && lhs.hideOnStockOverview == rhs.hideOnStockOverview && lhs.defaultStockLabelType == rhs.defaultStockLabelType && lhs.shouldNotBeFrozen == rhs.shouldNotBeFrozen && lhs.treatOpenedAsOutOfStock == rhs.treatOpenedAsOutOfStock
            && lhs.noOwnStock == rhs.noOwnStock && lhs.defaultConsumeLocationID == rhs.defaultConsumeLocationID && lhs.moveOnOpen == rhs.moveOnOpen && lhs.quIDConsume == rhs.quIDConsume
            && lhs.autoReprintStockLabel == rhs.autoReprintStockLabel && lhs.quIDPrice == rhs.quIDPrice && lhs.rowCreatedTimestamp == rhs.rowCreatedTimestamp
    }
}

typealias MDProducts = [MDProduct]
