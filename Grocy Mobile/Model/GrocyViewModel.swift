//
//  GrocyModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

internal import Combine
import Foundation
import OSLog
import SwiftData
import SwiftUI
import WebKit

@MainActor
@Observable
class GrocyViewModel {
    var grocyApi: GrocyAPI

    let modelContext: ModelContext
    let profileModelContext: ModelContext?
    private let swiftDataSync: SwiftDataSynchronizer

    var aiCategoryMatcher: AICategoryMatcher?

    @ObservationIgnored @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @ObservationIgnored @AppStorage("isDemoModus") var isDemoModus: Bool = false
    @ObservationIgnored @AppStorage("demoServerURL") var demoServerURL: String = GrocyAPP.DemoServers.noLanguage.rawValue
    @ObservationIgnored @AppStorage("localizationKey") var localizationKey: String = "en"
    @ObservationIgnored @AppStorage("timeoutInterval") var timeoutInterval: Double = 60.0
    @ObservationIgnored @AppStorage("autoReload") private var autoReload: Bool = false
    @ObservationIgnored @AppStorage("autoReloadInterval") private var autoReloadInterval: Int = 0
    @ObservationIgnored @AppStorage("syncShoppingListToReminders") private var syncShoppingListToReminders: Bool = false
    @ObservationIgnored @AppStorage("shoppingListToSyncID") private var shoppingListToSyncID: Int = 0
    @ObservationIgnored @AppStorage("selectedServerProfileID") private var selectedServerProfileID: UUID?
    @ObservationIgnored @AppStorage("useAppleIntelligence") var useAppleIntelligence: Bool = true

    @ObservationIgnored @State private var refreshTimer: Timer?

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
    var grocyTasks: GrocyTasks = []

