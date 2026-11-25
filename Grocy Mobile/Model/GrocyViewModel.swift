//
//  GrocyModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import AppIntents
internal import Combine
import Foundation
import OSLog
import SwiftData
import SwiftUI
import WebKit
import WidgetKit

@MainActor
@Observable
class GrocyViewModel {
    var grocyApi: GrocyAPI

    let modelContext: ModelContext
    let profileModelContext: ModelContext?
    private let swiftDataSync: SwiftDataSynchronizer

    var aiCategoryMatcher: AICategoryMatcher?

    /// Quick Scan's last choices (store, locations, due dates, prices). Kept until the app quits, and forgotten with the cached data,
    /// because the IDs belong to this server.
    let quickScanSession = QuickScanSession()

    @ObservationIgnored @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @ObservationIgnored @AppStorage("isDemoModus") var isDemoModus: Bool = false
    @ObservationIgnored @AppStorage("demoServerURL") var demoServerURL: String = GrocyAPP.DemoServers.noLanguage.rawValue
    @ObservationIgnored @AppStorage("localizationKey") var localizationKey: String = "en"
    @ObservationIgnored @AppStorage("timeoutInterval") var timeoutInterval: Double = 60.0
    @ObservationIgnored @AppStorage("autoReload") private var autoReload: Bool = false
    @ObservationIgnored @AppStorage("autoReloadInterval") private var autoReloadInterval: Int = 0
    @ObservationIgnored @AppStorage("selectedServerProfileID") private var selectedServerProfileID: UUID?
    @ObservationIgnored @AppStorage("useAppleIntelligence") var useAppleIntelligence: Bool = true

    @ObservationIgnored var refreshTimer: Timer?
    /// The automatic login started at launch. `requestData` waits for it, so the views' first `.task` doesn't run before the API is configured.
    @ObservationIgnored private var loginTask: Task<Void, Never>?

    var systemInfo: SystemInfo?
    var systemDBChangedTime: SystemDBChangedTime?
    var systemConfig: SystemConfig?
    var userSettings: GrocyUserSettings?

    var users: GrocyUsers = []
    var currentUser: GrocyUser? = nil
    var stock: Stock = []
    var stockEntries: StockEntries = []
    var stockCurrentLocations: StockLocations = []
    var volatileStock: VolatileStock? = nil
    var stockJournal: StockJournal = []
    var shoppingListDescriptions: ShoppingListDescriptions = []
    var shoppingList: [ShoppingListItem] = []
    var recipes: Recipes = []
    var recipeFulfillments: RecipeFulfilments = []
    var recipesNestings: RecipesNesting = []
    var recipesPos: [RecipePos] = []
    var recipesPosResolved: [RecipePosResolvedElement] = []
    var chores: Chores = []
    var choreLog: ChoreLog = []
    var batteries: Batteries = []
    var batteryChargeCycles: BatteryChargeCycles = []
    var grocyTasks: GrocyTasks = []
    var mealPlan: MealPlanEntries = []

    var mdProducts: MDProducts = []
    var mdProductBarcodes: MDProductBarcodes = []
    var mdLocations: MDLocations = []
    var mdStores: MDStores = []
    var mdQuantityUnits: MDQuantityUnits = []
    var mdQuantityUnitConversions: MDQuantityUnitConversions = []
    var mdProductGroups: MDProductGroups = []
    var mdBatteries: MDBatteries = []
    var mdEquipment: MDEquipments = []
    var mdTaskCategories: MDTaskCategories = []
    var mdUserFields: MDUserFields = []
    var mdUserEntities: MDUserEntities = []
    var mdUserObjects: MDUserObjects = []
    var mdChores: MDChores = []
    var mdMealPlanSections: MDMealPlanSections = []

    var stockProductDetails: [Int: StockProductDetails] = [:]
    var stockProductLocations: [Int: StockLocations] = [:]
    var stockProductEntries: [Int: StockEntries] = [:]
    var stockProductPriceHistories: [Int: ProductPriceHistories] = [:]
    var choreDetails: [Int: ChoreDetails] = [:]

    var lastStockActions: StockJournal = []

    var failedToLoadObjects = Set<ObjectEntities>()
    var failedToLoadAdditionalObjects = Set<AdditionalEntities>()
    var failedToLoadErrors: [Error] = []

    var timeStampsObjects: [ObjectEntities: SystemDBChangedTime] = [:]
    var timeStampsAdditionalObjects: [AdditionalEntities: SystemDBChangedTime] = [:]

    var logEntries: [OSLogEntryLog] = []

    var loadingObjectEntities: Set<ObjectEntities> = Set()
    var loadingAdditionalEntities: Set<AdditionalEntities> = Set()

    var productPictures: [String: Data] = [:]
    var userPictures: [String: Data] = [:]
    var recipePictures: [String: Data] = [:]

    var cancellables = Set<AnyCancellable>()

    var jsonEncoder: JSONEncoder

