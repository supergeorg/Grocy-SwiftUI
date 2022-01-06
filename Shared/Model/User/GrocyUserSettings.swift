//
//  GrocyUserSettings.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 03.01.22.
//

import Foundation

// MARK: - GrocyUserSettings
struct GrocyUserSettings: Codable {
    //    let autoReloadOnDBChange: Bool
    //    let nightModeEnabled: Bool
    //    let autoNightModeEnabled, autoNightModeTimeRangeFrom, autoNightModeTimeRangeTo: String
    //    let autoNightModeTimeRangeGoesOverMidnight, currentlyInsideNightModeRange, keepScreenOn, keepScreenOnWhenFullscreenCard: Bool
    let productPresetsLocationID: Int?
    let productPresetsProductGroupID: Int?
    let productPresetsQuID: Int?
    let productPresetsDefaultDueDays: Int?
    let stockDecimalPlacesAmounts: Int?
    let stockDecimalPlacesPrices: Int?
    let stockAutoDecimalSeparatorPrices: Bool?
    let stockDueSoonDays: Int?
    let stockDefaultPurchaseAmount: Int?
    let stockDefaultConsumeAmount: Int?
    let stockDefaultConsumeAmountUseQuickConsumeAmount: Bool?
    //    let scanModeConsumeEnabled: Bool
    //let scanModePurchaseEnabled: Bool
    let showIconOnStockOverviewPageWhenProductIsOnShoppingList: Bool?
    let showPurchasedDateOnPurchase: Bool?
    let showWarningOnPurchaseWhenDueDateIsEarlierThanNext: Bool?
    //    let shoppingListToStockWorkflowAutoSubmitWhenPrefilled, shoppingListShowCalendar, recipeIngredientsGroupByProductGroup: Bool
    //    let choresDueSoonDays: Int
    //    let batteriesDueSoonDays: Int
    //    let tasksDueSoonDays: Int
    //    let showClockInHeader: Bool
    //    let quagga2Numofworkers: Int
    //    let quagga2Halfsample: Bool
    //    let quagga2Patchsize: String
    //    let quagga2Frequency: Int
    //    let quagga2Debug: Bool
    //    let datatablesStateBarcodeTable, datatablesStateBatteriesTable, datatablesStateEquipmentTable, datatablesStateLocationsTable: String
    //    let datatablesStateProductgroupsTable, datatablesStateProductsTable, datatablesStateQuConversionsTable, datatablesStateQuConversionsTableProducts: String
    //    let datatablesStateQuantityunitsTable, datatablesStateShoppingListPrintShadowTable, datatablesStateShoppinglistTable, datatablesStateShoppinglocationsTable: String
    //    let datatablesStateStockJournalTable, datatablesStateStockOverviewTable, datatablesStateStockentriesTable, datatablesStateTaskcategoriesTable: String
    //    let datatablesStateUserentitiesTable, datatablesStateUserfieldsTable, datatablesStateUsersTable, locale: String
    