    var mdProducts: MDProducts = []
    var mdProductBarcodes: MDProductBarcodes = []
    var mdLocations: MDLocations = []
    var mdStores: MDStores = []
    var mdQuantityUnits: MDQuantityUnits = []
    var mdQuantityUnitConversions: MDQuantityUnitConversions = []
    var mdProductGroups: MDProductGroups = []
    var mdBatteries: MDBatteries = []
    var mdTaskCategories: MDTaskCategories = []
    var mdUserFields: MDUserFields = []
    var mdUserEntities: MDUserEntities = []
    var mdChores: MDChores = []

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
            Task {
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
                            customHeaders: profile.customHeaders ?? []
                        )
                    }
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

    func setDemoModus() {
        grocyApi.setLoginData(baseURL: demoServerURL, apiKey: "", customHeaders: [:])
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
            customHeaders: Dictionary(uniqueKeysWithValues: (selectedServerProfile.customHeaders ?? []).map { (header: LoginCustomHeader) in ((header.headerName) as String, (header.headerValue) as String) })
        )
        grocyApi.setTimeoutInterval(timeoutInterval: timeoutInterval)
        isDemoModus = false
        isLoggedIn = true
        self.setUpdateTimer()
        GrocyLogger.info("Switched to login modus")
    }

    func logout() {
        self.stopUpdateTimer()
        grocyApi.clearHassData()
        grocyApi.clearLoginData()
        self.deleteAllCachedData()
        isLoggedIn = false
    }

    func cancelAllURLSessionTasks() {
        URLSession.shared.getAllTasks(completionHandler: { tasks in
            for task in tasks {
                task.cancel()
            }
        })
    }

    func stopUpdateTimer() {
        self.refreshTimer?.invalidate()
    }

    func setUpdateTimer() {
        if self.autoReload && self.autoReloadInterval != 0 {
            self.stopUpdateTimer()
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

    func checkServer(baseURL: String, apiKey: String?, useHassIngress: Bool = false, hassToken: String = "", isDemoMode: Bool, customHeaders: [LoginCustomHeader] = []) async throws {
        self.grocyApi = GrocyApi()
        if useHassIngress && !isDemoMode, let hassAPIPath = getHomeAssistantPathFromIngress(ingressPath: baseURL) {
            await grocyApi.setHassData(hassURL: hassAPIPath, hassToken: hassToken)
        }
        grocyApi.setLoginData(baseURL: baseURL, apiKey: apiKey ?? "", customHeaders: Dictionary(uniqueKeysWithValues: customHeaders.map({ ($0.headerName, $0.headerValue) })))
        grocyApi.setTimeoutInterval(timeoutInterval: timeoutInterval)
        let systemInfo = try await grocyApi.getSystemInfo()
        if !systemInfo.grocyVersion.version.isEmpty {
            GrocyLogger.info("Server check successful. Logging into Grocy Server \(systemInfo.grocyVersion.version) with app version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?").")
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
        case .tasks:
            ints = self.grocyTasks.map { $0.id }
        case .task_categories:
            ints = self.mdTaskCategories.map { $0.id }
        case .userfields:
            ints = self.mdUserFields.map { $0.id }
        case .userentities:
            ints = self.mdUserEntities.map { $0.id }
        default:
            throw APIError.invalidResponse
        }
        var startvar = 1
        while ints.contains(startvar) { startvar += 1 }
        return startvar
    }

    func requestData(objects: [ObjectEntities]? = nil, additionalObjects: [AdditionalEntities]? = nil) async {
        // Guard against calling API before initialization is complete
        guard grocyApi.isLoggedIn else { return }

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
                        case .chores:
                            self.mdChores = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.mdChores)
                        case .chores_log:
                            self.choreLog = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.choreLog)
                        case .locations:
                            self.mdLocations = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.mdLocations)
                        case .product_barcodes:
                            self.mdProductBarcodes = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.mdProductBarcodes)
                        case .product_groups:
                            self.mdProductGroups = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.mdProductGroups)
                        case .products:
                            self.mdProducts = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.mdProducts)
                        case .quantity_unit_conversions:
                            self.mdQuantityUnitConversions = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.mdQuantityUnitConversions)
                        case .recipes:
                            self.recipes = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.recipes)
                        case .recipes_nestings:
                            self.recipesNestings = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.recipesNestings)
                        case .recipes_pos:
                            self.recipesPos = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.recipesPos)
                        case .recipes_pos_resolved:
                            self.recipesPosResolved = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.recipesPosResolved)
                        case .quantity_units:
                            self.mdQuantityUnits = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.mdQuantityUnits)
                        case .shopping_list:
                            self.shoppingList = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.shoppingList)
                        case .shopping_lists:
                            self.shoppingListDescriptions = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.shoppingListDescriptions)
                        case .shopping_locations:
                            self.mdStores = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.mdStores)
                        case .stock:
                            self.stockEntries = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.stockEntries)
                        case .stock_log:
                            self.stockJournal = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.stockJournal)
                        case .stock_current_locations:
                            self.stockCurrentLocations = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.stockCurrentLocations)
                        case .tasks:
                            self.grocyTasks = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.grocyTasks)
                        case .task_categories:
                            self.mdTaskCategories = try await grocyApi.getObject(object: object)
                            try? swiftDataSync.syncPersistentCollection(self.mdTaskCategories)
                        default:
                            GrocyLogger.error("Object not implemented")
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

        case .chores:
            self.chores = try await grocyApi.getChores()
            try? swiftDataSync.syncPersistentCollection(self.chores)

        case .stock:
            self.stock = try await grocyApi.getStock()
            try? swiftDataSync.syncStockElements(self.stock)

        case .system_config:
            self.systemConfig = try await grocyApi.getSystemConfig()
            try? swiftDataSync.syncSingletonModel(SystemConfig.self, with: self.systemConfig)

        case .system_db_changed_time:
            self.systemDBChangedTime = try await grocyApi.getSystemDBChangedTime()

        case .system_info:
            self.systemInfo = try await grocyApi.getSystemInfo()

        case .user_settings:
            self.userSettings = try await grocyApi.getUserSettings()
            try? swiftDataSync.syncSingletonModel(GrocyUserSettings.self, with: self.userSettings)

        case .recipeFulfillments:
            self.recipeFulfillments = try await grocyApi.getRecipeFulfillments()
            try? swiftDataSync.syncPersistentCollection(self.recipeFulfillments)

        case .users:
            self.users = try await grocyApi.getUsers()
            try? swiftDataSync.syncArrayModel(GrocyUser.self, with: self.users)

        case .volatileStock:
            let userSettingsFetch = FetchDescriptor<GrocyUserSettings>()
            let dueSoonDays = (try? modelContext.fetch(userSettingsFetch))?.first?.stockDueSoonDays ?? self.userSettings?.stockDueSoonDays ?? 5
            self.volatileStock = try await grocyApi.getVolatileStock(dueSoonDays: dueSoonDays)
            try? swiftDataSync.syncSingletonModel(VolatileStock.self, with: self.volatileStock)
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
        self.grocyTasks = []

        self.mdProducts = []
        self.mdProductBarcodes = []
        self.mdLocations = []
        self.mdStores = []
        self.mdQuantityUnits = []
        self.mdQuantityUnitConversions = []
        self.mdProductGroups = []
        self.mdBatteries = []
        self.mdTaskCategories = []
        self.mdUserFields = []
        self.mdUserEntities = []

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
            try self.modelContext.delete(model: MDProduct.self)
            try self.modelContext.delete(model: MDProductBarcode.self)
            try self.modelContext.delete(model: MDLocation.self)
            try self.modelContext.delete(model: MDStore.self)
            try self.modelContext.delete(model: MDQuantityUnit.self)
            try self.modelContext.delete(model: MDQuantityUnitConversion.self)
            try self.modelContext.delete(model: MDProductGroup.self)
            try self.modelContext.delete(model: ShoppingListItem.self)
            try self.modelContext.delete(model: ShoppingListDescription.self)
            try self.modelContext.delete(model: StockElement.self)
            try self.modelContext.delete(model: VolatileStock.self)
            try self.modelContext.delete(model: StockJournalEntry.self)
            try self.modelContext.delete(model: GrocyUser.self)
            try self.modelContext.delete(model: GrocyUserSettings.self)
            try self.modelContext.delete(model: StockEntry.self)
            try self.modelContext.delete(model: StockProduct.self)
            try self.modelContext.delete(model: StockProductDetails.self)
            try self.modelContext.delete(model: StockLocation.self)
            try self.modelContext.delete(model: Recipe.self)
            try self.modelContext.delete(model: RecipePos.self)
            try self.modelContext.delete(model: RecipePosResolvedElement.self)
            try self.modelContext.delete(model: StockLocation.self)
            try self.modelContext.delete(model: SystemConfig.self)
            try self.modelContext.delete(model: MDChore.self)
            try self.modelContext.delete(model: Chore.self)
            try self.modelContext.delete(model: ChoreDetails.self)
            try self.modelContext.delete(model: GrocyTask.self)
        } catch {
            GrocyLogger.error("\(error)")
        }

        GrocyLogger.info("Deleted all cached data from the viewmodel.")
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
                try? swiftDataSync.syncPersistentCollection(stockLocations)

            case .entries:
                let stockEntries: StockEntries = try await grocyApi.getStockProductInfo(stockModeGet: .entries, productID: productID, queries: queries)
                self.stockProductEntries[productID] = stockEntries
                try? swiftDataSync.syncPersistentCollection(stockEntries)

            case .priceHistory:
                print("not implemented")
            }
        } catch {
            GrocyLogger.error("Data request failed for \(stockModeGet). Message: \("\(error)")")
            self.failedToLoadErrors.append(error)
        }
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
        let productPictureData = try await grocyApi.getFile(fileName: fileName, groupName: "productpictures", bestFitHeight: bestFitHeight, bestFitWidth: bestFitWidth)
        self.productPictures[fileName] = productPictureData
        return productPictureData
    }

    func getUserPicture(fileName: String, bestFitHeight: Int? = nil, bestFitWidth: Int? = nil) async throws -> Data? {
        if self.productPictures.keys.contains(fileName) {
            return self.productPictures[fileName]
        }
        let userPictureData = try await grocyApi.getFile(fileName: fileName, groupName: "userpictures", bestFitHeight: bestFitHeight, bestFitWidth: bestFitWidth)
        self.userPictures[fileName] = userPictureData
        return userPictureData
    }

    func getRecipePicture(fileName: String, bestFitHeight: Int? = nil, bestFitWidth: Int? = nil) async throws -> Data? {
        if self.recipePictures.keys.contains(fileName) {
            return self.recipePictures[fileName]
        }
        let recipePictureData = try await grocyApi.getFile(fileName: fileName, groupName: "recipepictures", bestFitHeight: bestFitHeight, bestFitWidth: bestFitWidth)
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
}
