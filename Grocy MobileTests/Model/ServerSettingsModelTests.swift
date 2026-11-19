//
//  ServerSettingsModelTests.swift
//  Grocy MobileTests
//
//  Created by Georg Meißner on 19.11.26.
//

import Foundation
import SwiftData
import Testing

@testable import Grocy_Mobile

/// Decoding of the server configuration, the user settings and the price history.
@MainActor
@Suite("Server configuration, user settings and price history")
struct ServerSettingsModelTests {
    private func fixture(_ name: String) throws -> Data {
        let url = try #require(Bundle.main.url(forResource: name, withExtension: "json"), "Missing fixture \(name).json")
        return try Data(contentsOf: url)
    }

    private func decode<T: Decodable>(_ type: T.Type, json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    /// The keys an old server (or a minimal config) still sends; everything else falls back to Grocy's defaults.
    private let minimalConfig = """
        {"CURRENCY": "EUR", "BASE_PATH": "", "BASE_URL": "/", "LOCALE": "de",
         "FEATURE_FLAG_STOCK": true, "FEATURE_FLAG_SHOPPINGLIST": true, "FEATURE_FLAG_RECIPES": true, "FEATURE_FLAG_CHORES": true,
         "FEATURE_FLAG_TASKS": true, "FEATURE_FLAG_BATTERIES": true, "FEATURE_FLAG_EQUIPMENT": true, "FEATURE_FLAG_CALENDAR": true}
        """

    // MARK: - SystemConfig

    @Test("The system config fixture decodes every setting")
    func systemConfigFixture() throws {
        let config = try JSONDecoder().decode(SystemConfig.self, from: fixture("system__config"))

        #expect(config.mode == "demo")
        #expect(config.defaultLocale == "en")
        #expect(config.calendarShowWeekOfYear)
        #expect(config.stockBarcodeLookupPlugin == "OpenFoodFactsBarcodeLookupPlugin")
        #expect(config.entryPage == "stock")
        #expect(config.disableAuth == false)
        #expect(config.authClass == "Grocy\\Middleware\\DefaultAuthMiddleware")
        #expect(config.reverseProxyAuthHeader == "REMOTE_USER")
        #expect(config.defaultPermissions == ["ADMIN"])
        #expect(config.grocycodeType == "2D")
        #expect(config.labelPrinterFontFamily == "Source Sans Pro (Regular)")
        #expect(config.labelPrinterRunServer)
        #expect(config.tprinterIP == "127.0.0.1")
        #expect(config.tprinterPort == 9100)
        #expect(config.tprinterConnector == "/dev/usb/lp0")
        #expect(config.featureFlagLabelPrinter == false)
        #expect(config.featureFlagStockLocationTracking)
        #expect(config.featureFlagStockBestBeforeDateTracking)
        #expect(config.featureFlagStockProductOpenedTracking)
        #expect(config.featureFlagStockProductFreezing)
        #expect(config.featureFlagShoppinglistMultipleLists)
        #expect(config.featureFlagChoresAssignments)
        #expect(config.featureFlagThermalPrinter == false)
        #expect(config.featureFlagDisableBrowserBarcodeCameraScanning == false)
        #expect(config.featureFlagAutoTorchOnWithCamera)
        #expect(config.userUsername == "Demo User")
        #expect(config.userPictureFileName == nil)
    }

    @Test("A config without the newer keys falls back to Grocy's defaults")
    func systemConfigDefaults() throws {
        let config = try decode(SystemConfig.self, json: minimalConfig)

        #expect(config.currency == "EUR")
        #expect(config.mode == "production")
        #expect(config.calendarShowWeekOfYear)
        #expect(config.defaultPermissions == ["ADMIN"])
        #expect(config.labelPrinterFontFamily == "Source Sans Pro (Regular)")
        #expect(config.tprinterPort == 9100)
        #expect(config.featureFlagStockPriceTracking)
        #expect(config.featureFlagStockLocationTracking)
        #expect(config.featureFlagShoppinglistMultipleLists)
        #expect(config.featureFlagLabelPrinter == false)
        #expect(config.energyUnit == "kcal")
    }

    @Test("Flags and numbers sent as strings or 0/1 decode")
    func systemConfigFlexibleValues() throws {
        var json = minimalConfig.dropLast().description
        json += """
            , "FEATURE_FLAG_SHOPPINGLIST_MULTIPLE_LISTS": "0", "FEATURE_FLAG_STOCK_PRODUCT_FREEZING": 0,
            "FEATURE_FLAG_LABEL_PRINTER": "1", "TPRINTER_PORT": "9101", "LABEL_PRINTER_PARAMS": [], "DEFAULT_PERMISSIONS": ["STOCK", "SHOPPINGLIST"]}
            """
        let config = try decode(SystemConfig.self, json: json)

        #expect(config.featureFlagShoppinglistMultipleLists == false)
        #expect(config.featureFlagStockProductFreezing == false)
        #expect(config.featureFlagLabelPrinter)
        #expect(config.tprinterPort == 9101)
        // PHP encodes an empty array as `[]`, not `{}`.
        #expect(config.labelPrinterFontFamily == "Source Sans Pro (Regular)")
        #expect(config.defaultPermissions == ["STOCK", "SHOPPINGLIST"])
    }

    @Test("The LDAP bind password is neither kept nor encoded")
    func systemConfigDropsLDAPPassword() throws {
        var json = minimalConfig.dropLast().description
        json += #", "LDAP_BIND_DN": "CN=grocy", "LDAP_BIND_PW": "secret"}"#
        let config = try decode(SystemConfig.self, json: json)
        #expect(config.ldapBindDN == "CN=grocy")

        let encoded = try #require(String(data: try JSONEncoder().encode(config), encoding: .utf8))
        #expect(!encoded.contains("LDAP_BIND_PW"))
        #expect(!encoded.contains("secret"))
    }

    @Test("The system config survives encoding and decoding")
    func systemConfigRoundTrip() throws {
        let config = try JSONDecoder().decode(SystemConfig.self, from: fixture("system__config"))
        let decoded = try JSONDecoder().decode(SystemConfig.self, from: JSONEncoder().encode(config))

        #expect(decoded.mode == config.mode)
        #expect(decoded.defaultPermissions == config.defaultPermissions)
        #expect(decoded.labelPrinterFontFamily == config.labelPrinterFontFamily)
        #expect(decoded.tprinterPort == config.tprinterPort)
        #expect(decoded.featureFlagChoresAssignments == config.featureFlagChoresAssignments)
        #expect(decoded.featureFlagAutoTorchOnWithCamera == config.featureFlagAutoTorchOnWithCamera)
    }

    // MARK: - GrocyUserSettings

    @Test("The user settings fixture decodes every setting")
    func userSettingsFixture() throws {
        let settings = try JSONDecoder().decode(GrocyUserSettings.self, from: fixture("user__settings"))

        #expect(settings.nightMode == "follow-system")
        #expect(settings.autoNightModeEnabled == false)
        #expect(settings.autoNightModeTimeRangeFrom == "20:00")
        #expect(settings.autoNightModeTimeRangeTo == "07:00")
        #expect(settings.autoNightModeTimeRangeGoesOverMidnight == true)
        // Sent as the string "1".
        #expect(settings.nightModeEnabledInternal == true)
        #expect(settings.autoReloadOnDBChange == false)
        #expect(settings.showClockInHeader == false)
        #expect(settings.keepScreenOn == false)
        #expect(settings.keepScreenOnWhenFullscreenCard == false)
        // Sent as the string "3".
        #expect(settings.productPresetsLocationID == 3)
        #expect(settings.productPresetsDefaultStockLabelType == 0)
        #expect(settings.scanModeConsumeEnabled == false)
        #expect(settings.scanModePurchaseEnabled == false)
        #expect(settings.shoppingListPrintShowHeader == true)
        #expect(settings.shoppingListPrintGroupByProductGroup == true)
        #expect(settings.shoppingListPrintLayoutType == "table")
        #expect(settings.recipesShowListSideBySide == true)
        #expect(settings.calendarColorProducts == "#007bff")
        #expect(settings.calendarColorTasks == "#28a745")
        #expect(settings.calendarColorChores == "#ffc107")
        #expect(settings.calendarColorBatteries == "#17a2b8")
        #expect(settings.calendarColorMealPlan == "#6c757d")
    }

    @Test("Settings an older server doesn't send stay nil")
    func userSettingsMissingKeys() throws {
        let settings = try decode(GrocyUserSettings.self, json: #"{"stock_due_soon_days": "7"}"#)

        #expect(settings.stockDueSoonDays == 7)
        #expect(settings.nightMode == nil)
        #expect(settings.scanModePurchaseEnabled == nil)
        #expect(settings.calendarColorMealPlan == nil)
    }

    @Test("The user settings survive encoding and decoding")
    func userSettingsRoundTrip() throws {
        let settings = try JSONDecoder().decode(GrocyUserSettings.self, from: fixture("user__settings"))
        let decoded = try JSONDecoder().decode(GrocyUserSettings.self, from: JSONEncoder().encode(settings))

        #expect(decoded.nightMode == settings.nightMode)
        #expect(decoded.nightModeEnabledInternal == settings.nightModeEnabledInternal)
        #expect(decoded.shoppingListPrintLayoutType == settings.shoppingListPrintLayoutType)
        #expect(decoded.calendarColorChores == settings.calendarColorChores)
        #expect(decoded.productPresetsDefaultStockLabelType == settings.productPresetsDefaultStockLabelType)
    }

    // MARK: - SwiftData

    @Test("Both are stored in and read back from SwiftData")
    func storedInSwiftData() throws {
        let container = try ModelContainer(
            for: SystemConfig.self,
            GrocyUserSettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        let context = container.mainContext
        let synchronizer = SwiftDataSynchronizer(modelContext: context)

        try synchronizer.syncSingletonModel(SystemConfig.self, with: JSONDecoder().decode(SystemConfig.self, from: fixture("system__config")))
        try synchronizer.syncSingletonModel(GrocyUserSettings.self, with: JSONDecoder().decode(GrocyUserSettings.self, from: fixture("user__settings")))

        let storedConfig = try #require(try ModelContext(container).fetch(FetchDescriptor<SystemConfig>()).first)
        #expect(storedConfig.defaultPermissions == ["ADMIN"])
        #expect(storedConfig.labelPrinterFontFamily == "Source Sans Pro (Regular)")
        #expect(storedConfig.featureFlagChoresAssignments)

        let storedSettings = try #require(try ModelContext(container).fetch(FetchDescriptor<GrocyUserSettings>()).first)
        #expect(storedSettings.calendarColorMealPlan == "#6c757d")
        #expect(storedSettings.nightMode == "follow-system")
    }

    // MARK: - Price history

    @Test("Price history entries decode with and without a store")
    func priceHistoryDecodes() throws {
        let json = """
            [{"date": "2026-11-01", "price": 1.49, "shopping_location": {"id": "2", "name": "Market", "description": null, "row_created_timestamp": "2026-01-01 00:00:00"}},
             {"date": "2026-10-03", "price": "0.99", "shopping_location": null}]
            """
        let history = try decode(ProductPriceHistories.self, json: json)

        #expect(history.count == 2)
        #expect(history[0].price == 1.49)
        #expect(history[0].storeID == 2)
        #expect(history[0].storeName == "Market")
        #expect(history[1].price == 0.99)
        #expect(history[1].storeID == nil)
        #expect(history[1].storeName == nil)

        let components = Calendar.current.dateComponents([.year, .month, .day], from: history[0].date)
        #expect(components.year == 2026 && components.month == 11 && components.day == 1)
    }

    @Test("A price history entry without a date fails with a decoding error")
    func priceHistoryInvalidDate() {
        #expect(throws: APIError.self) {
            try decode(ProductPriceHistories.self, json: #"[{"date": "not a date", "price": 1, "shopping_location": null}]"#)
        }
    }
}
