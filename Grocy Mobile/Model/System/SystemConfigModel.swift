//
//  SystemConfigModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 12.10.20.
//

import Foundation
import SwiftData

// MARK: - SystemConfig
/// The server's configuration (`/system/config`, Grocy's `config.php`).
///
/// Every property added after the first version has a default (Grocy's own default from `config-dist.php`),
/// so the stored config migrates and older servers that don't send a key still decode.
/// `LDAP_BIND_PW` is left out on purpose: it's a password, and the app has no use for it.
@Model
class SystemConfig: Codable {
    var mode: String = "production"
    var defaultLocale: String = "en"
    var currency: String
    var calendarShowWeekOfYear: Bool = true
    var basePath: String
    var baseURL: String
    var stockBarcodeLookupPlugin: String = "OpenFoodFactsBarcodeLookupPlugin"
    var disableURLRewriting: Bool = false
    var entryPage: String = "stock"
    var disableAuth: Bool = false
    var authClass: String = "Grocy\\Middleware\\DefaultAuthMiddleware"
    var reverseProxyAuthHeader: String = "REMOTE_USER"
    var reverseProxyAuthUseEnv: Bool = false
    var ldapAddress: String = ""
    var ldapBaseDN: String = ""
    var ldapBindDN: String = ""
    var ldapUserFilter: String = ""
    var ldapUidAttr: String = ""
    var defaultPermissions: [String] = ["ADMIN"]
    /// `1D` or `2D`.
    var grocycodeType: String = "2D"
    var labelPrinterWebhook: String = ""
    var labelPrinterRunServer: Bool = true
    /// `LABEL_PRINTER_PARAMS.font_family`. Kept as a plain string: SwiftData can't read a Codable struct with optionals back.
    var labelPrinterFontFamily: String? = LabelPrinterParams.defaultFontFamily
    var labelPrinterHookJSON: Bool = true
    var tprinterIsNetworkPrinter: Bool = false
    var tprinterPrintQuantityName: Bool = true
    var tprinterPrintNotes: Bool = true
    var tprinterIP: String = "127.0.0.1"
    var tprinterPort: Int = 9100
    var tprinterConnector: String = "/dev/usb/lp0"
    var featureFlagStock: Bool
    var featureFlagShoppinglist: Bool
    var featureFlagRecipes: Bool
    var featureFlagChores: Bool
    var featureFlagTasks: Bool
    var featureFlagBatteries: Bool
    var featureFlagEquipment: Bool
    var featureFlagCalendar: Bool
    var featureFlagRecipesMealplan: Bool = true
    var featureFlagStockPriceTracking: Bool = true
    /// `0` (Sunday) … `6` (Saturday), or empty for the locale's first day.
    var calendarFirstDayOfWeek: String = ""
    /// `0` (Sunday) … `6` (Saturday), `-1` for today, or empty for `calendarFirstDayOfWeek`.
    var mealPlanFirstDayOfWeek: String = ""
    var energyUnit: String = "kcal"
    var featureFlagLabelPrinter: Bool = false
    var featureFlagStockLocationTracking: Bool = true
    var featureFlagStockBestBeforeDateTracking: Bool = true
    var featureFlagStockProductOpenedTracking: Bool = true
    var featureFlagStockProductFreezing: Bool = true
    var featureFlagStockBestBeforeDateFieldNumberPad: Bool = true
    var featureFlagShoppinglistMultipleLists: Bool = true
    var featureFlagChoresAssignments: Bool = true
    var featureFlagThermalPrinter: Bool = false
    var featureFlagDisableBrowserBarcodeCameraScanning: Bool = false
    var featureFlagAutoTorchOnWithCamera: Bool = true
    var locale: String
    var userUsername: String?
    var userPictureFileName: String?

