//
//  StockProductModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 1$.1!.23.

import Foundation
import SwiftData

@Model
class StockProduct: Codable, Equatable {
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
    var dueType: Int
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
    var rowCreatedTimestamp: String
    
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
            do { self.id = try container.decode(Int.self, forKey: .id) } catch { self.id = Int(try container.decode(String.self, forKey: .id))! }
            self.name = try container.decode(String.self, forKey: .name)
            self.mdProductDescription = (try? container.decodeIfPresent(String.self, forKey: .mdProductDescription)) ?? ""
            do { self.productGroupID = try container.decodeIfPresent(Int.self, forKey: .productGroupID) } catch { self.productGroupID = try Int(container.decodeIfPresent(String.self, forKey: .productGroupID) ?? "") }
            do {
                self.active = try container.decode(Bool.self, forKey: .active)
            } catch {
                do {
                    self.active = try container.decode(Int.self, forKey: .active) == 1
                } catch {
                    self.active = ["1", "true"].contains(try? container.decode(String.self, forKey: .active))
                }
            }
            do { self.locationID = try container.decode(Int.self, forKey: .locationID) } catch { self.locationID = try Int(container.decode(String.self, forKey: .locationID))! }
            do { self.storeID = try container.decodeIfPresent(Int.self, forKey: .storeID) } catch { self.storeID = try? Int(container.decodeIfPresent(String.self, forKey: .storeID) ?? "") }
            do { self.quIDPurchase = try container.decode(Int.self, forKey: .quIDPurchase) } catch { self.quIDPurchase = try Int(container.decode(String.self, forKey: .quIDPurchase))! }
            do { self.quIDStock = try container.decode(Int.self, forKey: .quIDStock) } catch { self.quIDStock = try Int(container.decode(String.self, forKey: .quIDStock))! }
            do { self.minStockAmount = try container.decode(Double.self, forKey: .minStockAmount) } catch { self.minStockAmount = try Double(container.decode(String.self, forKey: .minStockAmount))! }
            do { self.defaultDueDays = try container.decode(Int.self, forKey: .defaultDueDays) } catch { self.defaultDueDays = try Int(container.decode(String.self, forKey: .defaultDueDays))! }
            do { self.defaultDueDaysAfterOpen = try container.decode(Int.self, forKey: .defaultDueDaysAfterOpen) } catch { self.defaultDueDaysAfterOpen = try Int(container.decode(String.self, forKey: .defaultDueDaysAfterOpen))! }
            do { self.defaultDueDaysAfterFreezing = try container.decode(Int.self, forKey: .defaultDueDaysAfterFreezing) } catch { self.defaultDueDaysAfterFreezing = try Int(container.decode(String.self, forKey: .defaultDueDaysAfterFreezing))! }
            do { self.defaultDueDaysAfterThawing = try container.decode(Int.self, forKey: .defaultDueDaysAfterThawing) } catch { self.defaultDueDaysAfterThawing = try Int(container.decode(String.self, forKey: .defaultDueDaysAfterThawing))! }
            self.pictureFileName = try? container.decodeIfPresent(String.self, forKey: .pictureFileName) ?? nil
            do {
                self.enableTareWeightHandling = try container.decode(Bool.self, forKey: .enableTareWeightHandling)
            } catch {
                do {
                    self.enableTareWeightHandling = try container.decode(Int.self, forKey: .enableTareWeightHandling) == 1
                } catch {
                    self.enableTareWeightHandling = ["1", "true"].contains(try? container.decode(String.self, forKey: .enableTareWeightHandling))
                }
            }
            do { self.tareWeight = try container.decode(Double.self, forKey: .tareWeight) } catch { self.tareWeight = try? Double(container.decodeIfPresent(String.self, forKey: .tareWeight) ?? "") }
            do {
                self.notCheckStockFulfillmentForRecipes = try container.decode(Bool.self, forKey: .notCheckStockFulfillmentForRecipes)
            } catch {
                do {
                    self.notCheckStockFulfillmentForRecipes = try container.decode(Int.self, forKey: .notCheckStockFulfillmentForRecipes) == 1
                } catch {
                    self.notCheckStockFulfillmentForRecipes = ["1", "true"].contains(try? container.decode(String.self, forKey: .notCheckStockFulfillmentForRecipes))
                }
            }
            do { self.parentProductID = try container.decodeIfPresent(Int.self, forKey: .parentProductID) } catch { self.parentProductID = try? Int(container.decodeIfPresent(String.self, forKey: .parentProductID) ?? "") }
            do { self.calories = try container.decodeIfPresent(Double.self, forKey: .calories) } catch { self.calories = try? Double(container.decodeIfPresent(String.self, forKey: .calories) ?? "") }
            do {
                self.cumulateMinStockAmountOfSubProducts = try container.decode(Bool.self, forKey: .cumulateMinStockAmountOfSubProducts)
            } catch {
                do {
                    self.cumulateMinStockAmountOfSubProducts = try container.decode(Int.self, forKey: .cumulateMinStockAmountOfSubProducts) == 1
                } catch {
                    self.cumulateMinStockAmountOfSubProducts = ["1", "true"].contains(try? container.decode(String.self, forKey: .cumulateMinStockAmountOfSubProducts))
                }
            }
            do { self.dueType = try container.decode(Int.self, forKey: .dueType) } catch { self.dueType = try Int(container.decode(String.self, forKey: .dueType))! }
            do { self.quickConsumeAmount = try container.decodeIfPresent(Double.self, forKey: .quickConsumeAmount) } catch { self.quickConsumeAmount = try? Double(container.decodeIfPresent(String.self, forKey: .quickConsumeAmount) ?? "") }
            do { self.quickOpenAmount = try container.decodeIfPresent(Double.self, forKey: .quickOpenAmount) } catch { self.quickOpenAmount = try? Double(container.decodeIfPresent(String.self, forKey: .quickOpenAmount) ?? "") }
            do {
                self.hideOnStockOverview = try container.decode(Bool.self, forKey: .hideOnStockOverview)
            } catch {
                do {
                    self.hideOnStockOverview = try container.decode(Int.self, forKey: .hideOnStockOverview) == 1
                } catch {
                    self.hideOnStockOverview = ["1", "true"].contains(try? container.decode(String.self, forKey: .hideOnStockOverview))
                }
            }
            do { self.defaultStockLabelType = try container.decodeIfPresent(Int.self, forKey: .defaultStockLabelType) } catch { self.defaultStockLabelType = try? Int(container.decodeIfPresent(String.self, forKey: .defaultStockLabelType) ?? "") }
            do {
                self.shouldNotBeFrozen = try container.decode(Bool.self, forKey: .shouldNotBeFrozen)
            } catch {
                do {
                    self.shouldNotBeFrozen = try container.decode(Int.self, forKey: .shouldNotBeFrozen) == 1
                } catch {
                    self.shouldNotBeFrozen = ["1", "true"].contains(try? container.decode(String.self, forKey: .shouldNotBeFrozen))
                }
            }
            do {
                self.treatOpenedAsOutOfStock = try container.decode(Bool.self, forKey: .treatOpenedAsOutOfStock)
            } catch {
                do {
                    self.treatOpenedAsOutOfStock = try container.decode(Int.self, forKey: .treatOpenedAsOutOfStock) == 1
                } catch {
                    self.treatOpenedAsOutOfStock = ["1", "true"].contains(try? container.decode(String.self, forKey: .treatOpenedAsOutOfStock))
                }
            }
            do {
                self.noOwnStock = try container.decode(Bool.self, forKey: .noOwnStock)
            } catch {
                do {
                    self.noOwnStock = try container.decode(Int.self, forKey: .noOwnStock) == 1
                } catch {
                    self.noOwnStock = ["1", "true"].contains(try? container.decode(String.self, forKey: .noOwnStock))
                }
            }
            do { self.defaultConsumeLocationID = try container.decodeIfPresent(Int.self, forKey: .defaultConsumeLocationID) } catch { self.defaultConsumeLocationID = try? Int(container.decodeIfPresent(String.self, forKey: .defaultConsumeLocationID) ?? "") }
            do {
                self.moveOnOpen = try container.decode(Bool.self, forKey: .moveOnOpen)
            } catch {
                do {
                    self.moveOnOpen = try container.decode(Int.self, forKey: .moveOnOpen) == 1
                } catch {
                    self.moveOnOpen = ["1", "true"].contains(try? container.decode(String.self, forKey: .moveOnOpen))
                }
            }
            do { self.quIDConsume = try container.decode(Int.self, forKey: .quIDConsume) } catch { self.quIDConsume = try Int(container.decode(String.self, forKey: .quIDConsume))! }
            do {
                self.autoReprintStockLabel = try container.decode(Bool.self, forKey: .autoReprintStockLabel)
            } catch {
                do {
                    self.autoReprintStockLabel = try container.decode(Int.self, forKey: .autoReprintStockLabel) == 1
                } catch {
                    self.autoReprintStockLabel = ["1", "true"].contains(try? container.decode(String.self, forKey: .autoReprintStockLabel))
                }
            }
            do { self.quIDPrice = try container.decode(Int.self, forKey: .quIDPrice) } catch { self.quIDPrice = try Int(container.decode(String.self, forKey: .quIDPrice))! }
            self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
    
