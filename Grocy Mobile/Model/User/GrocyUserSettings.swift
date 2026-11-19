//
//  GrocyUserSettings.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 03.01.22.
//

import Foundation
import SwiftData

/// The current user's settings (`/user/settings`, Grocy's `DefaultUserSetting`s).
///
/// All optional: a setting the server doesn't send (older version) stays `nil`.
/// The `datatables_state_*` keys are left out on purpose: they hold the web frontend's table layout as JSON and mean nothing to the app.
@Model
class GrocyUserSettings: Codable {
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
    var showIconOnStockOverviewPageWhenProductIsOnShoppingList: Bool?
    var stockOverviewShowAllOutOfStockProducts: Bool?
    var showPurchasedDateOnPurchase: Bool?
    var showWarningOnPurchaseWhenDueDateIsEarlierThanNext: Bool?
    var shoppingListShowCalendar: Bool?
    var shoppingListRoundUp: Bool?
    var shoppingListAutoAddBelowMinStockAmount: Bool?
    var shoppingListAutoAddBelowMinStockAmountListID: Int?
    var shoppingListToStockWorkflowAutoSubmitWhenPrefilled: Bool?
    var recipeIngredientsGroupByProductGroup: Bool?
    var recipesShowIngredientCheckbox: Bool?
    var choresDueSoonDays: Int?
    var choresOverviewSwapTrackingButtons: Bool?
    var batteriesDueSoonDays: Int?
    var tasksDueSoonDays: Int?
    var nightMode: String?
    var autoNightModeEnabled: Bool?
    var autoNightModeTimeRangeFrom: String?
    var autoNightModeTimeRangeTo: String?
    var autoNightModeTimeRangeGoesOverMidnight: Bool?
    var nightModeEnabledInternal: Bool?
    var autoReloadOnDBChange: Bool?
    var showClockInHeader: Bool?
    var keepScreenOn: Bool?
    var keepScreenOnWhenFullscreenCard: Bool?
    var productPresetsDefaultStockLabelType: Int?
    var scanModeConsumeEnabled: Bool?
    var scanModePurchaseEnabled: Bool?
    var shoppingListPrintShowHeader: Bool?
    var shoppingListPrintGroupByProductGroup: Bool?
    var shoppingListPrintLayoutType: String?
    var recipesShowListSideBySide: Bool?
    var calendarColorProducts: String?
    var calendarColorTasks: String?
    var calendarColorChores: String?
    var calendarColorBatteries: String?
    var calendarColorMealPlan: String?
    var locale: String?