    enum CodingKeys: String, CodingKey {
        case mode = "MODE"
        case defaultLocale = "DEFAULT_LOCALE"
        case currency = "CURRENCY"
        case calendarShowWeekOfYear = "CALENDAR_SHOW_WEEK_OF_YEAR"
        case basePath = "BASE_PATH"
        case baseURL = "BASE_URL"
        case stockBarcodeLookupPlugin = "STOCK_BARCODE_LOOKUP_PLUGIN"
        case disableURLRewriting = "DISABLE_URL_REWRITING"
        case entryPage = "ENTRY_PAGE"
        case disableAuth = "DISABLE_AUTH"
        case authClass = "AUTH_CLASS"
        case reverseProxyAuthHeader = "REVERSE_PROXY_AUTH_HEADER"
        case reverseProxyAuthUseEnv = "REVERSE_PROXY_AUTH_USE_ENV"
        case ldapAddress = "LDAP_ADDRESS"
        case ldapBaseDN = "LDAP_BASE_DN"
        case ldapBindDN = "LDAP_BIND_DN"
        case ldapUserFilter = "LDAP_USER_FILTER"
        case ldapUidAttr = "LDAP_UID_ATTR"
        case defaultPermissions = "DEFAULT_PERMISSIONS"
        case grocycodeType = "GROCYCODE_TYPE"
        case labelPrinterWebhook = "LABEL_PRINTER_WEBHOOK"
        case labelPrinterRunServer = "LABEL_PRINTER_RUN_SERVER"
        case labelPrinterParams = "LABEL_PRINTER_PARAMS"
        case labelPrinterHookJSON = "LABEL_PRINTER_HOOK_JSON"
        case tprinterIsNetworkPrinter = "TPRINTER_IS_NETWORK_PRINTER"
        case tprinterPrintQuantityName = "TPRINTER_PRINT_QUANTITY_NAME"
        case tprinterPrintNotes = "TPRINTER_PRINT_NOTES"
        case tprinterIP = "TPRINTER_IP"
        case tprinterPort = "TPRINTER_PORT"
        case tprinterConnector = "TPRINTER_CONNECTOR"
        case featureFlagStock = "FEATURE_FLAG_STOCK"
        case featureFlagShoppinglist = "FEATURE_FLAG_SHOPPINGLIST"
        case featureFlagRecipes = "FEATURE_FLAG_RECIPES"
        case featureFlagChores = "FEATURE_FLAG_CHORES"
        case featureFlagTasks = "FEATURE_FLAG_TASKS"
        case featureFlagBatteries = "FEATURE_FLAG_BATTERIES"
        case featureFlagEquipment = "FEATURE_FLAG_EQUIPMENT"
        case featureFlagCalendar = "FEATURE_FLAG_CALENDAR"
        case featureFlagRecipesMealplan = "FEATURE_FLAG_RECIPES_MEALPLAN"
        case featureFlagStockPriceTracking = "FEATURE_FLAG_STOCK_PRICE_TRACKING"
        case calendarFirstDayOfWeek = "CALENDAR_FIRST_DAY_OF_WEEK"
        case mealPlanFirstDayOfWeek = "MEAL_PLAN_FIRST_DAY_OF_WEEK"
        case energyUnit = "ENERGY_UNIT"
        case featureFlagLabelPrinter = "FEATURE_FLAG_LABEL_PRINTER"
        case featureFlagStockLocationTracking = "FEATURE_FLAG_STOCK_LOCATION_TRACKING"
        case featureFlagStockBestBeforeDateTracking = "FEATURE_FLAG_STOCK_BEST_BEFORE_DATE_TRACKING"
        case featureFlagStockProductOpenedTracking = "FEATURE_FLAG_STOCK_PRODUCT_OPENED_TRACKING"
        case featureFlagStockProductFreezing = "FEATURE_FLAG_STOCK_PRODUCT_FREEZING"
        case featureFlagStockBestBeforeDateFieldNumberPad = "FEATURE_FLAG_STOCK_BEST_BEFORE_DATE_FIELD_NUMBER_PAD"
        case featureFlagShoppinglistMultipleLists = "FEATURE_FLAG_SHOPPINGLIST_MULTIPLE_LISTS"
        case featureFlagChoresAssignments = "FEATURE_FLAG_CHORES_ASSIGNMENTS"
        case featureFlagThermalPrinter = "FEATURE_FLAG_THERMAL_PRINTER"
        case featureFlagDisableBrowserBarcodeCameraScanning = "FEATURE_FLAG_DISABLE_BROWSER_BARCODE_CAMERA_SCANNING"
        case featureFlagAutoTorchOnWithCamera = "FEATURE_FLAG_AUTO_TORCH_ON_WITH_CAMERA"
        case locale = "LOCALE"
        case userUsername = "USER_USERNAME"
        case userPictureFileName = "USER_PICTURE_FILE_NAME"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            /// A string that may be missing, `null` or a number; falls back to `defaultValue`.
            func string(_ key: CodingKeys, _ defaultValue: String) -> String {
                (try? container.decodeFlexibleString(forKey: key)) ?? defaultValue
            }
            func bool(_ key: CodingKeys, _ defaultValue: Bool) throws -> Bool {
                try container.decodeFlexibleBoolIfPresent(forKey: key) ?? defaultValue
            }