    enum CodingKeys: String, CodingKey {
        //        case autoReloadOnDBChange = "auto_reload_on_db_change"
        //        case nightModeEnabled = "night_mode_enabled"
        //        case autoNightModeEnabled = "auto_night_mode_enabled"
        //        case autoNightModeTimeRangeFrom = "auto_night_mode_time_range_from"
        //        case autoNightModeTimeRangeTo = "auto_night_mode_time_range_to"
        //        case autoNightModeTimeRangeGoesOverMidnight = "auto_night_mode_time_range_goes_over_midnight"
        //        case currentlyInsideNightModeRange = "currently_inside_night_mode_range"
        //        case keepScreenOn = "keep_screen_on"
        //        case keepScreenOnWhenFullscreenCard = "keep_screen_on_when_fullscreen_card"
        case productPresetsLocationID = "product_presets_location_id"
        case productPresetsProductGroupID = "product_presets_product_group_id"
        case productPresetsQuID = "product_presets_qu_id"
        case productPresetsDefaultDueDays = "product_presets_default_due_days"
        case stockDecimalPlacesAmounts = "stock_decimal_places_amounts"
        case stockDecimalPlacesPrices = "stock_decimal_places_prices"
        case stockAutoDecimalSeparatorPrices = "stock_auto_decimal_separator_prices"
        case stockDueSoonDays = "stock_due_soon_days"
        case stockDefaultPurchaseAmount = "stock_default_purchase_amount"
        case stockDefaultConsumeAmount = "stock_default_consume_amount"
        case stockDefaultConsumeAmountUseQuickConsumeAmount = "stock_default_consume_amount_use_quick_consume_amount"
        //        case scanModeConsumeEnabled = "scan_mode_consume_enabled"
        //        case scanModePurchaseEnabled = "scan_mode_purchase_enabled"
        case showIconOnStockOverviewPageWhenProductIsOnShoppingList = "show_icon_on_stock_overview_page_when_product_is_on_shopping_list"
        case showPurchasedDateOnPurchase = "show_purchased_date_on_purchase"
        case showWarningOnPurchaseWhenDueDateIsEarlierThanNext = "show_warning_on_purchase_when_due_date_is_earlier_than_next"
        //        case shoppingListToStockWorkflowAutoSubmitWhenPrefilled = "shopping_list_to_stock_workflow_auto_submit_when_prefilled"
        //        case shoppingListShowCalendar = "shopping_list_show_calendar"
        //        case recipeIngredientsGroupByProductGroup = "recipe_ingredients_group_by_product_group"
        //        case choresDueSoonDays = "chores_due_soon_days"
        //        case batteriesDueSoonDays = "batteries_due_soon_days"
        //        case tasksDueSoonDays = "tasks_due_soon_days"
        //        case showClockInHeader = "show_clock_in_header"
        //        case quagga2Numofworkers = "quagga2_numofworkers"
        //        case quagga2Halfsample = "quagga2_halfsample"
        //        case quagga2Patchsize = "quagga2_patchsize"
        //        case quagga2Frequency = "quagga2_frequency"
        //        case quagga2Debug = "quagga2_debug"
        //        case datatablesStateBarcodeTable = "datatables_state_barcode-table"
        //        case datatablesStateBatteriesTable = "datatables_state_batteries-table"
        //        case datatablesStateEquipmentTable = "datatables_state_equipment-table"
        //        case datatablesStateLocationsTable = "datatables_state_locations-table"
        //        case datatablesStateProductgroupsTable = "datatables_state_productgroups-table"
        //        case datatablesStateProductsTable = "datatables_state_products-table"
        //        case datatablesStateQuConversionsTable = "datatables_state_qu-conversions-table"
        //        case datatablesStateQuConversionsTableProducts = "datatables_state_qu-conversions-table-products"
        //        case datatablesStateQuantityunitsTable = "datatables_state_quantityunits-table"
        //        case datatablesStateShoppingListPrintShadowTable = "datatables_state_shopping-list-print-shadow-table"
        //        case datatablesStateShoppinglistTable = "datatables_state_shoppinglist-table"
        //        case datatablesStateShoppinglocationsTable = "datatables_state_shoppinglocations-table"
        //        case datatablesStateStockJournalTable = "datatables_state_stock-journal-table"
        //        case datatablesStateStockOverviewTable = "datatables_state_stock-overview-table"
        //        case datatablesStateStockentriesTable = "datatables_state_stockentries-table"
        //        case datatablesStateTaskcategoriesTable = "datatables_state_taskcategories-table"
        //        case datatablesStateUserentitiesTable = "datatables_state_userentities-table"
        //        case datatablesStateUserfieldsTable = "datatables_state_userfields-table"
        //        case datatablesStateUsersTable = "datatables_state_users-table"
        //        case locale
    }
    
    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            do { self.productPresetsLocationID = try container.decodeIfPresent(Int.self, forKey: .productPresetsLocationID) } catch { self.productPresetsLocationID = try Int(container.decodeIfPresent(String.self, forKey: .productPresetsLocationID) ?? "") }
            
            do { self.productPresetsProductGroupID = try container.decodeIfPresent(Int.self, forKey: .productPresetsProductGroupID) } catch { self.productPresetsProductGroupID = try Int(container.decodeIfPresent(String.self, forKey: .productPresetsProductGroupID) ?? "") }
            
            do { self.stockDueSoonDays = try container.decodeIfPresent(Int.self, forKey: .stockDueSoonDays) } catch { self.stockDueSoonDays = try Int(container.decodeIfPresent(String.self, forKey: .stockDueSoonDays) ?? "") }
            
            do { self.productPresetsQuID = try container.decodeIfPresent(Int.self, forKey: .productPresetsQuID) } catch { self.productPresetsQuID = try Int(container.decodeIfPresent(String.self, forKey: .productPresetsQuID) ?? "") }
            
            do { self.productPresetsDefaultDueDays = try container.decodeIfPresent(Int.self, forKey: .productPresetsDefaultDueDays) } catch { self.productPresetsDefaultDueDays = try Int(container.decodeIfPresent(String.self, forKey: .productPresetsDefaultDueDays) ?? "") }
            
            do { self.stockDecimalPlacesAmounts = try container.decodeIfPresent(Int.self, forKey: .stockDecimalPlacesAmounts) } catch { self.stockDecimalPlacesAmounts = try Int(container.decodeIfPresent(String.self, forKey: .stockDecimalPlacesAmounts) ?? "") }
            
            do { self.stockDecimalPlacesPrices = try container.decodeIfPresent(Int.self, forKey: .stockDecimalPlacesPrices) } catch { self.stockDecimalPlacesPrices = try Int(container.decodeIfPresent(String.self, forKey: .stockDecimalPlacesPrices) ?? "") }
            
