//
//  ProductsModel.swift
//  grocy-ios
//
//  Created by Georg Meissner on 13.10.20.
//

import Foundation

// MARK: - MDProduct

struct MDProduct: Codable {
    let id: Int
    let name: String
    @NullCodable var mdProductDescription: String?
    @NullCodable var productGroupID: Int?
    let active: Bool?
    let locationID: Int
    @NullCodable var storeID: Int?
    let quIDPurchase, quIDStock, quIDConsume, quIDPrice: Int
    let minStockAmount: Double
    let defaultBestBeforeDays, defaultBestBeforeDaysAfterOpen, defaultBestBeforeDaysAfterFreezing, defaultBestBeforeDaysAfterThawing: Int
    @NullCodable var pictureFileName: String?
    let enableTareWeightHandling: Bool?
    @NullCodable var tareWeight: Double?
    let notCheckStockFulfillmentForRecipes: Bool?
    @NullCodable var parentProductID: Int?
    @NullCodable var calories: Double?
    let cumulateMinStockAmountOfSubProducts: Bool?
    let dueType: Int
    @NullCodable var quickConsumeAmount: Double?
    @NullCodable var quickOpenAmount: Double?
    @NullCodable var hideOnStockOverview: Bool?
    let defaultStockLabelType: Int?
    let shouldNotBeFrozen: Bool?
    let treatOpenedAsOutOfStock: Bool?
    let noOwnStock: Bool?
    @NullCodable var defaultConsumeLocationID: Int?
    let moveOnOpen: Bool?
    let autoReprintStockLabel: Bool?
    let rowCreatedTimestamp: String

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
        case defaultBestBeforeDays = "default_best_before_days"
        case defaultBestBeforeDaysAfterOpen = "default_best_before_days_after_open"
        case defaultBestBeforeDaysAfterFreezing = "default_best_before_days_after_freezing"
        case defaultBestBeforeDaysAfterThawing = "default_best_before_days_after_thawing"
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

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            do { self.id = try container.decode(Int.self, forKey: .id) } catch { self.id = Int(try container.decode(String.self, forKey: .id))! }
            self.name = try container.decode(String.self, forKey: .name)
            self.mdProductDescription = try? container.decodeIfPresent(String.self, forKey: .mdProductDescription) ?? nil
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
            do { self.defaultBestBeforeDays = try container.decode(Int.self, forKey: .defaultBestBeforeDays) } catch { self.defaultBestBeforeDays = try Int(container.decode(String.self, forKey: .defaultBestBeforeDays))! }
            do { self.defaultBestBeforeDaysAfterOpen = try container.decode(Int.self, forKey: .defaultBestBeforeDaysAfterOpen) } catch { self.defaultBestBeforeDaysAfterOpen = try Int(container.decode(String.self, forKey: .defaultBestBeforeDaysAfterOpen))! }
            do { self.defaultBestBeforeDaysAfterFreezing = try container.decode(Int.self, forKey: .defaultBestBeforeDaysAfterFreezing) } catch { self.defaultBestBeforeDaysAfterFreezing = try Int(container.decode(String.self, forKey: .defaultBestBeforeDaysAfterFreezing))! }
            do { self.defaultBestBeforeDaysAfterThawing = try container.decode(Int.self, forKey: .defaultBestBeforeDaysAfterThawing) } catch { self.defaultBestBeforeDaysAfterThawing = try Int(container.decode(String.self, forKey: .defaultBestBeforeDaysAfterThawing))! }
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
            do { self.parentProductID = try container.decode(Int.self, forKey: .parentProductID) } catch { self.parentProductID = try? Int(container.decodeIfPresent(String.self, forKey: .parentProductID) ?? "") }
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
        mdProductDescription: String? = nil,
        productGroupID: Int? = nil,
        active: Bool,
        locationID: Int,
        storeID: Int? = nil,
        quIDPurchase: Int,
        quIDStock: Int,
        quIDConsume: Int,
        quIDPrice: Int,
        minStockAmount: Double,
        defaultBestBeforeDays: Int,
        defaultBestBeforeDaysAfterOpen: Int,
        defaultBestBeforeDaysAfterFreezing: Int,
        defaultBestBeforeDaysAfterThawing: Int,
        pictureFileName: String? = nil,
        enableTareWeightHandling: Bool? = nil,
        tareWeight: Double? = nil,
        notCheckStockFulfillmentForRecipes: Bool? = nil,
        parentProductID: Int? = nil,
        calories: Double? = nil,
        cumulateMinStockAmountOfSubProducts: Bool,
        dueType: Int,
        quickConsumeAmount: Double? = nil,
        quickOpenAmount: Double? = nil,
        hideOnStockOverview: Bool? = nil,
        defaultStockLabelType: Int? = nil,
        shouldNotBeFrozen: Bool? = nil,
        treatOpenedAsOutOfStock: Bool? = nil,
        noOwnStock: Bool? = nil,
        defaultConsumeLocationID: Int? = nil,
        moveOnOpen: Bool? = nil,
        autoReprintStockLabel: Bool? = nil,
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
        self.defaultBestBeforeDays = defaultBestBeforeDays
        self.defaultBestBeforeDaysAfterOpen = defaultBestBeforeDaysAfterOpen
        self.defaultBestBeforeDaysAfterFreezing = defaultBestBeforeDaysAfterFreezing
        self.defaultBestBeforeDaysAfterThawing = defaultBestBeforeDaysAfterThawing
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
}

typealias MDProducts = [MDProduct]