            self.mode = string(.mode, "production")
            self.defaultLocale = string(.defaultLocale, "en")
            self.currency = try container.decode(String.self, forKey: .currency)
            self.calendarShowWeekOfYear = try bool(.calendarShowWeekOfYear, true)
            self.basePath = try container.decode(String.self, forKey: .basePath)
            self.baseURL = try container.decode(String.self, forKey: .baseURL)
            self.stockBarcodeLookupPlugin = string(.stockBarcodeLookupPlugin, "OpenFoodFactsBarcodeLookupPlugin")
            self.disableURLRewriting = try bool(.disableURLRewriting, false)
            self.entryPage = string(.entryPage, "stock")
            self.disableAuth = try bool(.disableAuth, false)
            self.authClass = string(.authClass, "Grocy\\Middleware\\DefaultAuthMiddleware")
            self.reverseProxyAuthHeader = string(.reverseProxyAuthHeader, "REMOTE_USER")
            self.reverseProxyAuthUseEnv = try bool(.reverseProxyAuthUseEnv, false)
            self.ldapAddress = string(.ldapAddress, "")
            self.ldapBaseDN = string(.ldapBaseDN, "")
            self.ldapBindDN = string(.ldapBindDN, "")
            self.ldapUserFilter = string(.ldapUserFilter, "")
            self.ldapUidAttr = string(.ldapUidAttr, "")
            self.defaultPermissions = (try? container.decodeIfPresent([String].self, forKey: .defaultPermissions)) ?? ["ADMIN"]
            self.grocycodeType = string(.grocycodeType, "2D")
            self.labelPrinterWebhook = string(.labelPrinterWebhook, "")
            self.labelPrinterRunServer = try bool(.labelPrinterRunServer, true)
            self.labelPrinterFontFamily =
                (try? container.decodeIfPresent(LabelPrinterParams.self, forKey: .labelPrinterParams))?.fontFamily ?? LabelPrinterParams.defaultFontFamily
            self.labelPrinterHookJSON = try bool(.labelPrinterHookJSON, true)
            self.tprinterIsNetworkPrinter = try bool(.tprinterIsNetworkPrinter, false)
            self.tprinterPrintQuantityName = try bool(.tprinterPrintQuantityName, true)
            self.tprinterPrintNotes = try bool(.tprinterPrintNotes, true)
            self.tprinterIP = string(.tprinterIP, "127.0.0.1")
            self.tprinterPort = try container.decodeFlexibleIntIfPresent(forKey: .tprinterPort) ?? 9100
            self.tprinterConnector = string(.tprinterConnector, "/dev/usb/lp0")