    enum CodingKeys: String, CodingKey {
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
        case showIconOnStockOverviewPageWhenProductIsOnShoppingList = "show_icon_on_stock_overview_page_when_product_is_on_shopping_list"
        case stockOverviewShowAllOutOfStockProducts = "stock_overview_show_all_out_of_stock_products"
        case showPurchasedDateOnPurchase = "show_purchased_date_on_purchase"
        case showWarningOnPurchaseWhenDueDateIsEarlierThanNext = "show_warning_on_purchase_when_due_date_is_earlier_than_next"
        case shoppingListShowCalendar = "shopping_list_show_calendar"
        case shoppingListRoundUp = "shopping_list_round_up"
        case shoppingListAutoAddBelowMinStockAmount = "shopping_list_auto_add_below_min_stock_amount"
        case shoppingListAutoAddBelowMinStockAmountListID = "shopping_list_auto_add_below_min_stock_amount_list_id"
        case shoppingListToStockWorkflowAutoSubmitWhenPrefilled = "shopping_list_to_stock_workflow_auto_submit_when_prefilled"
        case recipeIngredientsGroupByProductGroup = "recipe_ingredients_group_by_product_group"
        case recipesShowIngredientCheckbox = "recipes_show_ingredient_checkbox"
        case choresDueSoonDays = "chores_due_soon_days"
        case choresOverviewSwapTrackingButtons = "chores_overview_swap_tracking_buttons"
        case batteriesDueSoonDays = "batteries_due_soon_days"
        case tasksDueSoonDays = "tasks_due_soon_days"
        case nightMode = "night_mode"
        case autoNightModeEnabled = "auto_night_mode_enabled"
        case autoNightModeTimeRangeFrom = "auto_night_mode_time_range_from"
        case autoNightModeTimeRangeTo = "auto_night_mode_time_range_to"
        case autoNightModeTimeRangeGoesOverMidnight = "auto_night_mode_time_range_goes_over_midnight"
        case nightModeEnabledInternal = "night_mode_enabled_internal"
        case autoReloadOnDBChange = "auto_reload_on_db_change"
        case showClockInHeader = "show_clock_in_header"
        case keepScreenOn = "keep_screen_on"
        case keepScreenOnWhenFullscreenCard = "keep_screen_on_when_fullscreen_card"
        case productPresetsDefaultStockLabelType = "product_presets_default_stock_label_type"
        case scanModeConsumeEnabled = "scan_mode_consume_enabled"
        case scanModePurchaseEnabled = "scan_mode_purchase_enabled"
        case shoppingListPrintShowHeader = "shopping_list_print_show_header"
        case shoppingListPrintGroupByProductGroup = "shopping_list_print_group_by_product_group"
        case shoppingListPrintLayoutType = "shopping_list_print_layout_type"
        case recipesShowListSideBySide = "recipes_show_list_side_by_side"
        case calendarColorProducts = "calendar_color_products"
        case calendarColorTasks = "calendar_color_tasks"
        case calendarColorChores = "calendar_color_chores"
        case calendarColorBatteries = "calendar_color_batteries"
        case calendarColorMealPlan = "calendar_color_meal_plan"
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
            self.stockDefaultConsumeAmountUseQuickConsumeAmount = try container.decodeFlexibleBoolIfPresent(
                forKey: .stockDefaultConsumeAmountUseQuickConsumeAmount
            )
            self.showIconOnStockOverviewPageWhenProductIsOnShoppingList = try container.decodeFlexibleBoolIfPresent(
                forKey: .showIconOnStockOverviewPageWhenProductIsOnShoppingList
            )
            self.stockOverviewShowAllOutOfStockProducts = try container.decodeFlexibleBoolIfPresent(forKey: .stockOverviewShowAllOutOfStockProducts)
            self.showPurchasedDateOnPurchase = try container.decodeFlexibleBoolIfPresent(forKey: .showPurchasedDateOnPurchase)
            self.showWarningOnPurchaseWhenDueDateIsEarlierThanNext = try container.decodeFlexibleBoolIfPresent(
                forKey: .showWarningOnPurchaseWhenDueDateIsEarlierThanNext
            )
            self.shoppingListShowCalendar = try container.decodeFlexibleBoolIfPresent(forKey: .shoppingListShowCalendar)
            self.shoppingListRoundUp = try container.decodeFlexibleBoolIfPresent(forKey: .shoppingListRoundUp)
            self.shoppingListAutoAddBelowMinStockAmount = try container.decodeFlexibleBoolIfPresent(forKey: .shoppingListAutoAddBelowMinStockAmount)
            self.shoppingListAutoAddBelowMinStockAmountListID = try container.decodeFlexibleIntIfPresent(forKey: .shoppingListAutoAddBelowMinStockAmountListID)
            self.shoppingListToStockWorkflowAutoSubmitWhenPrefilled = try container.decodeFlexibleBoolIfPresent(
                forKey: .shoppingListToStockWorkflowAutoSubmitWhenPrefilled
            )
            self.recipeIngredientsGroupByProductGroup = try container.decodeFlexibleBoolIfPresent(forKey: .recipeIngredientsGroupByProductGroup)
            self.recipesShowIngredientCheckbox = try container.decodeFlexibleBoolIfPresent(forKey: .recipesShowIngredientCheckbox)
            self.choresDueSoonDays = try container.decodeFlexibleIntIfPresent(forKey: .choresDueSoonDays)
            self.batteriesDueSoonDays = try container.decodeFlexibleIntIfPresent(forKey: .batteriesDueSoonDays)
            self.choresOverviewSwapTrackingButtons = try container.decodeFlexibleBoolIfPresent(forKey: .choresOverviewSwapTrackingButtons)
            self.tasksDueSoonDays = try container.decodeFlexibleIntIfPresent(forKey: .tasksDueSoonDays)
            self.nightMode = try? container.decodeFlexibleString(forKey: .nightMode)
            self.autoNightModeEnabled = try container.decodeFlexibleBoolIfPresent(forKey: .autoNightModeEnabled)
            self.autoNightModeTimeRangeFrom = try? container.decodeFlexibleString(forKey: .autoNightModeTimeRangeFrom)
            self.autoNightModeTimeRangeTo = try? container.decodeFlexibleString(forKey: .autoNightModeTimeRangeTo)
            self.autoNightModeTimeRangeGoesOverMidnight = try container.decodeFlexibleBoolIfPresent(forKey: .autoNightModeTimeRangeGoesOverMidnight)
            self.nightModeEnabledInternal = try container.decodeFlexibleBoolIfPresent(forKey: .nightModeEnabledInternal)
            self.autoReloadOnDBChange = try container.decodeFlexibleBoolIfPresent(forKey: .autoReloadOnDBChange)
            self.showClockInHeader = try container.decodeFlexibleBoolIfPresent(forKey: .showClockInHeader)
            self.keepScreenOn = try container.decodeFlexibleBoolIfPresent(forKey: .keepScreenOn)
            self.keepScreenOnWhenFullscreenCard = try container.decodeFlexibleBoolIfPresent(forKey: .keepScreenOnWhenFullscreenCard)
            self.productPresetsDefaultStockLabelType = try container.decodeFlexibleIntIfPresent(forKey: .productPresetsDefaultStockLabelType)
            self.scanModeConsumeEnabled = try container.decodeFlexibleBoolIfPresent(forKey: .scanModeConsumeEnabled)
            self.scanModePurchaseEnabled = try container.decodeFlexibleBoolIfPresent(forKey: .scanModePurchaseEnabled)
            self.shoppingListPrintShowHeader = try container.decodeFlexibleBoolIfPresent(forKey: .shoppingListPrintShowHeader)
            self.shoppingListPrintGroupByProductGroup = try container.decodeFlexibleBoolIfPresent(forKey: .shoppingListPrintGroupByProductGroup)
            self.shoppingListPrintLayoutType = try? container.decodeFlexibleString(forKey: .shoppingListPrintLayoutType)
            self.recipesShowListSideBySide = try container.decodeFlexibleBoolIfPresent(forKey: .recipesShowListSideBySide)
            self.calendarColorProducts = try? container.decodeFlexibleString(forKey: .calendarColorProducts)
            self.calendarColorTasks = try? container.decodeFlexibleString(forKey: .calendarColorTasks)
            self.calendarColorChores = try? container.decodeFlexibleString(forKey: .calendarColorChores)
            self.calendarColorBatteries = try? container.decodeFlexibleString(forKey: .calendarColorBatteries)
            self.calendarColorMealPlan = try? container.decodeFlexibleString(forKey: .calendarColorMealPlan)
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
        try container.encode(stockOverviewShowAllOutOfStockProducts, forKey: .stockOverviewShowAllOutOfStockProducts)
        try container.encode(showPurchasedDateOnPurchase, forKey: .showPurchasedDateOnPurchase)
        try container.encode(showWarningOnPurchaseWhenDueDateIsEarlierThanNext, forKey: .showWarningOnPurchaseWhenDueDateIsEarlierThanNext)
        try container.encode(shoppingListShowCalendar, forKey: .shoppingListShowCalendar)
        try container.encode(shoppingListRoundUp, forKey: .shoppingListRoundUp)
        try container.encode(shoppingListAutoAddBelowMinStockAmount, forKey: .shoppingListAutoAddBelowMinStockAmount)
        try container.encode(shoppingListAutoAddBelowMinStockAmountListID, forKey: .shoppingListAutoAddBelowMinStockAmountListID)
        try container.encode(shoppingListToStockWorkflowAutoSubmitWhenPrefilled, forKey: .shoppingListToStockWorkflowAutoSubmitWhenPrefilled)
        try container.encode(recipeIngredientsGroupByProductGroup, forKey: .recipeIngredientsGroupByProductGroup)
        try container.encode(recipesShowIngredientCheckbox, forKey: .recipesShowIngredientCheckbox)
        try container.encode(choresDueSoonDays, forKey: .choresDueSoonDays)
        try container.encode(batteriesDueSoonDays, forKey: .batteriesDueSoonDays)
        try container.encode(choresOverviewSwapTrackingButtons, forKey: .choresOverviewSwapTrackingButtons)
        try container.encode(tasksDueSoonDays, forKey: .tasksDueSoonDays)
        try container.encode(nightMode, forKey: .nightMode)
        try container.encode(autoNightModeEnabled, forKey: .autoNightModeEnabled)
        try container.encode(autoNightModeTimeRangeFrom, forKey: .autoNightModeTimeRangeFrom)
        try container.encode(autoNightModeTimeRangeTo, forKey: .autoNightModeTimeRangeTo)
        try container.encode(autoNightModeTimeRangeGoesOverMidnight, forKey: .autoNightModeTimeRangeGoesOverMidnight)
        try container.encode(nightModeEnabledInternal, forKey: .nightModeEnabledInternal)
        try container.encode(autoReloadOnDBChange, forKey: .autoReloadOnDBChange)
        try container.encode(showClockInHeader, forKey: .showClockInHeader)
        try container.encode(keepScreenOn, forKey: .keepScreenOn)
        try container.encode(keepScreenOnWhenFullscreenCard, forKey: .keepScreenOnWhenFullscreenCard)
        try container.encode(productPresetsDefaultStockLabelType, forKey: .productPresetsDefaultStockLabelType)
        try container.encode(scanModeConsumeEnabled, forKey: .scanModeConsumeEnabled)
        try container.encode(scanModePurchaseEnabled, forKey: .scanModePurchaseEnabled)
        try container.encode(shoppingListPrintShowHeader, forKey: .shoppingListPrintShowHeader)
        try container.encode(shoppingListPrintGroupByProductGroup, forKey: .shoppingListPrintGroupByProductGroup)
        try container.encode(shoppingListPrintLayoutType, forKey: .shoppingListPrintLayoutType)
        try container.encode(recipesShowListSideBySide, forKey: .recipesShowListSideBySide)
        try container.encode(calendarColorProducts, forKey: .calendarColorProducts)
        try container.encode(calendarColorTasks, forKey: .calendarColorTasks)
        try container.encode(calendarColorChores, forKey: .calendarColorChores)
        try container.encode(calendarColorBatteries, forKey: .calendarColorBatteries)
        try container.encode(calendarColorMealPlan, forKey: .calendarColorMealPlan)
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
