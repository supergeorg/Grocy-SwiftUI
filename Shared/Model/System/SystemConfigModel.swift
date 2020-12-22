//
//  SystemConfigModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 12.10.20.
//

import Foundation

// MARK: - SystemConfig
struct SystemConfig: Codable {
    let mode, defaultLocale, calendarFirstDayOfWeek: String
    let calendarShowWeekOfYear: Bool
    let currency, basePath: String
    let baseURL: String
    let stockBarcodeLookupPlugin: String
    let disableURLRewriting: Bool
    let entryPage: String
    let disableAuth: Bool
    let authClass, reverseProxyAuthHeader, ldapDomain, ldapAddress: String
    let ldapBaseDN: String
    let disableBrowserBarcodeCameraScanning: Bool
    let mealPlanFirstDayOfWeek: String
    let defaultPermissions: [String]
    let featureFlagStock, featureFlagShoppinglist, featureFlagRecipes, featureFlagChores: Bool
    let featureFlagTasks, featureFlagBatteries, featureFlagEquipment, featureFlagCalendar: Bool
    let featureFlagStockPriceTracking, featureFlagStockLocationTracking, featureFlagStockBestBeforeDateTracking, featureFlagStockProductOpenedTracking: Bool
    let featureFlagStockProductFreezing, featureFlagStockBestBeforeDateFieldNumberPad, featureFlagShoppinglistMultipleLists, featureFlagChoresAssignments: Bool
    let featureSettingStockCountOpenedProductsAgainstMinimumStockAmount, featureFlagAutoTorchOnWithCamera, showAuthViews: Bool
    let userUsername: String
    let userPictureFileName: String?
    let locale: String

    enum CodingKeys: String, CodingKey {
        case mode = "MODE"
        case defaultLocale = "DEFAULT_LOCALE"
        case calendarFirstDayOfWeek = "CALENDAR_FIRST_DAY_OF_WEEK"
        case calendarShowWeekOfYear = "CALENDAR_SHOW_WEEK_OF_YEAR"
        case currency = "CURRENCY"
        case basePath = "BASE_PATH"
        case baseURL = "BASE_URL"
        case stockBarcodeLookupPlugin = "STOCK_BARCODE_LOOKUP_PLUGIN"
        case disableURLRewriting = "DISABLE_URL_REWRITING"
        case entryPage = "ENTRY_PAGE"
        case disableAuth = "DISABLE_AUTH"
        case authClass = "AUTH_CLASS"
        case reverseProxyAuthHeader = "REVERSE_PROXY_AUTH_HEADER"
        case ldapDomain = "LDAP_DOMAIN"
        case ldapAddress = "LDAP_ADDRESS"
        case ldapBaseDN = "LDAP_BASE_DN"
        case disableBrowserBarcodeCameraScanning = "DISABLE_BROWSER_BARCODE_CAMERA_SCANNING"
        case mealPlanFirstDayOfWeek = "MEAL_PLAN_FIRST_DAY_OF_WEEK"
        case defaultPermissions = "DEFAULT_PERMISSIONS"
        case featureFlagStock = "FEATURE_FLAG_STOCK"
        case featureFlagShoppinglist = "FEATURE_FLAG_SHOPPINGLIST"
        case featureFlagRecipes = "FEATURE_FLAG_RECIPES"
        case featureFlagChores = "FEATURE_FLAG_CHORES"
        case featureFlagTasks = "FEATURE_FLAG_TASKS"
        case featureFlagBatteries = "FEATURE_FLAG_BATTERIES"
        case featureFlagEquipment = "FEATURE_FLAG_EQUIPMENT"
        case featureFlagCalendar = "FEATURE_FLAG_CALENDAR"
        case featureFlagStockPriceTracking = "FEATURE_FLAG_STOCK_PRICE_TRACKING"
        case featureFlagStockLocationTracking = "FEATURE_FLAG_STOCK_LOCATION_TRACKING"
        case featureFlagStockBestBeforeDateTracking = "FEATURE_FLAG_STOCK_BEST_BEFORE_DATE_TRACKING"
        case featureFlagStockProductOpenedTracking = "FEATURE_FLAG_STOCK_PRODUCT_OPENED_TRACKING"
        case featureFlagStockProductFreezing = "FEATURE_FLAG_STOCK_PRODUCT_FREEZING"
        case featureFlagStockBestBeforeDateFieldNumberPad = "FEATURE_FLAG_STOCK_BEST_BEFORE_DATE_FIELD_NUMBER_PAD"
        case featureFlagShoppinglistMultipleLists = "FEATURE_FLAG_SHOPPINGLIST_MULTIPLE_LISTS"
        case featureFlagChoresAssignments = "FEATURE_FLAG_CHORES_ASSIGNMENTS"
        case featureSettingStockCountOpenedProductsAgainstMinimumStockAmount = "FEATURE_SETTING_STOCK_COUNT_OPENED_PRODUCTS_AGAINST_MINIMUM_STOCK_AMOUNT"
        case featureFlagAutoTorchOnWithCamera = "FEATURE_FLAG_AUTO_TORCH_ON_WITH_CAMERA"
        case showAuthViews = "SHOW_AUTH_VIEWS"
        case userUsername = "USER_USERNAME"
        case userPictureFileName = "USER_PICTURE_FILE_NAME"
        case locale = "LOCALE"
    }
}