            do {
                self.stockAutoDecimalSeparatorPrices = try container.decode(Bool.self, forKey: .stockAutoDecimalSeparatorPrices)
            } catch {
                do {
                    self.stockAutoDecimalSeparatorPrices = try container.decodeIfPresent(Int.self, forKey: .stockAutoDecimalSeparatorPrices) == 1
                } catch {
                    self.stockAutoDecimalSeparatorPrices = ["1", "true"].contains(try container.decodeIfPresent(String.self, forKey: .stockAutoDecimalSeparatorPrices))
                }
            }
            
            do { self.stockDefaultPurchaseAmount = try container.decodeIfPresent(Int.self, forKey: .stockDefaultPurchaseAmount) } catch { self.stockDefaultPurchaseAmount = try Int(container.decodeIfPresent(String.self, forKey: .stockDefaultPurchaseAmount) ?? "") }
            
            do { self.stockDefaultConsumeAmount = try container.decodeIfPresent(Int.self, forKey: .stockDefaultConsumeAmount) } catch { self.stockDefaultConsumeAmount = try Int(container.decodeIfPresent(String.self, forKey: .stockDefaultConsumeAmount) ?? "") }
            
            do {
                self.stockDefaultConsumeAmountUseQuickConsumeAmount = try container.decode(Bool.self, forKey: .stockDefaultConsumeAmountUseQuickConsumeAmount)
            } catch {
                do {
                    self.stockDefaultConsumeAmountUseQuickConsumeAmount = try container.decodeIfPresent(Int.self, forKey: .stockDefaultConsumeAmountUseQuickConsumeAmount) == 1
                } catch {
                    self.stockDefaultConsumeAmountUseQuickConsumeAmount = ["1", "true"].contains(try container.decodeIfPresent(String.self, forKey: .stockDefaultConsumeAmountUseQuickConsumeAmount))
                }
            }
            
            do {
                self.showIconOnStockOverviewPageWhenProductIsOnShoppingList = try container.decode(Bool.self, forKey: .showIconOnStockOverviewPageWhenProductIsOnShoppingList)
            } catch {
                do {
                    self.showIconOnStockOverviewPageWhenProductIsOnShoppingList = try container.decodeIfPresent(Int.self, forKey: .showIconOnStockOverviewPageWhenProductIsOnShoppingList) == 1
                } catch {
                    self.showIconOnStockOverviewPageWhenProductIsOnShoppingList = ["1", "true"].contains(try container.decodeIfPresent(String.self, forKey: .showIconOnStockOverviewPageWhenProductIsOnShoppingList))
                }
            }
            
            do {
                self.showPurchasedDateOnPurchase = try container.decode(Bool.self, forKey: .showPurchasedDateOnPurchase)
            } catch {
                do {
                    self.showPurchasedDateOnPurchase = try container.decodeIfPresent(Int.self, forKey: .showPurchasedDateOnPurchase) == 1
                } catch {
                    self.showPurchasedDateOnPurchase = ["1", "true"].contains(try container.decodeIfPresent(String.self, forKey: .showPurchasedDateOnPurchase))
                }
            }
            
            do {
                self.showWarningOnPurchaseWhenDueDateIsEarlierThanNext = try container.decode(Bool.self, forKey: .showWarningOnPurchaseWhenDueDateIsEarlierThanNext)
            } catch {
                do {
                    self.showWarningOnPurchaseWhenDueDateIsEarlierThanNext = try container.decodeIfPresent(Int.self, forKey: .showPurchasedDateOnPurchase) == 1
                } catch {
                    self.showWarningOnPurchaseWhenDueDateIsEarlierThanNext = ["1", "true"].contains(try container.decodeIfPresent(String.self, forKey: .showWarningOnPurchaseWhenDueDateIsEarlierThanNext))
                }
            }
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
}

struct GrocyUserSettingsString: Codable {
    let value: String?
    
    init(value: String) {
        self.value = value
    }
}

struct GrocyUserSettingsInt: Codable {
    let value: Int?
    
    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            do { self.value = try container.decodeIfPresent(Int.self, forKey: .value) } catch { self.value = try Int(container.decodeIfPresent(String.self, forKey: .value) ?? "") }
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
    
    init(value: Int?) {
        self.value = value
    }
}

struct GrocyUserSettingsBool: Codable {
    let value: Bool
    
    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            do {
                self.value = try container.decode(Bool.self, forKey: .value)
            } catch {
                do {
                    self.value = try container.decodeIfPresent(Int.self, forKey: .value) == 1
                } catch {
                    self.value = ["1", "true"].contains(try container.decodeIfPresent(String.self, forKey: .value))
                }
            }
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
    
    init(value: Bool) {
        self.value = value
    }
}
