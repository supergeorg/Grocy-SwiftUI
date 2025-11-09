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

@Observable
@MainActor
class GrocyViewModel {
    var grocyApi: GrocyAPI

    let modelContext: ModelContext

    @ObservationIgnored @AppStorage("grocyServerURL") var grocyServerURL: String = ""
    @ObservationIgnored @AppStorage("grocyAPIKey") var grocyAPIKey: String = ""
    @ObservationIgnored @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @ObservationIgnored @AppStorage("isDemoModus") var isDemoModus: Bool = false
    @ObservationIgnored @AppStorage("demoServerURL") var demoServerURL: String = GrocyAPP.DemoServers.noLanguage.rawValue
    @ObservationIgnored @AppStorage("localizationKey") var localizationKey: String = "en"
    @ObservationIgnored @AppStorage("timeoutInterval") var timeoutInterval: Double = 60.0
    @ObservationIgnored @AppStorage("autoReload") private var autoReload: Bool = false
    @ObservationIgnored @AppStorage("autoReloadInterval") private var autoReloadInterval: Int = 0
    @ObservationIgnored @AppStorage("syncShoppingListToReminders") private var syncShoppingListToReminders: Bool = false
    @ObservationIgnored @AppStorage("shoppingListToSyncID") private var shoppingListToSyncID: Int = 0
    @ObservationIgnored @AppStorage("useHassIngress") var useHassIngress: Bool = false
    @ObservationIgnored @AppStorage("hassToken") var hassToken: String = ""

    var systemInfo: SystemInfo?
    var systemDBChangedTime: SystemDBChangedTime?
    var systemConfig: SystemConfig?
    var userSettings: GrocyUserSettings?

    var users: GrocyUsers = []
    var currentUser: GrocyUser? = nil
    var stock: Stock = []
    var volatileStock: VolatileStock? = nil
    var stockJournal: StockJournal = []
    var shoppingListDescriptions: ShoppingListDescriptions = []
    var shoppingList: [ShoppingListItem] = []
    var recipes: Recipes = []
    var recipeFulfillments: RecipeFulfilments = []
    var recipePosResolved: [RecipePosResolvedElement] = []

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

    var stockProductDetails: [Int: StockProductDetails] = [:]
    var stockProductLocations: [Int: StockLocations] = [:]
    var stockProductEntries: [Int: StockEntries] = [:]
    var stockProductPriceHistories: [Int: ProductPriceHistories] = [:]

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

    @ObservationIgnored @State private var refreshTimer: Timer?

    let jsonEncoder = JSONEncoder()