            self.featureFlagStock = try container.decodeFlexibleBool(forKey: .featureFlagStock)
            self.featureFlagShoppinglist = try container.decodeFlexibleBool(forKey: .featureFlagShoppinglist)
            self.featureFlagRecipes = try container.decodeFlexibleBool(forKey: .featureFlagRecipes)
            self.featureFlagChores = try container.decodeFlexibleBool(forKey: .featureFlagChores)
            self.featureFlagTasks = try container.decodeFlexibleBool(forKey: .featureFlagTasks)
            self.featureFlagBatteries = try container.decodeFlexibleBool(forKey: .featureFlagBatteries)
            self.featureFlagEquipment = try container.decodeFlexibleBool(forKey: .featureFlagEquipment)
            self.featureFlagCalendar = try container.decodeFlexibleBool(forKey: .featureFlagCalendar)
            self.featureFlagRecipesMealplan = try bool(.featureFlagRecipesMealplan, true)
            self.featureFlagStockPriceTracking = try bool(.featureFlagStockPriceTracking, true)
            self.calendarFirstDayOfWeek = string(.calendarFirstDayOfWeek, "")
            self.mealPlanFirstDayOfWeek = string(.mealPlanFirstDayOfWeek, "")
            self.energyUnit = string(.energyUnit, "kcal")
            self.featureFlagLabelPrinter = try bool(.featureFlagLabelPrinter, false)
            self.featureFlagStockLocationTracking = try bool(.featureFlagStockLocationTracking, true)
            self.featureFlagStockBestBeforeDateTracking = try bool(.featureFlagStockBestBeforeDateTracking, true)
            self.featureFlagStockProductOpenedTracking = try bool(.featureFlagStockProductOpenedTracking, true)
            self.featureFlagStockProductFreezing = try bool(.featureFlagStockProductFreezing, true)
            self.featureFlagStockBestBeforeDateFieldNumberPad = try bool(.featureFlagStockBestBeforeDateFieldNumberPad, true)
            self.featureFlagShoppinglistMultipleLists = try bool(.featureFlagShoppinglistMultipleLists, true)
            self.featureFlagChoresAssignments = try bool(.featureFlagChoresAssignments, true)
            self.featureFlagThermalPrinter = try bool(.featureFlagThermalPrinter, false)
            self.featureFlagDisableBrowserBarcodeCameraScanning = try bool(.featureFlagDisableBrowserBarcodeCameraScanning, false)
            self.featureFlagAutoTorchOnWithCamera = try bool(.featureFlagAutoTorchOnWithCamera, true)

