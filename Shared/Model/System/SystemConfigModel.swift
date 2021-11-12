//
//  SystemConfigModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 12.10.20.
//

import Foundation

// MARK: - SystemConfig
struct SystemConfig: Codable {
//    let mode: String
//    let demoDBSuffix: String?
//    let defaultLocale: String
    let currency: String
// TODO Real implementation
//    let calendarFirstDayOfWeek: Int?
//    let calendarShowWeekOfYear: Bool
    let basePath, baseURL: String
//    let stockBarcodeLookupPlugin: String
//    let disableURLRewriting: Bool
//    let entryPage: String
//    let disableAuth: Bool
//    let authClass, reverseProxyAuthHeader, ldapAddress, ldapBaseDN: String
//    let ldapBindDN, ldapBindPw, ldapUserFilter, ldapUidAttr: String
//    let disableBrowserBarcodeCameraScanning: Bool
//    let mealPlanFirstDayOfWeek: String
//    let defaultPermissions: [String]
//    let grocycodeType, labelPrinterWebhook: String
//    let labelPrinterRunServer: Bool
//    let labelPrinterParams: LabelPrinterParams
//    let labelPrinterHookJSON, tprinterIsNetworkPrinter, tprinterPrintQuantityName, tprinterPrintNotes: Bool
//    let tprinterIP: String
//    let tprinterPort: Int
//    let tprinterConnector: String
//    let featureFlagStock, featureFlagShoppinglist, featureFlagRecipes, featureFlagChores: Bool
//    let featureFlagTasks, featureFlagBatteries, featureFlagEquipment, featureFlagCalendar: Bool
//    let featureFlagLabelPrinter, featureFlagStockPriceTracking, featureFlagStockLocationTracking, featureFlagStockBestBeforeDateTracking: Bool
//    let featureFlagStockProductOpenedTracking, featureFlagStockProductFreezing, featureFlagStockBestBeforeDateFieldNumberPad, featureFlagShoppinglistMultipleLists: Bool
//    let featureFlagChoresAssignments, featureFlagThermalPrinter, featureSettingStockCountOpenedProductsAgainstMinimumStockAmount, featureFlagAutoTorchOnWithCamera: Bool
    let locale, userUsername: String
    let userPictureFileName: String?

    enum CodingKeys: String, CodingKey {
//        case mode = "MODE"
//        case demoDBSuffix = "DEMO_DB_SUFFIX"
//        case defaultLocale = "DEFAULT_LOCALE"
        case currency = "CURRENCY"
//        case calendarFirstDayOfWeek = "CALENDAR_FIRST_DAY_OF_WEEK"
//        case calendarShowWeekOfYear = "CALENDAR_SHOW_WEEK_OF_YEAR"
        case basePath = "BASE_PATH"
        case baseURL = "BASE_URL"
//        case stockBarcodeLookupPlugin = "STOCK_BARCODE_LOOKUP_PLUGIN"
//        case disableURLRewriting = "DISABLE_URL_REWRITING"
//        case entryPage = "ENTRY_PAGE"
//        case disableAuth = "DISABLE_AUTH"
//        case authClass = "AUTH_CLASS"
//        case reverseProxyAuthHeader = "REVERSE_PROXY_AUTH_HEADER"
//        case ldapAddress = "LDAP_ADDRESS"
//        case ldapBaseDN = "LDAP_BASE_DN"
//        case ldapBindDN = "LDAP_BIND_DN"
//        case ldapBindPw = "LDAP_BIND_PW"
//        case ldapUserFilter = "LDAP_USER_FILTER"
//        case ldapUidAttr = "LDAP_UID_ATTR"
//        case disableBrowserBarcodeCameraScanning = "DISABLE_BROWSER_BARCODE_CAMERA_SCANNING"
//        case mealPlanFirstDayOfWeek = "MEAL_PLAN_FIRST_DAY_OF_WEEK"
//        case defaultPermissions = "DEFAULT_PERMISSIONS"
//        case grocycodeType = "GROCYCODE_TYPE"
//        case labelPrinterWebhook = "LABEL_PRINTER_WEBHOOK"
//        case labelPrinterRunServer = "LABEL_PRINTER_RUN_SERVER"
//        case labelPrinterParams = "LABEL_PRINTER_PARAMS"
//        case labelPrinterHookJSON = "LABEL_PRINTER_HOOK_JSON"
//        case tprinterIsNetworkPrinter = "TPRINTER_IS_NETWORK_PRINTER"
//        case tprinterPrintQuantityName = "TPRINTER_PRINT_QUANTITY_NAME"
//        case tprinterPrintNotes = "TPRINTER_PRINT_NOTES"
//        case tprinterIP = "TPRINTER_IP"
//        case tprinterPort = "TPRINTER_PORT"
//        case tprinterConnector = "TPRINTER_CONNECTOR"
//        case featureFlagStock = "FEATURE_FLAG_STOCK"
//        case featureFlagShoppinglist = "FEATURE_FLAG_SHOPPINGLIST"
//        case featureFlagRecipes = "FEATURE_FLAG_RECIPES"
//        case featureFlagChores = "FEATURE_FLAG_CHORES"
//        case featureFlagTasks = "FEATURE_FLAG_TASKS"
//        case featureFlagBatteries = "FEATURE_FLAG_BATTERIES"
//        case featureFlagEquipment = "FEATURE_FLAG_EQUIPMENT"
//        case featureFlagCalendar = "FEATURE_FLAG_CALENDAR"
//        case featureFlagLabelPrinter = "FEATURE_FLAG_LABEL_PRINTER"
//        case featureFlagStockPriceTracking = "FEATURE_FLAG_STOCK_PRICE_TRACKING"
//        case featureFlagStockLocationTracking = "FEATURE_FLAG_STOCK_LOCATION_TRACKING"
//        case featureFlagStockBestBeforeDateTracking = "FEATURE_FLAG_STOCK_BEST_BEFORE_DATE_TRACKING"
//        case featureFlagStockProductOpenedTracking = "FEATURE_FLAG_STOCK_PRODUCT_OPENED_TRACKING"
//        case featureFlagStockProductFreezing = "FEATURE_FLAG_STOCK_PRODUCT_FREEZING"
//        case featureFlagStockBestBeforeDateFieldNumberPad = "FEATURE_FLAG_STOCK_BEST_BEFORE_DATE_FIELD_NUMBER_PAD"
//        case featureFlagShoppinglistMultipleLists = "FEATURE_FLAG_SHOPPINGLIST_MULTIPLE_LISTS"
//        case featureFlagChoresAssignments = "FEATURE_FLAG_CHORES_ASSIGNMENTS"
//        case featureFlagThermalPrinter = "FEATURE_FLAG_THERMAL_PRINTER"
//        case featureSettingStockCountOpenedProductsAgainstMinimumStockAmount = "FEATURE_SETTING_STOCK_COUNT_OPENED_PRODUCTS_AGAINST_MINIMUM_STOCK_AMOUNT"
//        case featureFlagAutoTorchOnWithCamera = "FEATURE_FLAG_AUTO_TORCH_ON_WITH_CAMERA"
        case locale = "LOCALE"
        case userUsername = "USER_USERNAME"
        case userPictureFileName = "USER_PICTURE_FILE_NAME"
    }
}

// MARK: - LabelPrinterParams
struct LabelPrinterParams: Codable {
    let fontFamily: String

    enum CodingKeys: String, CodingKey {
        case fontFamily = "font_family"
    }
}
