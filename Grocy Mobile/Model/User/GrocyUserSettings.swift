//
//  GrocyUserSettings.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 03.01.22.
//

import Foundation
import SwiftData

@Model
class GrocyUserSettings: Codable {
    //    var autoReloadOnDBChange: Bool
    //    var nightModeEnabled: Bool
    //    var autoNightModeEnabled, autoNightModeTimeRangeFrom, autoNightModeTimeRangeTo: String
    //    var autoNightModeTimeRangeGoesOverMidnight, currentlyInsideNightModeRange, keepScreenOn, keepScreenOnWhenFullscreenCard: Bool
    var productPresetsLocationID: Int?
    var productPresetsProductGroupID: Int?
    var productPresetsQuID: Int?
    var productPresetsDefaultDueDays: Int?
    var productPresetsTreatOpenedAsOutOfStock: Bool?
    var stockDecimalPlacesAmounts: Int?
    var stockDecimalPlacesPrices: Int?
    var stockDecimalPlacesPricesInput: Int?
    var stockDecimalPlacesPricesDisplay: Int?
    var stockAutoDecimalSeparatorPrices: Bool?
    var stockDueSoonDays: Int?
    var stockDefaultPurchaseAmount: Double?
    var stockDefaultConsumeAmount: Double?
    var stockDefaultConsumeAmountUseQuickConsumeAmount: Bool?
    //    var scanModeConsumeEnabled: Bool
    //var scanModePurchaseEnabled: Bool
    var showIconOnStockOverviewPageWhenProductIsOnShoppingList: Bool?
    var showPurchasedDateOnPurchase: Bool?
    var showWarningOnPurchaseWhenDueDateIsEarlierThanNext: Bool?
    var shoppingListShowCalendar: Bool?
    var shoppingListAutoAddBelowMinStockAmount: Bool?
    var shoppingListAutoAddBelowMinStockAmountListID: Int?
    var shoppingListToStockWorkflowAutoSubmitWhenPrefilled: Bool?
    //    var recipeIngredientsGroupByProductGroup: Bool
    var choresDueSoonDays: Int?
    var choresOverviewSwapTrackingButtons: Bool?
    var batteriesDueSoonDays: Int?
    var tasksDueSoonDays: Int?
    //    var showClockInHeader: Bool
    //    var quagga2Numofworkers: Int
    //    var quagga2Halfsample: Bool
    //    var quagga2Patchsize: String
    //    var quagga2Frequency: Int
    //    var quagga2Debug: Bool
    //    var datatablesStateBarcodeTable, datatablesStateBatteriesTable, datatablesStateEquipmentTable, datatablesStateLocationsTable: String
    //    var datatablesStateProductgroupsTable, datatablesStateProductsTable, datatablesStateQuConversionsTable, datatablesStateQuConversionsTableProducts: String
    //    var datatablesStateQuantityunitsTable, datatablesStateShoppingListPrintShadowTable, datatablesStateShoppinglistTable, datatablesStateStoresTable: String
    //    var datatablesStateStockJournalTable, datatablesStateStockOverviewTable, datatablesStateStockentriesTable, datatablesStateTaskcategoriesTable: String
    //    var datatablesStateUserentitiesTable, datatablesStateUserfieldsTable, datatablesStateUsersTable
    var locale: String?

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
        case productPresetsTreatOpenedAsOutOfStock = "product_presets_treat_opened_as_out_of_stock"
        case stockDecimalPlacesAmounts = "stock_decimal_places_amounts"
        case stockDecimalPlacesPrices = "stock_decimal_places_prices"
        case stockDecimalPlacesPricesInput = "stock_decimal_places_prices_input"
        case stockDecimalPlacesPricesDisplay = "stock_decimal_places_prices_display"
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
        case shoppingListShowCalendar = "shopping_list_show_calendar"
        case shoppingListAutoAddBelowMinStockAmount = "shopping_list_auto_add_below_min_stock_amount"
        case shoppingListAutoAddBelowMinStockAmountListID = "shopping_list_auto_add_below_min_stock_amount_list_id"
        case shoppingListToStockWorkflowAutoSubmitWhenPrefilled = "shopping_list_to_stock_workflow_auto_submit_when_prefilled"
        //        case recipeIngredientsGroupByProductGroup = "recipe_ingredients_group_by_product_group"
        case choresDueSoonDays = "chores_due_soon_days"
        case choresOverviewSwapTrackingButtons = "chores_overview_swap_tracking_buttons"
        case batteriesDueSoonDays = "batteries_due_soon_days"
        case tasksDueSoonDays = "tasks_due_soon_days"
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
        //        case datatablesStateStoresTable = "datatables_state_stores-table"
        //        case datatablesStateStockJournalTable = "datatables_state_stock-journal-table"
        //        case datatablesStateStockOverviewTable = "datatables_state_stock-overview-table"
        //        case datatablesStateStockentriesTable = "datatables_state_stockentries-table"
        //        case datatablesStateTaskcategoriesTable = "datatables_state_taskcategories-table"
        //        case datatablesStateUserentitiesTable = "datatables_state_userentities-table"
        //        case datatablesStateUserfieldsTable = "datatables_state_userfields-table"
        //        case datatablesStateUsersTable = "datatables_state_users-table"
        case locale
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.productPresetsLocationID = try container.decodeFlexibleIntIfPresent(forKey: .productPresetsLocationID)
            self.productPresetsProductGroupID = try container.decodeFlexibleIntIfPresent(forKey: .productPresetsProductGroupID)
            self.stockDueSoonDays = try container.decodeFlexibleIntIfPresent(forKey: .stockDueSoonDays)
            self.productPresetsQuID = try container.decodeFlexibleIntIfPresent(forKey: .productPresetsQuID)
            self.productPresetsDefaultDueDays = try container.decodeFlexibleIntIfPresent(forKey: .productPresetsDefaultDueDays)
            self.productPresetsTreatOpenedAsOutOfStock = try container.decodeFlexibleBoolIfPresent(forKey: .productPresetsTreatOpenedAsOutOfStock)
            self.stockDecimalPlacesAmounts = try container.decodeFlexibleIntIfPresent(forKey: .stockDecimalPlacesAmounts)
            self.stockDecimalPlacesPrices = try container.decodeFlexibleIntIfPresent(forKey: .stockDecimalPlacesPrices)
            self.stockDecimalPlacesPricesInput = try container.decodeFlexibleIntIfPresent(forKey: .stockDecimalPlacesPricesInput)
            self.stockDecimalPlacesPricesDisplay = try container.decodeFlexibleIntIfPresent(forKey: .stockDecimalPlacesPricesDisplay)
            self.stockAutoDecimalSeparatorPrices = try container.decodeFlexibleBoolIfPresent(forKey: .stockAutoDecimalSeparatorPrices)
            self.stockDefaultPurchaseAmount = try container.decodeFlexibleDoubleIfPresent(forKey: .stockDefaultPurchaseAmount)
            self.stockDefaultConsumeAmount = try container.decodeFlexibleDoubleIfPresent(forKey: .stockDefaultConsumeAmount)
            self.stockDefaultConsumeAmountUseQuickConsumeAmount = try container.decodeFlexibleBoolIfPresent(forKey: .stockDefaultConsumeAmountUseQuickConsumeAmount)
            self.showIconOnStockOverviewPageWhenProductIsOnShoppingList = try container.decodeFlexibleBoolIfPresent(forKey: .showIconOnStockOverviewPageWhenProductIsOnShoppingList)
            self.showPurchasedDateOnPurchase = try container.decodeFlexibleBoolIfPresent(forKey: .showPurchasedDateOnPurchase)
            self.showWarningOnPurchaseWhenDueDateIsEarlierThanNext = try container.decodeFlexibleBoolIfPresent(forKey: .showWarningOnPurchaseWhenDueDateIsEarlierThanNext)
            self.shoppingListShowCalendar = try container.decodeFlexibleBoolIfPresent(forKey: .shoppingListShowCalendar)
            self.shoppingListAutoAddBelowMinStockAmount = try container.decodeFlexibleBoolIfPresent(forKey: .shoppingListAutoAddBelowMinStockAmount)
            self.shoppingListAutoAddBelowMinStockAmountListID = try container.decodeFlexibleIntIfPresent(forKey: .shoppingListAutoAddBelowMinStockAmountListID)
            self.shoppingListToStockWorkflowAutoSubmitWhenPrefilled = try container.decodeFlexibleBoolIfPresent(forKey: .shoppingListToStockWorkflowAutoSubmitWhenPrefilled)
            self.choresDueSoonDays = try container.decodeFlexibleIntIfPresent(forKey: .choresDueSoonDays)
            self.batteriesDueSoonDays = try container.decodeFlexibleIntIfPresent(forKey: .batteriesDueSoonDays)
            self.choresOverviewSwapTrackingButtons = try container.decodeFlexibleBoolIfPresent(forKey: .choresOverviewSwapTrackingButtons)
            self.tasksDueSoonDays = try container.decodeFlexibleIntIfPresent(forKey: .tasksDueSoonDays)
            self.locale = try container.decodeIfPresent(String.self, forKey: .locale)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(productPresetsLocationID, forKey: .productPresetsLocationID)
        try container.encode(productPresetsProductGroupID, forKey: .productPresetsProductGroupID)
        try container.encode(productPresetsQuID, forKey: .productPresetsQuID)
        try container.encode(productPresetsDefaultDueDays, forKey: .productPresetsDefaultDueDays)
        try container.encode(productPresetsTreatOpenedAsOutOfStock, forKey: .productPresetsTreatOpenedAsOutOfStock)
        try container.encode(stockDecimalPlacesAmounts, forKey: .stockDecimalPlacesAmounts)
        try container.encode(stockDecimalPlacesPrices, forKey: .stockDecimalPlacesPrices)
        try container.encode(stockDecimalPlacesPricesInput, forKey: .stockDecimalPlacesPricesInput)
        try container.encode(stockDecimalPlacesPricesDisplay, forKey: .stockDecimalPlacesPricesDisplay)
        try container.encode(stockAutoDecimalSeparatorPrices, forKey: .stockAutoDecimalSeparatorPrices)
        try container.encode(stockDueSoonDays, forKey: .stockDueSoonDays)
        try container.encode(stockDefaultPurchaseAmount, forKey: .stockDefaultPurchaseAmount)
        try container.encode(stockDefaultConsumeAmount, forKey: .stockDefaultConsumeAmount)
        try container.encode(stockDefaultConsumeAmountUseQuickConsumeAmount, forKey: .stockDefaultConsumeAmountUseQuickConsumeAmount)
        try container.encode(showIconOnStockOverviewPageWhenProductIsOnShoppingList, forKey: .showIconOnStockOverviewPageWhenProductIsOnShoppingList)
        try container.encode(showPurchasedDateOnPurchase, forKey: .showPurchasedDateOnPurchase)
        try container.encode(showWarningOnPurchaseWhenDueDateIsEarlierThanNext, forKey: .showWarningOnPurchaseWhenDueDateIsEarlierThanNext)
        try container.encode(shoppingListShowCalendar, forKey: .shoppingListShowCalendar)
        try container.encode(shoppingListAutoAddBelowMinStockAmount, forKey: .shoppingListAutoAddBelowMinStockAmount)
        try container.encode(shoppingListAutoAddBelowMinStockAmountListID, forKey: .shoppingListAutoAddBelowMinStockAmountListID)
        try container.encode(shoppingListToStockWorkflowAutoSubmitWhenPrefilled, forKey: .shoppingListToStockWorkflowAutoSubmitWhenPrefilled)
        try container.encode(choresDueSoonDays, forKey: .choresDueSoonDays)
        try container.encode(batteriesDueSoonDays, forKey: .batteriesDueSoonDays)
        try container.encode(choresOverviewSwapTrackingButtons, forKey: .choresOverviewSwapTrackingButtons)
        try container.encode(tasksDueSoonDays, forKey: .tasksDueSoonDays)
        try container.encode(locale, forKey: .locale)
    }
}

typealias GrocyUserSettingsList = [GrocyUserSettings]

class GrocyUserSettingsString: Codable {
    var value: String?

    required init(value: String) {
        self.value = value
    }
}

class GrocyUserSettingsInt: Codable {
    var value: Int?

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.value = try container.decodeFlexibleIntIfPresent(forKey: .value)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(value: Int?) {
        self.value = value
    }
}

class GrocyUserSettingsDouble: Codable {
    var value: Double?

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.value = try container.decodeFlexibleDoubleIfPresent(forKey: .value)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(value: Double?) {
        self.value = value
    }
}

class GrocyUserSettingsBool: Codable {
    var value: Bool

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.value = try container.decodeFlexibleBool(forKey: .value)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(value: Bool) {
        self.value = value
    }
}