            self.locale = try container.decode(String.self, forKey: .locale)
            self.userUsername = try? container.decodeIfPresent(String.self, forKey: .userUsername)
            self.userPictureFileName = try? container.decodeIfPresent(String.self, forKey: .userPictureFileName)
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mode, forKey: .mode)
        try container.encode(defaultLocale, forKey: .defaultLocale)
        try container.encode(currency, forKey: .currency)
        try container.encode(calendarShowWeekOfYear, forKey: .calendarShowWeekOfYear)
        try container.encode(basePath, forKey: .basePath)
        try container.encode(baseURL, forKey: .baseURL)
        try container.encode(stockBarcodeLookupPlugin, forKey: .stockBarcodeLookupPlugin)
        try container.encode(disableURLRewriting, forKey: .disableURLRewriting)
        try container.encode(entryPage, forKey: .entryPage)
        try container.encode(disableAuth, forKey: .disableAuth)
        try container.encode(authClass, forKey: .authClass)
        try container.encode(reverseProxyAuthHeader, forKey: .reverseProxyAuthHeader)
        try container.encode(reverseProxyAuthUseEnv, forKey: .reverseProxyAuthUseEnv)
        try container.encode(ldapAddress, forKey: .ldapAddress)
        try container.encode(ldapBaseDN, forKey: .ldapBaseDN)
        try container.encode(ldapBindDN, forKey: .ldapBindDN)
        try container.encode(ldapUserFilter, forKey: .ldapUserFilter)
        try container.encode(ldapUidAttr, forKey: .ldapUidAttr)
        try container.encode(defaultPermissions, forKey: .defaultPermissions)
        try container.encode(grocycodeType, forKey: .grocycodeType)
        try container.encode(labelPrinterWebhook, forKey: .labelPrinterWebhook)
        try container.encode(labelPrinterRunServer, forKey: .labelPrinterRunServer)
        try container.encode(LabelPrinterParams(fontFamily: labelPrinterFontFamily), forKey: .labelPrinterParams)
        try container.encode(labelPrinterHookJSON, forKey: .labelPrinterHookJSON)
        try container.encode(tprinterIsNetworkPrinter, forKey: .tprinterIsNetworkPrinter)
        try container.encode(tprinterPrintQuantityName, forKey: .tprinterPrintQuantityName)
        try container.encode(tprinterPrintNotes, forKey: .tprinterPrintNotes)
        try container.encode(tprinterIP, forKey: .tprinterIP)
        try container.encode(tprinterPort, forKey: .tprinterPort)
        try container.encode(tprinterConnector, forKey: .tprinterConnector)
        try container.encode(featureFlagStock, forKey: .featureFlagStock)
        try container.encode(featureFlagShoppinglist, forKey: .featureFlagShoppinglist)
        try container.encode(featureFlagRecipes, forKey: .featureFlagRecipes)
        try container.encode(featureFlagChores, forKey: .featureFlagChores)
        try container.encode(featureFlagTasks, forKey: .featureFlagTasks)
        try container.encode(featureFlagBatteries, forKey: .featureFlagBatteries)
        try container.encode(featureFlagEquipment, forKey: .featureFlagEquipment)
        try container.encode(featureFlagCalendar, forKey: .featureFlagCalendar)
        try container.encode(featureFlagRecipesMealplan, forKey: .featureFlagRecipesMealplan)
        try container.encode(featureFlagStockPriceTracking, forKey: .featureFlagStockPriceTracking)
        try container.encode(calendarFirstDayOfWeek, forKey: .calendarFirstDayOfWeek)
        try container.encode(mealPlanFirstDayOfWeek, forKey: .mealPlanFirstDayOfWeek)
        try container.encode(energyUnit, forKey: .energyUnit)
        try container.encode(featureFlagLabelPrinter, forKey: .featureFlagLabelPrinter)
        try container.encode(featureFlagStockLocationTracking, forKey: .featureFlagStockLocationTracking)
        try container.encode(featureFlagStockBestBeforeDateTracking, forKey: .featureFlagStockBestBeforeDateTracking)
        try container.encode(featureFlagStockProductOpenedTracking, forKey: .featureFlagStockProductOpenedTracking)
        try container.encode(featureFlagStockProductFreezing, forKey: .featureFlagStockProductFreezing)
        try container.encode(featureFlagStockBestBeforeDateFieldNumberPad, forKey: .featureFlagStockBestBeforeDateFieldNumberPad)
        try container.encode(featureFlagShoppinglistMultipleLists, forKey: .featureFlagShoppinglistMultipleLists)
        try container.encode(featureFlagChoresAssignments, forKey: .featureFlagChoresAssignments)
        try container.encode(featureFlagThermalPrinter, forKey: .featureFlagThermalPrinter)
        try container.encode(featureFlagDisableBrowserBarcodeCameraScanning, forKey: .featureFlagDisableBrowserBarcodeCameraScanning)
        try container.encode(featureFlagAutoTorchOnWithCamera, forKey: .featureFlagAutoTorchOnWithCamera)
        try container.encode(locale, forKey: .locale)
        try container.encode(userUsername, forKey: .userUsername)
        try container.encode(userPictureFileName, forKey: .userPictureFileName)
    }
}

// MARK: - LabelPrinterParams
/// Extra parameters Grocy sends to the label printer webhook (only used for decoding and encoding `SystemConfig`).
nonisolated struct LabelPrinterParams: Codable, Equatable, Sendable {
    static let defaultFontFamily = "Source Sans Pro (Regular)"

    var fontFamily: String?

    enum CodingKeys: String, CodingKey {
        case fontFamily = "font_family"
    }

    init(fontFamily: String? = LabelPrinterParams.defaultFontFamily) {
        self.fontFamily = fontFamily
    }
}