    var selectedServerProfile: ServerProfile? {
        guard let modelContext = profileModelContext else { return nil }
        guard let selectedServerProfileID = selectedServerProfileID else { return nil }

        let descriptor = FetchDescriptor<ServerProfile>(predicate: #Predicate<ServerProfile> { $0.id == selectedServerProfileID })
        return (try? modelContext.fetch(descriptor))?.first
    }

    init(modelContext: ModelContext, profileModelContext: ModelContext) {
        self.grocyApi = GrocyApi()
        self.modelContext = modelContext
        self.modelContext.autosaveEnabled = false
        self.profileModelContext = profileModelContext
        self.swiftDataSync = SwiftDataSynchronizer(modelContext: modelContext)
        self.aiCategoryMatcher = nil
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .custom({ (date, encoder) in
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            if date.hasTimeComponent {
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            } else {
                dateFormatter.dateFormat = "yyyy-MM-dd"
            }
            let dateString = dateFormatter.string(from: date)
            var container = encoder.singleValueContainer()
            try container.encode(dateString)
        })
        self.jsonEncoder.outputFormatting = .prettyPrinted
        if isLoggedIn {
            loginTask = Task {
                do {
                    if isDemoModus {
                        try await checkServer(
                            baseURL: demoServerURL,
                            apiKey: "",
                            useHassIngress: false,
                            hassToken: "",
                            isDemoMode: isDemoModus,
                            customHeaders: []
                        )
                    } else if let profile = selectedServerProfile {
                        try await checkServer(
                            baseURL: profile.grocyServerURL,
                            apiKey: profile.grocyAPIKey,
                            useHassIngress: profile.useHassIngress,
                            hassToken: profile.hassToken,
                            isDemoMode: isDemoModus,
                            customHeaders: profile.customHeaders ?? [],
                            trustedCertificateFingerprint: profile.trustedCertificateFingerprint
                        )
                    }
                    self.setUpdateTimer()
                } catch {
                    GrocyLogger.error("\(error)")
                }
            }
        } else {
            GrocyLogger.info("Not logged in")
        }
        if useAppleIntelligence && AppleIntelligenceStatus.isAppleIntelligenceAvailable {
            self.aiCategoryMatcher = AICategoryMatcher()
        }
    }

    /// Waits until the login at launch is done, so the server can be called.
    func waitForLogin() async {
        await loginTask?.value
    }

    func setDemoModus() {
        grocyApi.setLoginData(baseURL: demoServerURL, apiKey: "", customHeaders: [:])
        grocyApi.setTrustedCertificate(fingerprint: nil)
        grocyApi.setTimeoutInterval(timeoutInterval: timeoutInterval)
        isDemoModus = true
        isLoggedIn = true
        self.setUpdateTimer()
        GrocyLogger.info("Switched to demo modus")
    }

    func setLoginModus() async {
        guard let selectedServerProfile else {
            GrocyLogger.info("Not logged in")
            return
        }
        if selectedServerProfile.useHassIngress, let hassAPIPath = getHomeAssistantPathFromIngress(ingressPath: selectedServerProfile.grocyServerURL) {
            await grocyApi.setHassData(hassURL: hassAPIPath, hassToken: selectedServerProfile.hassToken)
        }
        grocyApi.setLoginData(
            baseURL: selectedServerProfile.grocyServerURL,
            apiKey: selectedServerProfile.grocyAPIKey,
            customHeaders: Dictionary(
                uniqueKeysWithValues: (selectedServerProfile.customHeaders ?? []).map { (header: LoginCustomHeader) in
                    ((header.headerName) as String, (header.headerValue) as String)
                }
            )
        )
        grocyApi.setTrustedCertificate(fingerprint: selectedServerProfile.trustedCertificateFingerprint)
        grocyApi.setTimeoutInterval(timeoutInterval: timeoutInterval)
        isDemoModus = false
        isLoggedIn = true
        self.setUpdateTimer()
        GrocyLogger.info("Switched to login modus")
    }

    func logout() {
        self.loginTask?.cancel()
        self.loginTask = nil
        self.stopUpdateTimer()
        grocyApi.clearHassData()
        grocyApi.clearLoginData()
        self.deleteAllCachedData()
        // The links to Reminders belong to the shopping lists of this server.
        ReminderStore.shared.unlinkAll()
        isLoggedIn = false
        // The watch shows "not signed in" and drops the shopping lists and tasks.
        self.updateWatch()
    }

    func cancelAllURLSessionTasks() {
        grocyApi.cancelAllTasks()
    }

    func stopUpdateTimer() {
        self.refreshTimer?.invalidate()
        self.refreshTimer = nil
    }

    /// Starts the auto reload timer with the current settings, or stops it when auto reload is off (#112).
    func setUpdateTimer() {
        self.stopUpdateTimer()
        if self.autoReload && self.autoReloadInterval != 0 {
            self.refreshTimer =
                Timer
                .scheduledTimer(
                    withTimeInterval: Double(autoReloadInterval),
                    repeats: true,
                    block: { _ in
                        Task {
                            await self.updateData()
                        }
                    }
                )
        }
    }

    func checkServer(
        baseURL: String,
        apiKey: String?,
        useHassIngress: Bool = false,
        hassToken: String = "",
        isDemoMode: Bool,
        customHeaders: [LoginCustomHeader] = [],
        trustedCertificateFingerprint: String? = nil
    ) async throws {
        // Configure the new API completely before swapping it in, so no request runs against a half-configured instance.
        let api = GrocyApi()
        if useHassIngress && !isDemoMode, let hassAPIPath = getHomeAssistantPathFromIngress(ingressPath: baseURL) {
            api.setHassData(hassURL: hassAPIPath, hassToken: hassToken)
        }
        api.setLoginData(
            baseURL: baseURL,
            apiKey: apiKey ?? "",
            customHeaders: Dictionary(uniqueKeysWithValues: customHeaders.map({ ($0.headerName, $0.headerValue) }))
        )
        api.setTrustedCertificate(fingerprint: isDemoMode ? nil : trustedCertificateFingerprint)
        api.setTimeoutInterval(timeoutInterval: timeoutInterval)
        self.grocyApi = api
        // The server may have changed, so reload everything and forget errors from the previous server.
        self.timeStampsObjects.removeAll()
        self.timeStampsAdditionalObjects.removeAll()
        self.failedToLoadObjects.removeAll()
        self.failedToLoadAdditionalObjects.removeAll()
        self.failedToLoadErrors.removeAll()
        let systemInfo = try await api.getSystemInfo()
        if !systemInfo.grocyVersion.version.isEmpty {
            GrocyLogger.info(
                "Server check successful. Logging into Grocy Server \(systemInfo.grocyVersion.version) with app version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")."
            )
            self.systemInfo = systemInfo
            return
        } else {
            GrocyLogger.error("Selected server doesn't respond.")
            throw APIError.invalidResponse
        }
    }