    init(
        id: Int,
        name: String,
        mdProductDescription: String = "",
        productGroupID: Int? = nil,
        active: Bool,
        locationID: Int,
        storeID: Int? = nil,
        quIDPurchase: Int,
        quIDStock: Int,
        quIDConsume: Int,
        quIDPrice: Int,
        minStockAmount: Double,
        defaultDueDays: Int,
        defaultDueDaysAfterOpen: Int,
        defaultDueDaysAfterFreezing: Int,
        defaultDueDaysAfterThawing: Int,
        pictureFileName: String? = nil,
        enableTareWeightHandling: Bool = false,
        tareWeight: Double? = nil,
        notCheckStockFulfillmentForRecipes: Bool = false,
        parentProductID: Int? = nil,
        calories: Double? = nil,
        cumulateMinStockAmountOfSubProducts: Bool,
        dueType: Int,
        quickConsumeAmount: Double? = nil,
        quickOpenAmount: Double? = nil,
        hideOnStockOverview: Bool = false,
        defaultStockLabelType: Int? = nil,
        shouldNotBeFrozen: Bool = false,
        treatOpenedAsOutOfStock: Bool = false,
        noOwnStock: Bool = false,
        defaultConsumeLocationID: Int? = nil,
        moveOnOpen: Bool = false,
        autoReprintStockLabel: Bool = false,
        rowCreatedTimestamp: String
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
    
    static func == (lhs: StockProduct, rhs: StockProduct) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.mdProductDescription == rhs.mdProductDescription &&
        lhs.productGroupID == rhs.productGroupID &&
        lhs.active == rhs.active &&
        lhs.locationID == rhs.locationID &&
        lhs.storeID == rhs.storeID &&
        lhs.quIDPurchase == rhs.quIDPurchase &&
        lhs.quIDStock == rhs.quIDStock &&
        lhs.minStockAmount == rhs.minStockAmount &&
        lhs.defaultDueDays == rhs.defaultDueDays &&
        lhs.defaultDueDaysAfterOpen == rhs.defaultDueDaysAfterOpen &&
        lhs.defaultDueDaysAfterFreezing == rhs.defaultDueDaysAfterFreezing &&
        lhs.defaultDueDaysAfterThawing == rhs.defaultDueDaysAfterThawing &&
        lhs.pictureFileName == rhs.pictureFileName &&
        lhs.enableTareWeightHandling == rhs.enableTareWeightHandling &&
        lhs.tareWeight == rhs.tareWeight &&
        lhs.notCheckStockFulfillmentForRecipes == rhs.notCheckStockFulfillmentForRecipes &&
        lhs.parentProductID == rhs.parentProductID &&
        lhs.calories == rhs.calories &&
        lhs.cumulateMinStockAmountOfSubProducts == rhs.cumulateMinStockAmountOfSubProducts &&
        lhs.dueType == rhs.dueType &&
        lhs.quickConsumeAmount == rhs.quickConsumeAmount &&
        lhs.quickOpenAmount == rhs.quickOpenAmount &&
        lhs.hideOnStockOverview == rhs.hideOnStockOverview &&
        lhs.defaultStockLabelType == rhs.defaultStockLabelType &&
        lhs.shouldNotBeFrozen == rhs.shouldNotBeFrozen &&
        lhs.treatOpenedAsOutOfStock == rhs.treatOpenedAsOutOfStock &&
        lhs.noOwnStock == rhs.noOwnStock &&
        lhs.defaultConsumeLocationID == rhs.defaultConsumeLocationID &&
        lhs.moveOnOpen == rhs.moveOnOpen &&
        lhs.quIDConsume == rhs.quIDConsume &&
        lhs.autoReprintStockLabel == rhs.autoReprintStockLabel &&
        lhs.quIDPrice == rhs.quIDPrice &&
        lhs.rowCreatedTimestamp == rhs.rowCreatedTimestamp
    }
}