    init(modelContext: ModelContext) {
        self.grocyApi = GrocyApi()
        self.modelContext = modelContext
        self.modelContext.autosaveEnabled = false
        jsonEncoder.dateEncodingStrategy = .custom({ (date, encoder) in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)
            var container = encoder.singleValueContainer()
            try container.encode(dateString)
        })
        jsonEncoder.outputFormatting = .prettyPrinted
        if isLoggedIn {
            grocyApi.setLoginData(baseURL: grocyServerURL, apiKey: grocyAPIKey)
            Task {
                do {
                    try await checkServer(
                        baseURL: !isDemoModus ? grocyServerURL : demoServerURL,
                        apiKey: !isDemoModus ? grocyAPIKey : "",
                        isDemoMode: isDemoModus
                    )
                } catch {

                }
            }
        } else {
            GrocyLogger.info("Not logged in")
        }
    }

    func setDemoModus() {
        isDemoModus = true
        grocyApi.setLoginData(baseURL: demoServerURL, apiKey: "")
        grocyApi.setTimeoutInterval(timeoutInterval: timeoutInterval)
        isLoggedIn = true
        self.setUpdateTimer()
        GrocyLogger.info("Switched to demo modus")
    }

    func setLoginModus() async {
        if useHassIngress, let hassAPIPath = getHomeAssistantPathFromIngress(ingressPath: grocyServerURL) {
            await grocyApi.setHassData(hassURL: hassAPIPath, hassToken: hassToken)
        }
        grocyApi.setLoginData(baseURL: grocyServerURL, apiKey: grocyAPIKey)
        grocyApi.setTimeoutInterval(timeoutInterval: timeoutInterval)
        isDemoModus = false
        isLoggedIn = true
        self.setUpdateTimer()
        GrocyLogger.info("Switched to login modus")
    }

    func logout() {
        self.stopUpdateTimer()
        grocyApi.clearHassData()
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
        if self.refreshTimer != nil {
            self.refreshTimer!.invalidate()
        }
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

    func checkServer(baseURL: String, apiKey: String?, isDemoMode: Bool) async throws {
        self.grocyApi = GrocyApi()
        if useHassIngress && !isDemoMode, let hassAPIPath = getHomeAssistantPathFromIngress(ingressPath: grocyServerURL) {
            await grocyApi.setHassData(hassURL: hassAPIPath, hassToken: hassToken)
        }
        grocyApi.setLoginData(baseURL: baseURL, apiKey: apiKey ?? "")
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

    func findNextID(_ object: ObjectEntities) -> Int {
        var ints: [Int] = []
        switch object {
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
        case .task_categories:
            ints = self.mdTaskCategories.map { $0.id }
        case .userfields:
            ints = self.mdUserFields.map { $0.id }
        case .userentities:
            ints = self.mdUserEntities.map { $0.id }
        default:
            GrocyLogger.error("Find next ID not implemented for \(object.rawValue).")
        }
        var startvar = 1
        while ints.contains(startvar) { startvar += 1 }
        return startvar
    }

    func requestData(objects: [ObjectEntities]? = nil, additionalObjects: [AdditionalEntities]? = nil) async {
        do {
            let timestamp = try await grocyApi.getSystemDBChangedTime()
            await self.requestDataWithTimeStamp(objects: objects, additionalObjects: additionalObjects, timeStamp: timestamp)
        } catch {
            GrocyLogger.error("Getting timestamp failed. Message: \("\(error)")")
        }
    }

    func getObjectAndSaveSwiftData<T: Codable & Equatable & Identifiable & PersistentModel>(object: ObjectEntities) async throws -> [T] {
        do {
            let incomingObjects: [T] = try await grocyApi.getObject(object: object)
            let fetchDescriptor = FetchDescriptor<T>(sortBy: [SortDescriptor(\T.id)])
            let existingObjects = try modelContext.fetch(fetchDescriptor)

            // Process any pending changes before proceeding
            modelContext.processPendingChanges()

            // Build lookup dictionaries
            let existingById = Dictionary(uniqueKeysWithValues: existingObjects.map { ($0.id, $0) })
            let incomingById = Dictionary(uniqueKeysWithValues: incomingObjects.map { ($0.id, $0) })

            // Delete removed objects
            for (id, existingObject) in existingById {
                if incomingById[id] == nil {
                    modelContext.delete(existingObject)
                }
            }

            // Insert new or updated objects
            for (id, newObject) in incomingById {
                if let existing = existingById[id] {
                    if existing != newObject {
                        modelContext.delete(existing)
                        modelContext.insert(newObject)
                    }
                    // else: identical, skip
                } else {
                    modelContext.insert(newObject)
                }
            }

            try modelContext.save()
            return incomingObjects
        } catch {
            GrocyLogger.error("Failed to save data: \(error)")
            throw error
        }
    }

    func requestDataWithTimeStamp(objects: [ObjectEntities]? = nil, additionalObjects: [AdditionalEntities]? = nil, timeStamp: SystemDBChangedTime) async {
        if let objects = objects {
            for object in objects {
                do {
                    if timeStamp != self.timeStampsObjects[object] {
                        loadingObjectEntities.insert(object)
                        switch object {
                        case .batteries:
                            self.mdBatteries = try await grocyApi.getObject(object: object)
                        case .locations:
                            self.mdLocations = try await self.getObjectAndSaveSwiftData(object: object)
                        case .product_barcodes:
                            self.mdProductBarcodes = try await self.getObjectAndSaveSwiftData(object: object)
                        case .product_groups:
                            self.mdProductGroups = try await self.getObjectAndSaveSwiftData(object: object)
                        case .products:
                            self.mdProducts = try await self.getObjectAndSaveSwiftData(object: object)
                        case .quantity_unit_conversions:
                            self.mdQuantityUnitConversions = try await self.getObjectAndSaveSwiftData(object: object)
                        case .recipes:
                            self.recipes = try await self.getObjectAndSaveSwiftData(object: object)
                        case .recipes_pos_resolved:
                            self.recipePosResolved = try await self.getObjectAndSaveSwiftData(object: object)
                        case .quantity_units:
                            self.mdQuantityUnits = try await self.getObjectAndSaveSwiftData(object: object)
                        case .shopping_list:
                            self.shoppingList = try await self.getObjectAndSaveSwiftData(object: object)
                        case .shopping_lists:
                            self.shoppingListDescriptions = try await self.getObjectAndSaveSwiftData(object: object)
                        case .shopping_locations:
                            self.mdStores = try await self.getObjectAndSaveSwiftData(object: object)
                        case .stock_log:
                            self.stockJournal = try await self.getObjectAndSaveSwiftData(object: object)
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
                }
            }
        }
        if let additionalObjects = additionalObjects {
            for additionalObject in additionalObjects {
                do {
                    if timeStamp != self.timeStampsAdditionalObjects[additionalObject] {
                        loadingAdditionalEntities.insert(additionalObject)
                        switch additionalObject {
                        case .current_user:
                            self.currentUser = try await grocyApi.getUser().first
                        case .stock:
                            self.stock = try await grocyApi.getStock()
                            let fetchDescriptor = FetchDescriptor<StockElement>()
                            let existingObjects = try modelContext.fetch(fetchDescriptor)
                            for existingObject in existingObjects {
                                if !self.stock.contains(existingObject) {
                                    self.modelContext.delete(existingObject)
                                }
                            }
                            for newObject in self.stock {
                                if !existingObjects.contains(newObject) {
                                    let productFetchDescriptor = FetchDescriptor<MDProduct>(
                                        predicate: #Predicate { product in
                                            product.id == newObject.productID
                                        }
                                    )
                                    if let existingProduct = try modelContext.fetch(productFetchDescriptor).first {
                                        newObject.product = existingProduct
                                    }
                                }
                            }
                            try self.modelContext.save()
                        case .system_config:
                            self.systemConfig = try await grocyApi.getSystemConfig()
                            try self.modelContext.delete(model: SystemConfig.self)
                            if let cfg = self.systemConfig {
                                self.modelContext.insert(cfg)
                            }
                            try self.modelContext.save()
                        case .system_db_changed_time:
                            self.systemDBChangedTime = try await grocyApi.getSystemDBChangedTime()
                        case .system_info:
                            self.systemInfo = try await grocyApi.getSystemInfo()
                        case .user_settings:
                            self.userSettings = try await grocyApi.getUserSettings()
                            try self.modelContext.delete(model: GrocyUserSettings.self)
                            if let userSet = self.userSettings {
                                self.modelContext.insert(userSet)
                            }
                            try self.modelContext.save()
                        case .recipeFulfillments:
                            self.recipeFulfillments = try await grocyApi.getRecipeFulfillments()
                        case .users:
                            self.users = try await grocyApi.getUsers()
                            try self.modelContext.delete(model: GrocyUser.self)
                            for user in self.users {
                                self.modelContext.insert(user)
                            }
                            try self.modelContext.save()
                        case .volatileStock:
                            let userSettingsFetch = FetchDescriptor<GrocyUserSettings>()
                            let dueSoonDays = try modelContext.fetch(userSettingsFetch).first?.stockDueSoonDays ?? self.userSettings?.stockDueSoonDays ?? 5
                            self.volatileStock = try await grocyApi.getVolatileStock(dueSoonDays: dueSoonDays)
                            try self.modelContext.delete(model: VolatileStock.self)
                            if let volatileStock = self.volatileStock {
                                self.modelContext.insert(volatileStock)
                            }
                            try self.modelContext.save()
                        }
                        self.timeStampsAdditionalObjects[additionalObject] = timeStamp
                        self.loadingAdditionalEntities.remove(additionalObject)
                        self.failedToLoadAdditionalObjects.remove(additionalObject)
                    }
                } catch {
                    GrocyLogger.error("Data request failed for \(additionalObject). Message: \("\(error)")")
                    self.failedToLoadAdditionalObjects.insert(additionalObject)
                    self.failedToLoadErrors.append(error)
                }
            }
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
        systemInfo = nil
        systemDBChangedTime = nil
        systemConfig = nil
        userSettings = nil

        users = []
        currentUser = nil
        stock = []
        volatileStock = nil
        stockJournal = []
        shoppingListDescriptions = []
        shoppingList = []
        recipes = []
        recipeFulfillments = []
        recipePosResolved = []

        mdProducts = []
        mdProductBarcodes = []
        mdLocations = []
        mdStores = []
        mdQuantityUnits = []
        mdQuantityUnitConversions = []
        mdProductGroups = []
        mdBatteries = []
        mdTaskCategories = []
        mdUserFields = []
        mdUserEntities = []

        stockProductDetails = [:]
        stockProductLocations = [:]
        stockProductEntries = [:]
        stockProductPriceHistories = [:]

        lastStockActions = []

        timeStampsObjects.removeAll()
        timeStampsAdditionalObjects.removeAll()

        failedToLoadObjects.removeAll()
        failedToLoadAdditionalObjects.removeAll()
        failedToLoadErrors.removeAll()

        productPictures.removeAll()
        userPictures.removeAll()
        recipePictures.removeAll()

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
            try self.modelContext.delete(model: StockProductDetails.self)
            try self.modelContext.delete(model: StockProduct.self)
            try self.modelContext.delete(model: Recipe.self)
            try self.modelContext.delete(model: RecipePosResolvedElement.self)
        } catch {
            GrocyLogger.error("\(error)")
        }

        GrocyLogger.info("Deleted all cached data from the viewmodel.")
    }

    func getLogEntries() {
        do {
            // Open the log store.
            let logStore = try OSLogStore(scope: .currentProcessIdentifier)

            // Get all the logs from the last hour.
            let oneHourAgo = logStore.position(date: Date().addingTimeInterval(-3600))

            // Fetch log objects.
            let allEntries = try logStore.getEntries(at: oneHourAgo)

            // Filter the log to be relevant for our specific subsystem
            // and remove other elements (signposts, etc).
            let logEntriesFiltered =
                allEntries
                .compactMap { $0 as? OSLogEntryLog }
                .filter { $0.subsystem == "georgappdev.Grocy" }

            self.logEntries = logEntriesFiltered
        } catch {
            GrocyLogger.error("Error getting log entries")
        }
    }

    func updateShoppingListFromReminders(reminders: [Reminder]) async {
        for reminder in reminders {
            var nameComponents = reminder.title.components(separatedBy: " ")
            let amount = Double(nameComponents.removeFirst())
            let name = nameComponents.joined(separator: " ")
            if let product = self.mdProducts.first(where: { $0.name == name }),
                let entry = self.shoppingList.first(where: { $0.productID == product.id })
            {
                let shoppingListEntryNew = ShoppingListItem(
                    id: entry.id,
                    productID: entry.productID,
                    note: reminder.notes,
                    amount: amount ?? entry.amount,
                    shoppingListID: entry.shoppingListID,
                    done: reminder.isComplete ? 1 : 0,
                    quID: entry.quID,
                    rowCreatedTimestamp: entry.rowCreatedTimestamp
                )
                if shoppingListEntryNew.note != entry.note, shoppingListEntryNew.amount != entry.amount, shoppingListEntryNew.done != entry.done {
                    do {
                        try await self.putMDObjectWithID(
                            object: .shopping_list,
                            id: entry.id,
                            content: shoppingListEntryNew
                        )
                        GrocyLogger.info("Shopping entry edited successfully.")
                    } catch {
                        GrocyLogger.error("Shopping entry edit failed. \(error)")
                    }
                }
            } else {
                GrocyLogger.info("Found no matching product for the shopping list entry \(name).")
            }
        }
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
    //    func getCurrencySymbol() -> String {
    //        let locale = NSLocale(localeIdentifier: localizationKey)
    //        return locale.displayName(forKey: NSLocale.Key.currencySymbol, value: self.systemConfig?.currency ?? "CURRENCY") ?? "CURRENCY"
    //    }

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
    func requestStockInfo(stockModeGet: StockProductGet, productID: Int) async {
        do {
            switch stockModeGet {
            case .details:
                let stockDetails: StockProductDetails = try await grocyApi.getStockProductInfo(stockModeGet: .details, productID: productID, queries: nil)
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
                print("not implemented")
            case .entries:
                let stockEntries: StockEntries = try await grocyApi.getStockProductInfo(stockModeGet: .entries, productID: productID, queries: nil)
                self.stockProductEntries[productID] = stockEntries
                
                // Process any pending changes before proceeding
                modelContext.processPendingChanges()
                
                let fetchDescriptor = FetchDescriptor<StockEntry>(
                    predicate: #Predicate { entry in
                        entry.productID == productID
                    }
                )
                let existingObjects = try modelContext.fetch(fetchDescriptor)
                
                // Build lookup dictionaries
                let existingById = Dictionary(uniqueKeysWithValues: existingObjects.map { ($0.id, $0) })
                let incomingById = Dictionary(uniqueKeysWithValues: stockEntries.map { ($0.id, $0) })
                
                // Delete removed objects
                for (id, existingObject) in existingById {
                    if incomingById[id] == nil {
                        modelContext.delete(existingObject)
                    }
                }
                
                // Insert new or updated objects
                for (id, newObject) in incomingById {
                    if let existing = existingById[id] {
                        if existing != newObject {
                            modelContext.delete(existing)
                            modelContext.insert(newObject)
                        }
                        // else: identical, skip
                    } else {
                        modelContext.insert(newObject)
                    }
                }
                
                try modelContext.save()
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

    func getStockProductEntries(productID: Int) async throws {
        self.stockProductEntries[productID] = try await grocyApi.getStockProductInfo(stockModeGet: .entries, productID: productID, queries: ["include_sub_products=true"])
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

    // MARK: -Shopping Lists

    func addShoppingListItem(content: ShoppingListItemAdd) async throws {
        let jsonContent = try! jsonEncoder.encode(content)
        try await grocyApi.shoppingListAddItem(content: jsonContent)
    }

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
}