    func findNextID(_ object: ObjectEntities) throws -> Int {
        var ints: [Int] = []
        switch object {
        case .chores:
            ints = self.mdChores.map { $0.id }
        case .batteries:
            ints = self.mdBatteries.map { $0.id }
        case .equipment:
            ints = self.mdEquipment.map { $0.id }
        case .products:
            ints = self.mdProducts.map { $0.id }
        case .locations:
            ints = self.mdLocations.map { $0.id }
        case .shopping_locations:
            ints = self.mdStores.map { $0.id }
        case .quantity_units:
            ints = self.mdQuantityUnits.map { $0.id }
        case .quantity_unit_conversions:
            ints = self.mdQuantityUnitConversions.map { $0.id }
        case .product_groups:
            ints = self.mdProductGroups.map { $0.id }
        case .shopping_lists:
            ints = self.shoppingListDescriptions.map { $0.id }
        case .shopping_list:
            ints = self.shoppingList.map { $0.id }
        case .product_barcodes:
            ints = self.mdProductBarcodes.map { $0.id }
        case .recipes:
            ints = self.recipes.map { $0.id }
        case .recipes_pos:
            ints = self.recipesPos.map { $0.id }
        case .recipes_nestings:
            ints = self.recipesNestings.map { $0.id }
        case .tasks:
            ints = self.grocyTasks.map { $0.id }
        case .task_categories:
            ints = self.mdTaskCategories.map { $0.id }
        case .userfields:
            ints = self.mdUserFields.map { $0.id }
        case .userentities:
            ints = self.mdUserEntities.map { $0.id }
        case .meal_plan:
            ints = self.mealPlan.map { $0.id }
        case .meal_plan_sections:
            ints = self.mdMealPlanSections.map { $0.id }
        default:
            throw APIError.invalidResponse
        }
        var startvar = 1
        while ints.contains(startvar) { startvar += 1 }
        return startvar
    }

    func requestData(objects: [ObjectEntities]? = nil, additionalObjects: [AdditionalEntities]? = nil) async {
        // Wait for the automatic login started at launch, then guard against calling the API before it's configured.
        if !grocyApi.isLoggedIn, let loginTask {
            await loginTask.value
        }
        guard grocyApi.isLoggedIn else {
            GrocyLogger.debug("Skipping data request, because the API isn't configured yet.")
            return
        }

        do {
            let timestamp = try await grocyApi.getSystemDBChangedTime()
            await self.requestDataWithTimeStamp(objects: objects, additionalObjects: additionalObjects, timeStamp: timestamp)
        } catch {
            GrocyLogger.error("Getting timestamp failed. Message: \(error)")
        }
    }

    func requestDataWithTimeStamp(objects: [ObjectEntities]? = nil, additionalObjects: [AdditionalEntities]? = nil, timeStamp: SystemDBChangedTime) async {
        if let objects = objects {
            for object in objects {
                do {
                    if timeStamp != self.timeStampsObjects[object] {
                        self.loadingObjectEntities.insert(object)

                        switch object {
                        case .batteries:
                            self.mdBatteries = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.mdBatteries)
                        case .battery_charge_cycles:
                            self.batteryChargeCycles = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.batteryChargeCycles)
                        case .equipment:
                            self.mdEquipment = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.mdEquipment)
                        case .chores:
                            self.mdChores = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.mdChores)
                        case .chores_log:
                            self.choreLog = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.choreLog)
                        case .meal_plan:
                            self.mealPlan = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.mealPlan)
                        case .meal_plan_sections:
                            self.mdMealPlanSections = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.mdMealPlanSections)
                        case .locations:
                            self.mdLocations = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.mdLocations)
                        case .product_barcodes:
                            self.mdProductBarcodes = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.mdProductBarcodes)
                        case .product_groups:
                            self.mdProductGroups = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.mdProductGroups)
                        case .products:
                            self.mdProducts = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.mdProducts)
                            // Stock may have been synced before the products (for example on first launch), so link it now.
                            try swiftDataSync.linkStockElementsToProducts()
                            self.updateWidgetShoppingList()
                            // Siri's phrases name the products, so tell the system about the new names.
                            GrocyAppShortcuts.updateAppShortcutParameters()
                        case .quantity_unit_conversions:
                            self.mdQuantityUnitConversions = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.mdQuantityUnitConversions)
                        case .recipes:
                            self.recipes = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.recipes)
                        case .recipes_nestings:
                            self.recipesNestings = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.recipesNestings)
                        case .recipes_pos:
                            self.recipesPos = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.recipesPos)
                        case .recipes_pos_resolved:
                            self.recipesPosResolved = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.recipesPosResolved)
                        case .quantity_units:
                            self.mdQuantityUnits = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.mdQuantityUnits)
                            self.updateWidgetShoppingList()
                        case .shopping_list:
                            self.shoppingList = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.shoppingList)
                            self.updateWidgetShoppingList()
                            ReminderStore.shared.syncAutomaticallyIfEnabled(grocyVM: self, only: .shoppingList)
                        case .shopping_lists:
                            self.shoppingListDescriptions = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.shoppingListDescriptions)
                            self.updateWidgetShoppingList()
                        case .shopping_locations:
                            self.mdStores = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.mdStores)
                        // Userfields and user entities are only kept in memory.
                        case .userfields:
                            self.mdUserFields = try await grocyApi.getObject(object: object)
                        case .userentities:
                            self.mdUserEntities = try await grocyApi.getObject(object: object)
                        case .userobjects:
                            self.mdUserObjects = try await grocyApi.getObject(object: object)
                        case .stock:
                            self.stockEntries = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.stockEntries)
                        case .stock_log:
                            self.stockJournal = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.stockJournal)
                        case .stock_current_locations:
                            self.stockCurrentLocations = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.stockCurrentLocations)
                        case .tasks:
                            self.grocyTasks = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.grocyTasks)
                            self.updateWidgetTasks()
                            ReminderStore.shared.syncAutomaticallyIfEnabled(grocyVM: self, only: .tasks)
                        case .task_categories:
                            self.mdTaskCategories = try await grocyApi.getObject(object: object)
                            try swiftDataSync.syncPersistentCollection(self.mdTaskCategories)
                        }

                        self.timeStampsObjects[object] = timeStamp
                        self.loadingObjectEntities.remove(object)
                        self.failedToLoadObjects.remove(object)
                    }
                } catch {
                    GrocyLogger.error("Data request failed for \(object). Message: \("\(error)")")
                    self.failedToLoadObjects.insert(object)
                    self.failedToLoadErrors.append(error)
                    self.loadingObjectEntities.remove(object)
                }
            }
        }

        if let additionalObjects = additionalObjects {
            for additionalObject in additionalObjects {
                do {
                    if timeStamp != self.timeStampsAdditionalObjects[additionalObject] {
                        self.loadingAdditionalEntities.insert(additionalObject)

                        try await self.fetchAndSyncAdditionalObject(additionalObject)

                        self.timeStampsAdditionalObjects[additionalObject] = timeStamp
                        self.loadingAdditionalEntities.remove(additionalObject)
                        self.failedToLoadAdditionalObjects.remove(additionalObject)
                    }
                } catch {
                    GrocyLogger.error("Data request failed for \(additionalObject). Message: \("\(error)")")
                    self.failedToLoadAdditionalObjects.insert(additionalObject)
                    self.failedToLoadErrors.append(error)
                    self.loadingAdditionalEntities.remove(additionalObject)
                }
            }
        }
    }

    // MARK: - SwiftData Synchronization Helpers

    private func fetchAndSyncAdditionalObject(_ additionalObject: AdditionalEntities) async throws {
        switch additionalObject {
        case .current_user:
            self.currentUser = try await grocyApi.getUser().first
            self.updateWidgetChores()
            self.updateWidgetTasks()

        case .batteries:
            self.batteries = try await grocyApi.getBatteries()
            try swiftDataSync.syncPersistentCollection(self.batteries)
        case .chores:
            self.chores = try await grocyApi.getChores()
            try swiftDataSync.syncPersistentCollection(self.chores)
            self.updateWidgetChores()
            ReminderStore.shared.syncAutomaticallyIfEnabled(grocyVM: self, only: .chores)

        case .stock:
            self.stock = try await grocyApi.getStock()
            try swiftDataSync.syncStockElements(self.stock)

        case .system_config:
            self.systemConfig = try await grocyApi.getSystemConfig()
            try swiftDataSync.syncSingletonModel(SystemConfig.self, with: self.systemConfig)

        case .system_db_changed_time:
            self.systemDBChangedTime = try await grocyApi.getSystemDBChangedTime()

        case .system_info:
            self.systemInfo = try await grocyApi.getSystemInfo()

        case .user_settings:
            self.userSettings = try await grocyApi.getUserSettings()
            try swiftDataSync.syncSingletonModel(GrocyUserSettings.self, with: self.userSettings)
            self.updateWidgetChores()
            self.updateWidgetTasks()
            // "Round up" changes how the shopping list widget shows its amounts.
            self.updateWidgetShoppingList()

        case .recipeFulfillments:
            self.recipeFulfillments = try await grocyApi.getRecipeFulfillments()
            try swiftDataSync.syncPersistentCollection(self.recipeFulfillments)

        case .users:
            self.users = try await grocyApi.getUsers()
            try swiftDataSync.syncArrayModel(GrocyUser.self, with: self.users)

        case .volatileStock:
            let userSettingsFetch = FetchDescriptor<GrocyUserSettings>()
            let dueSoonDays = try modelContext.fetch(userSettingsFetch).first?.stockDueSoonDays ?? self.userSettings?.stockDueSoonDays ?? 5
            self.volatileStock = try await grocyApi.getVolatileStock(dueSoonDays: dueSoonDays)
            try swiftDataSync.syncSingletonModel(VolatileStock.self, with: self.volatileStock)
            self.updateWidgetSummary()
        }
    }

    func retryFailedRequests() async {
        self.failedToLoadErrors = []
        await self.requestData(objects: Array(failedToLoadObjects), additionalObjects: Array(failedToLoadAdditionalObjects))
    }

    func updateData() async {
        GrocyLogger.debug("Update triggered")
        await self.requestData(objects: Array(self.timeStampsObjects.keys), additionalObjects: Array(self.timeStampsAdditionalObjects.keys))
    }

    func deleteAllCachedData() {
        self.quickScanSession.reset()
        self.systemInfo = nil
        self.systemDBChangedTime = nil
        self.systemConfig = nil
        self.userSettings = nil

        self.users = []
        self.currentUser = nil
        self.stock = []
        self.stockEntries = []
        self.volatileStock = nil
        self.stockJournal = []
        self.shoppingListDescriptions = []
        self.shoppingList = []
        self.recipes = []
        self.recipeFulfillments = []
        self.recipesNestings = []
        self.recipesPos = []
        self.recipesPosResolved = []
        self.mdChores = []
        self.chores = []
        self.choreLog = []
        self.batteries = []
        self.batteryChargeCycles = []
        self.grocyTasks = []
        self.mealPlan = []

        self.mdProducts = []
        self.mdProductBarcodes = []
        self.mdLocations = []
        self.mdStores = []
        self.mdQuantityUnits = []
        self.mdQuantityUnitConversions = []
        self.mdProductGroups = []
        self.mdBatteries = []
        self.mdEquipment = []
        self.mdTaskCategories = []
        self.mdUserFields = []
        self.mdUserEntities = []
        self.mdUserObjects = []
        self.mdMealPlanSections = []

        self.stockProductDetails = [:]
        self.stockProductLocations = [:]
        self.stockProductEntries = [:]
        self.stockProductPriceHistories = [:]
        self.choreDetails = [:]

        self.lastStockActions = []

        self.timeStampsObjects.removeAll()
        self.timeStampsAdditionalObjects.removeAll()

        self.failedToLoadObjects.removeAll()
        self.failedToLoadAdditionalObjects.removeAll()
        self.failedToLoadErrors.removeAll()

        self.productPictures.removeAll()
        self.userPictures.removeAll()
        self.recipePictures.removeAll()

        do {
            for modelType in Grocy_MobileApp.mainModelTypes {
                try deleteAllObjects(of: modelType)
            }
            // Autosave is off, so the deletions only reach the store with an explicit save.
            try self.modelContext.save()
        } catch {
            self.modelContext.rollback()
            GrocyLogger.error("Deleting the cached data failed. \(error)")
        }

        WidgetStockSummary.clear()
        WidgetSharedStore.remove(forKey: WidgetSharedStore.shoppingListKey)
        WidgetSharedStore.remove(forKey: WidgetSharedStore.choresKey)
        WidgetSharedStore.remove(forKey: WidgetSharedStore.tasksKey)
        WidgetCenter.shared.reloadAllTimelines()

        GrocyLogger.info("Deleted all cached data from the viewmodel.")
    }

    private func deleteAllObjects<T: PersistentModel>(of modelType: T.Type) throws {
        try self.modelContext.delete(model: modelType)
    }

    /// Writes the counts shown by the widget to the App Group and reloads the widget.
    private func updateWidgetSummary() {
        guard let volatileStock else { return }
        WidgetStockSummary(
            dueSoon: volatileStock.dueProducts.count,
            overdue: volatileStock.overdueProducts.count,
            expired: volatileStock.expiredProducts.count,
            belowMinStock: volatileStock.missingProducts.count,
            updated: Date()
        ).save()
        WidgetSharedStore.saveLocalization(localizationKey)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetStockSummary.widgetKind)
    }

    /// Writes the undone shopping list items to the App Group and reloads the shopping list widget.
    private func updateWidgetShoppingList() {
        do {
            let descriptions = try modelContext.fetch(FetchDescriptor<ShoppingListDescription>(sortBy: [SortDescriptor(\.id)]))
            let items = try modelContext.fetch(FetchDescriptor<ShoppingListItem>(predicate: #Predicate { $0.done == false }))
            let products = Dictionary(try modelContext.fetch(FetchDescriptor<MDProduct>()).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            let quantityUnits = Dictionary(
                try modelContext.fetch(FetchDescriptor<MDQuantityUnit>()).map { ($0.id, $0) },
                uniquingKeysWith: { first, _ in first }
            )
            let roundUp = try modelContext.fetch(FetchDescriptor<GrocyUserSettings>()).first?.shoppingListRoundUp ?? false
            let conversions = try modelContext.fetch(FetchDescriptor<MDQuantityUnitConversion>())

            let lists = descriptions.map { (description: ShoppingListDescription) -> WidgetShoppingListSummary.List in
                let listItems =
                    items
                    .filter { $0.shoppingListID == description.id }
                    .map { (item: ShoppingListItem) -> WidgetShoppingListSummary.Item in
                        let product = item.productID.flatMap { products[$0] }
                        let name = product?.name ?? item.note
                        let displayAmount = item.displayAmount(roundUp: roundUp, product: product, conversions: conversions)
                        var amount = displayAmount.formattedAmount
                        if let quantityUnit = item.quID.flatMap({ quantityUnits[$0] }) {
                            amount += " \(quantityUnit.getName(amount: displayAmount))"
                        }
                        return WidgetShoppingListSummary.Item(id: item.id, name: name, amount: amount)
                    }
                    .sorted { (first: WidgetShoppingListSummary.Item, second: WidgetShoppingListSummary.Item) in
                        first.name.localizedStandardCompare(second.name) == .orderedAscending
                    }
                return WidgetShoppingListSummary.List(id: description.id, name: description.name, items: listItems)
            }

            WidgetSharedStore.save(WidgetShoppingListSummary(lists: lists, updated: Date()), forKey: WidgetSharedStore.shoppingListKey)
            WidgetSharedStore.saveLocalization(localizationKey)
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetSharedStore.shoppingListKind)
            self.updateWatch()
        } catch {
            GrocyLogger.error("Updating the shopping list widget failed. \(error)")
        }
    }

    /// Sends the shopping lists, tasks and chores the widgets show to the Watch app.
    private func updateWatch() {
        #if os(iOS)
            WatchSync.shared.sendSnapshot()
        #endif
    }

    /// Writes the chores with their next due date to the App Group and reloads the chores widget.
    private func updateWidgetChores() {
        do {
            let chores = try modelContext.fetch(FetchDescriptor<Chore>())
            let dueSoonDays = try modelContext.fetch(FetchDescriptor<GrocyUserSettings>()).first?.choresDueSoonDays ?? 5
            let currentUserID = self.currentUser?.id
            let items = chores.map { chore in
                WidgetDueSummary.Item(
                    id: chore.choreID,
                    name: chore.choreName,
                    dueDate: chore.nextEstimatedExecutionTime,
                    assignedToMe: currentUserID != nil && chore.nextExecutionAssignedToUserID == currentUserID
                )
            }
            WidgetSharedStore.save(WidgetDueSummary(items: items, dueSoonDays: dueSoonDays, updated: Date()), forKey: WidgetSharedStore.choresKey)
            WidgetSharedStore.saveLocalization(localizationKey)
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetSharedStore.choresKind)
            self.updateWatch()
        } catch {
            GrocyLogger.error("Updating the chores widget failed. \(error)")
        }
    }

    /// Writes the tasks that aren't done to the App Group and reloads the tasks widget.
    private func updateWidgetTasks() {
        do {
            let tasks = try modelContext.fetch(FetchDescriptor<GrocyTask>(predicate: #Predicate { $0.done == false }))
            let dueSoonDays = try modelContext.fetch(FetchDescriptor<GrocyUserSettings>()).first?.tasksDueSoonDays ?? 5
            let currentUserID = self.currentUser?.id
            let items = tasks.map { task in
                WidgetDueSummary.Item(
                    id: task.id,
                    name: task.name,
                    dueDate: task.dueDate,
                    assignedToMe: currentUserID != nil && task.assignedToUserID == currentUserID
                )
            }
            WidgetSharedStore.save(WidgetDueSummary(items: items, dueSoonDays: dueSoonDays, updated: Date()), forKey: WidgetSharedStore.tasksKey)
            WidgetSharedStore.saveLocalization(localizationKey)
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetSharedStore.tasksKind)
            self.updateWatch()
        } catch {
            GrocyLogger.error("Updating the tasks widget failed. \(error)")
        }
    }

    func getLogEntries() async {
        await Task.detached {
            do {
                let logStore = try OSLogStore(scope: .currentProcessIdentifier)
                let oneHourAgo = logStore.position(date: Date().addingTimeInterval(-3600))
                let allEntries = try logStore.getEntries(at: oneHourAgo)
                let filtered =
                    allEntries
                    .compactMap { $0 as? OSLogEntryLog }
                    .filter { $0.subsystem == "georgappdev.Grocy" }

                await MainActor.run {
                    self.logEntries = filtered
                }
            } catch {
                await MainActor.run {
                    GrocyLogger.error("Error getting log entries")
                }
            }
        }.value
    }

    func getAttributedStringFromHTML(htmlString: String) async -> AttributedString {
        do {
            let attributedString = try await NSAttributedString.fromHTML(htmlString)
            return AttributedString(attributedString.0)
        } catch {
            return AttributedString(htmlString)
        }
    }

    //MARK: - SYSTEM
    func getCurrencySymbol() -> String {
        let locale = NSLocale(localeIdentifier: localizationKey)
        return locale.displayName(forKey: NSLocale.Key.currencySymbol, value: self.systemConfig?.currency ?? "CURRENCY") ?? "CURRENCY"
    }

    func getFormattedCurrency(amount: Double) -> String {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = self.systemConfig?.currency
        currencyFormatter.maximumFractionDigits = 2
        currencyFormatter.locale = Locale(identifier: localizationKey)
        let formattedString = currencyFormatter.string(from: NSNumber(value: amount))
        return formattedString ?? amount.formattedAmount
    }

    // MARK: - USER MANAGEMENT
    func postUser(user: GrocyUserPOST) async throws {
        let jsonUser = try! jsonEncoder.encode(user)
        try await grocyApi.postUser(user: jsonUser)
    }

    func putUser(id: Int, user: GrocyUserPOST) async throws {
        let jsonUser = try! jsonEncoder.encode(user)
        try await grocyApi.putUserWithID(id: id, user: jsonUser)
    }

    func deleteUser(id: Int) async throws {
        try await grocyApi.deleteUserWithID(id: id)
    }

    /// All of Grocy's permissions, as a tree through `parent`.
    func getPermissionHierarchy() async throws -> GrocyPermissions {
        try await grocyApi.getPermissionHierarchy()
    }

    /// The IDs of the permissions assigned to a user (not the ones it inherits from them).
    func getUserPermissionIDs(userID: Int) async throws -> Set<Int> {
        Set(try await grocyApi.getUserPermissions(id: userID).map(\.permissionID))
    }

    /// Replaces all permissions of a user. Needs the ADMIN permission; in demo mode Grocy keeps ADMIN for everyone.
    func putUserPermissions(userID: Int, permissionIDs: Set<Int>) async throws {
        let content = try jsonEncoder.encode(GrocyUserPermissionsPUT(permissions: permissionIDs.sorted()))
        try await grocyApi.putUserPermissions(id: userID, content: content)
    }

    func getNewUserID() -> Int {
        let ints = self.users.map { $0.id }
        var startvar = 0
        while ints.contains(startvar) { startvar += 1 }
        return startvar
    }

    // MARK: - Current user
    func getUserSettingsEntry<T: Codable>(settingKey: String) async throws -> T {
        return try await grocyApi.getUserSettingKey(settingKey: settingKey)
    }

    func putUserSettingsEntry<T: Codable>(settingKey: String, content: T) async throws {
        let jsonContent = try! jsonEncoder.encode(content)
        try await grocyApi.putUserSettingKey(settingKey: settingKey, content: jsonContent)
    }

    // MARK: - Stock management
    func requestStockInfo(stockModeGet: StockProductGet, productID: Int, queries: [String]? = nil) async {
        do {
            switch stockModeGet {
            case .details:
                let stockDetails: StockProductDetails = try await grocyApi.getStockProductInfo(stockModeGet: .details, productID: productID, queries: queries)
                self.stockProductDetails[productID] = stockDetails
                let fetchDescriptor = FetchDescriptor<StockProductDetails>(
                    predicate: #Predicate { details in
                        details.productID == productID
                    }
                )
                if let existingObject = try modelContext.fetch(fetchDescriptor).first {
                    self.modelContext.delete(existingObject)
                }
                stockDetails.quantityUnitStock = try modelContext.fetch(
                    FetchDescriptor<MDQuantityUnit>(
                        predicate: #Predicate { qu in
                            qu.id == stockDetails.quantityUnitStockID
                        }
                    )
                ).first
                stockDetails.location = try modelContext.fetch(
                    FetchDescriptor<MDLocation>(
                        predicate: #Predicate { location in
                            location.id == stockDetails.locationID
                        }
                    )
                ).first
                self.modelContext.insert(stockDetails)
                try self.modelContext.save()
            case .locations:
                let stockLocations: StockLocations = try await grocyApi.getStockProductInfo(stockModeGet: .locations, productID: productID, queries: queries)
                self.stockProductLocations[productID] = stockLocations
                try swiftDataSync.syncPersistentCollection(stockLocations)

            case .entries:
                let stockEntries: StockEntries = try await grocyApi.getStockProductInfo(stockModeGet: .entries, productID: productID, queries: queries)
                self.stockProductEntries[productID] = stockEntries
                try swiftDataSync.syncPersistentCollection(stockEntries)

            case .priceHistory:
                _ = try await getProductPriceHistory(productID: productID)
            }
        } catch {
            GrocyLogger.error("Data request failed for \(stockModeGet). Message: \("\(error)")")
            self.failedToLoadErrors.append(error)
        }
    }

    /// The product's purchase prices, newest first. Kept in memory only (`stockProductPriceHistories`), not in SwiftData.
    @discardableResult
    func getProductPriceHistory(productID: Int) async throws -> ProductPriceHistories {
        let priceHistory: ProductPriceHistories = try await grocyApi.getStockProductInfo(stockModeGet: .priceHistory, productID: productID, queries: nil)
        self.stockProductPriceHistories[productID] = priceHistory
        return priceHistory
    }

    func getStockProductLocations(productID: Int) async throws {
        self.stockProductLocations[productID] = try await grocyApi.getStockProductInfo(stockModeGet: .locations, productID: productID, queries: nil)
    }

    func putStockProductEntry(id: Int, content: StockEntry) async throws -> StockJournal {
        let jsonContent = try! jsonEncoder.encode(content)
        return try await grocyApi.putStockEntry(entryID: id, content: jsonContent)
    }

    func postStockObject<T: Codable>(id: Int, stockModePost: StockProductPost, content: T) async throws {
        let jsonContent = try! jsonEncoder.encode(content)
        let stockJournalReturn: StockJournal = try await grocyApi.postStock(id: id, content: jsonContent, stockModePost: stockModePost)
        self.lastStockActions.append(contentsOf: stockJournalReturn)
    }

    func undoBookingWithID(id: Int) async throws {
        return try await grocyApi.undoBookingWithID(id: id)
    }

    func getPictureURL(groupName: String, fileName: String) async throws -> String? {
        try await grocyApi.getPictureURL(groupName: groupName, fileName: fileName)
    }

    func getProductPicture(fileName: String, bestFitHeight: Int? = nil, bestFitWidth: Int? = nil) async throws -> Data? {
        if self.productPictures.keys.contains(fileName) {
            return self.productPictures[fileName]
        }
        let productPictureData = try await grocyApi.getFile(
            fileName: fileName,
            groupName: "productpictures",
            bestFitHeight: bestFitHeight,
            bestFitWidth: bestFitWidth
        )
        self.productPictures[fileName] = productPictureData
        return productPictureData
    }

    func getUserPicture(fileName: String, bestFitHeight: Int? = nil, bestFitWidth: Int? = nil) async throws -> Data? {
        if self.productPictures.keys.contains(fileName) {
            return self.productPictures[fileName]
        }
        let userPictureData = try await grocyApi.getFile(
            fileName: fileName,
            groupName: "userpictures",
            bestFitHeight: bestFitHeight,
            bestFitWidth: bestFitWidth
        )
        self.userPictures[fileName] = userPictureData
        return userPictureData
    }

    func getRecipePicture(fileName: String, bestFitHeight: Int? = nil, bestFitWidth: Int? = nil) async throws -> Data? {
        if self.recipePictures.keys.contains(fileName) {
            return self.recipePictures[fileName]
        }
        let recipePictureData = try await grocyApi.getFile(
            fileName: fileName,
            groupName: "recipepictures",
            bestFitHeight: bestFitHeight,
            bestFitWidth: bestFitWidth
        )
        self.recipePictures[fileName] = recipePictureData
        return recipePictureData
    }

    func uploadFile(fileURL: URL, groupName: String, fileName: String) async throws {
        try await grocyApi.putFile(fileURL: fileURL, fileName: fileName, groupName: groupName)
    }

    func uploadFileData(fileData: Data, groupName: String, fileName: String) async throws {
        try await grocyApi.putFileData(fileData: fileData, fileName: fileName, groupName: groupName)
    }

    func deleteFile(groupName: String, fileName: String) async throws {
        try await grocyApi.deleteFile(fileName: fileName, groupName: groupName)
    }

    func externalBarcodeLookup(barcode: String) async throws -> ExternalBarcodeLookup? {
        return try await grocyApi.externalBarcodeLookup(barcode: barcode)
    }

    // MARK: - Shopping Lists
    func shoppingListAction(content: ShoppingListAction, actionType: ShoppingListActionType) async throws {
        let jsonContent = try! jsonEncoder.encode(content)
        try await grocyApi.shoppingListAction(content: jsonContent, actionType: actionType)
    }

    /// Adds a product to a shopping list, or raises the amount of the item that's already there.
    func addProductToShoppingList(content: ShoppingListAddProductModel) async throws {
        let jsonContent = try jsonEncoder.encode(content)
        try await grocyApi.shoppingListAddProduct(content: jsonContent)
    }

    // MARK: - Master Data
    func postMDObject<T: Codable>(object: ObjectEntities, content: T) async throws -> SuccessfulCreationMessage {
        let jsonContent = try! jsonEncoder.encode(content)
        return try await grocyApi.postObject(object: object, content: jsonContent)
    }

    func deleteMDObject(object: ObjectEntities, id: Int) async throws {
        try await grocyApi.deleteObjectWithID(object: object, id: id)
    }

    func putMDObjectWithID<T: Codable>(object: ObjectEntities, id: Int, content: T) async throws {
        let jsonContent = try! jsonEncoder.encode(content)
        try await grocyApi.putObjectWithID(object: object, id: id, content: jsonContent)
    }

    // MARK: - Userfields

    /// The userfields of an entity (e.g. `products` or `userentity-<name>`), in Grocy's order.
    func userfields(for entity: String) -> MDUserFields {
        mdUserFields
            .filter { $0.entity == entity }
            .sorted { ($0.sortNumber ?? .max, $0.name.localizedLowercase) < ($1.sortNumber ?? .max, $1.name.localizedLowercase) }
    }

    func getUserfieldValues(entity: String, objectID: Int) async throws -> UserfieldValues {
        try await grocyApi.getUserfieldValues(entity: entity, objectID: objectID)
    }

    /// Saves changed userfield values. Only the given fields change, the others keep their values.
    func putUserfieldValues(entity: String, objectID: Int, values: [String: String]) async throws {
        guard !values.isEmpty else { return }
        let jsonContent = try jsonEncoder.encode(UserfieldValues(values))
        try await grocyApi.putUserfieldValues(entity: entity, objectID: objectID, content: jsonContent)
        GrocyLogger.info("Saving userfields of \(entity) \(objectID) was successful.")
    }

    /// Saves what a form changed in the userfields of an object: uploads new files, saves the values,
    /// then deletes the files that were replaced or removed.
    func saveUserfields(entity: String, objectID: Int, changes: UserfieldChanges) async throws {
        for (encodedStoredName, data) in changes.uploads {
            try await grocyApi.putFileData(fileData: data, fileName: encodedStoredName, groupName: MDUserField.fileGroup)
        }
        try await putUserfieldValues(entity: entity, objectID: objectID, values: changes.values)
        for encodedStoredName in changes.obsoleteFiles {
            do {
                try await grocyApi.deleteFile(fileName: encodedStoredName, groupName: MDUserField.fileGroup)
            } catch {
                GrocyLogger.warning("Deleting a replaced userfield file failed. \(error)")
            }
        }
    }

    /// A file of a file or picture userfield. Pictures are scaled to fit `bestFitWidth`.
    func getUserfieldFile(value: String, bestFitWidth: Int? = nil) async throws -> Data? {
        guard let encodedStoredName = MDUserField.encodedStoredFileName(of: value) else { return nil }
        if let bestFitWidth {
            return try await grocyApi.getFile(fileName: encodedStoredName, groupName: MDUserField.fileGroup, bestFitHeight: nil, bestFitWidth: bestFitWidth)
        }
        return try await grocyApi.getFileUnmodified(fileName: encodedStoredName, groupName: MDUserField.fileGroup)
    }

    // MARK: - Chores
    func getChoreDetails(id: Int) async {
        do {
            let choreDetails = try await grocyApi.getChoreDetails(id: id)

            self.choreDetails[id] = choreDetails
            let fetchDescriptor = FetchDescriptor<ChoreDetails>(
                predicate: #Predicate { details in
                    details.choreID == id
                }
            )
            if let existingObject = try modelContext.fetch(fetchDescriptor).first {
                self.modelContext.delete(existingObject)
            }
            self.modelContext.insert(choreDetails)
            try self.modelContext.save()
        } catch {
            GrocyLogger.error("Failed to get chore details. \(error)")
        }
    }

    func executeChore(id: Int, content: ChoreExecuteModel) async throws -> ChoreLogEntry {
        let jsonContent = try! jsonEncoder.encode(content)
        return try await grocyApi.choreExecute(id: id, content: jsonContent)
    }

    func undoChoreWithID(id: Int) async throws {
        return try await grocyApi.undoChoreWithID(id: id)
    }

    // MARK: - Batteries
    func getBatteryDetails(id: Int) async throws -> BatteryDetails {
        return try await grocyApi.getBatteryDetails(id: id)
    }

    func chargeBattery(id: Int, content: BatteryChargeModel) async throws {
        let jsonContent = try jsonEncoder.encode(content)
        try await grocyApi.batteryCharge(id: id, content: jsonContent)
    }

    func undoBatteryChargeCycle(id: Int) async throws {
        try await grocyApi.undoBatteryChargeCycle(id: id)
    }

    // MARK: - Equipment
    /// Downloads an instruction manual. Grocy expects the file name Base64 encoded in the path.
    func getInstructionManual(fileName: String) async throws -> Data {
        let encodedFileName = Data(fileName.utf8).base64EncodedString()
        return try await grocyApi.getFileUnmodified(fileName: encodedFileName, groupName: MDEquipment.instructionManualGroup)
    }

    func uploadInstructionManual(fileData: Data, fileName: String) async throws {
        let encodedFileName = Data(fileName.utf8).base64EncodedString()
        try await grocyApi.putFileData(fileData: fileData, fileName: encodedFileName, groupName: MDEquipment.instructionManualGroup)
    }

    func deleteInstructionManual(fileName: String) async throws {
        let encodedFileName = Data(fileName.utf8).base64EncodedString()
        try await grocyApi.deleteFile(fileName: encodedFileName, groupName: MDEquipment.instructionManualGroup)
    }

    // MARK: - Tasks
    func executeTask(taskID: Int, content: TaskExecuteModel) async throws {
        let jsonContent = try! jsonEncoder.encode(content)
        try await grocyApi.taskComplete(taskID: taskID, content: jsonContent)
    }

    func undoTask(taskID: Int) async throws {
        return try await grocyApi.taskUndo(taskID: taskID)
    }

    // MARK: - Recipes
    func addNotFulfilledProductsToShoppinglist(recipeID: Int, content: RecipeAddToShLModel) async throws {
        let jsonContent = try! jsonEncoder.encode(content)
        try await grocyApi.addNotFulfilledProductsToShoppinglist(id: recipeID, content: jsonContent)
    }

    func consumeRecipe(recipeID: Int) async throws {
        try await grocyApi.recipeConsume(id: recipeID)
    }

    func copyRecipe(recipeID: Int) async throws {
        try await grocyApi.recipeCopy(id: recipeID)
    }

    /// Copies a product on the server and returns the copy's ID.
    func copyProduct(productID: Int) async throws -> Int {
        try await grocyApi.copyProduct(id: productID).createdObjectID
    }
}
