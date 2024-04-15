//
//  GrocyModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import Foundation
import Combine
import SwiftUI
import OSLog
import WebKit
import SwiftData

@Observable
@MainActor
class GrocyViewModel {
    var grocyApi: GrocyAPI
    
    //    @ObservationIgnored @Environment(\.modelContext) private var modelContext
    var modelContext: ModelContext
    
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
    
    let grocyLog = Logger(subsystem: "Grocy-Mobile", category: "APIAccess")
    
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
                        isDemoMode: isDemoModus)
                } catch {
                    
                }
            }
        } else {
            self.postLog("Not logged in", type: .info)
        }
    }
    
    func setDemoModus() {
        isDemoModus = true
        grocyApi.setLoginData(baseURL: demoServerURL, apiKey: "")
        grocyApi.setTimeoutInterval(timeoutInterval: timeoutInterval)
        isLoggedIn = true
        self.setUpdateTimer()
        self.postLog("Switched to demo modus", type: .info)
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
        self.postLog("Switched to login modus", type: .info)
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
            self.refreshTimer = Timer
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
            self.postLog("Server check successful. Logging into Grocy Server \(systemInfo.grocyVersion.version) with app version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?").", type: .info)
            self.systemInfo = systemInfo
            return
        } else {
            self.postLog("Selected server doesn't respond.", type: .error)
            throw APIError.invalidResponse
        }
    }
    
    func findNextID(_ object: ObjectEntities) -> Int {
        var ints: [Int] = []
        switch object {
        case .products:
            ints = self.mdProducts.map{ $0.id }
        case .locations:
            ints = self.mdLocations.map{ $0.id }
        case .shopping_locations:
            ints = self.mdStores.map{ $0.id }
        case .quantity_units:
            ints = self.mdQuantityUnits.map{ $0.id }
        case .quantity_unit_conversions:
            ints = self.mdQuantityUnitConversions.map{ $0.id }
        case .product_groups:
            ints = self.mdProductGroups.map{ $0.id }
        case .shopping_lists:
            ints = self.shoppingListDescriptions.map{ $0.id }
        case .shopping_list:
            ints = self.shoppingList.map{ $0.id }
        case .product_barcodes:
            ints = self.mdProductBarcodes.map{ $0.id }
        case .task_categories:
            ints = self.mdTaskCategories.map{ $0.id }
        case .userfields:
            ints = self.mdUserFields.map{ $0.id }
        case .userentities:
            ints = self.mdUserEntities.map{ $0.id }
        default:
            self.postLog("Find next ID not implemented for \(object.rawValue).", type: .error)
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
            self.postLog("Getting timestamp failed. Message: \("\(error)")", type: .error)
        }
    }
    
    func getObjectAndSaveSwiftData<T: Codable & Equatable & PersistentModel>(object: ObjectEntities) async throws -> [T] {
        do {
            let objects: [T] = try await grocyApi.getObject(object: object)
            let fetchDescriptor = FetchDescriptor<T>(sortBy: [SortDescriptor(\T.id)])
            let existingObjects = try modelContext.fetch(fetchDescriptor)
            for existingObject in existingObjects {
                if !objects.contains(existingObject)  {
                    self.modelContext.delete(existingObject)
                }
            }
            for newObject in objects {
                if !existingObjects.contains(newObject) {
                    self.modelContext.insert(newObject)
                }
            }
            return objects
        } catch {
            self.postLog("\(error)", type: .error)
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
                            //                            self.recipes = try await grocyApi.getObject(object: object)
                            self.recipes = try await self.getObjectAndSaveSwiftData(object: object)
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
                            self.postLog("Object not implemented", type: .error)
                        }
                        self.timeStampsObjects[object] = timeStamp
                        self.loadingObjectEntities.remove(object)
                        self.failedToLoadObjects.remove(object)
                    }
                } catch {
                    self.postLog("Data request failed for \(object). Message: \("\(error)")", type: .error)
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
                                if !self.stock.contains(existingObject)  {
                                    self.modelContext.delete(existingObject)
                                }
                            }
                            for newObject in self.stock {
                                if !existingObjects.contains(newObject) {
                                    let productFetchDescriptor = FetchDescriptor<MDProduct>(predicate: #Predicate { product in
                                        product.id == newObject.productID
                                    })
                                    if let existingProduct = try modelContext.fetch(productFetchDescriptor).first {
                                        newObject.product = existingProduct
                                    }
                                }
                            }
                            try self.modelContext.save()
                        case .system_config:
                            self.systemConfig = try await grocyApi.getSystemConfig()
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
                    self.postLog("Data request failed for \(additionalObject). Message: \("\(error)")", type: .error)
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
        self.postLog("Update triggered", type: .debug)
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
            try modelContext.delete(model: MDProduct.self)
            try modelContext.delete(model: MDProductBarcode.self)
            try modelContext.delete(model: MDLocation.self)
            try modelContext.delete(model: MDStore.self)
            try modelContext.delete(model: MDQuantityUnit.self)
            try modelContext.delete(model: MDQuantityUnitConversion.self)
            try modelContext.delete(model: MDProductGroup.self)
            try modelContext.delete(model: ShoppingListItem.self)
            try modelContext.delete(model: ShoppingListDescription.self)
            try modelContext.delete(model: StockElement.self)
            try modelContext.delete(model: VolatileStock.self)
            try modelContext.delete(model: StockJournalEntry.self)
            try modelContext.delete(model: GrocyUser.self)
            try modelContext.delete(model: GrocyUserSettings.self)
            try modelContext.delete(model: StockEntry.self)
            try modelContext.delete(model: StockProductDetails.self)
            try modelContext.delete(model: StockProduct.self)
            try modelContext.delete(model: Recipe.self)
        } catch {
            self.postLog("\(error)", type: .error)
        }
        
        self.postLog("Deleted all cached data from the viewmodel.", type: .info)
    }
    
    func postLog(_ message: String, type: OSLogType) {
        switch type {
        case .error:
            self.grocyLog.error("\(message, privacy: .public)")
        case .info:
            self.grocyLog.info("\(message, privacy: .public)")
        case .debug:
            self.grocyLog.debug("\(message, privacy: .public)")
        case .fault:
            self.grocyLog.fault("\(message, privacy: .public)")
        default:
            self.grocyLog.log("\(message, privacy: .public)")
        }
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
            let logEntriesFiltered =  allEntries
                .compactMap { $0 as? OSLogEntryLog }
                .filter { $0.subsystem == "Grocy-Mobile" }
            
            self.logEntries = logEntriesFiltered
        } catch {
            self.postLog("Error getting log entries", type: .error)
        }
    }
    
    func updateShoppingListFromReminders(reminders: [Reminder]) async {
        for reminder in reminders {
            var nameComponents = reminder.title.components(separatedBy: " ")
            let amount = Double(nameComponents.removeFirst())
            let name = nameComponents.joined(separator: " ")
            if
                let product = self.mdProducts.first(where: { $0.name == name }),
                let entry = self.shoppingList.first(where: { $0.productID == product.id } )
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
                        self.postLog("Shopping entry edited successfully.", type: .info)
                    } catch {
                        self.postLog("Shopping entry edit failed. \(error)", type: .error)
                    }
                }
            } else {
                self.postLog("Found no matching product for the shopping list entry \(name).", type: .info)
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
        let ints = self.users.map{ $0.id }
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
    func getStockProductInfo<T: Codable>(mode: StockProductGet, productID: Int, queries: [String]? = nil) async throws -> T {
        return try await grocyApi.getStockProductInfo(stockModeGet: mode, id: productID, queries: queries)
    }
    
    func requestStockInfo(stockModeGet: StockProductGet, productID: Int, ignoreCached: Bool = true) async throws {
        switch stockModeGet {
        case .details:
            if stockProductDetails.isEmpty || ignoreCached {
                let stockDetails: StockProductDetails = try await getStockProductInfo(mode: stockModeGet, productID: productID)
                self.stockProductDetails[productID] = stockDetails
                let fetchDescriptor = FetchDescriptor<StockProductDetails>(predicate: #Predicate { details in
                    details.productID == productID
                })
                if let existingObject = try modelContext.fetch(fetchDescriptor).first {
                    self.modelContext.delete(existingObject)
                }
                stockDetails.quantityUnitStock = try modelContext.fetch(FetchDescriptor<MDQuantityUnit>(predicate: #Predicate { qu in
                    qu.id == stockDetails.quantityUnitStockID
                })).first
                stockDetails.location = try modelContext.fetch(FetchDescriptor<MDLocation>(predicate: #Predicate { location in
                    location.id == stockDetails.locationID
                })).first
                self.modelContext.insert(stockDetails)
                try self.modelContext.save()
            }
        case .locations:
            print("not implemented")
        case .entries:
            if stockProductEntries[productID]?.isEmpty ?? true || ignoreCached {
                self.stockProductEntries[productID] = try await getStockProductInfo(mode: stockModeGet, productID: productID)
            }
        case .priceHistory:
            print("not implemented")
        }
    }
    
    func getStockProductLocations(productID: Int) async throws {
        self.stockProductLocations[productID] = try await grocyApi.getStockProductInfo(stockModeGet: .locations, id: productID, queries: nil)
    }
    
    func getStockProductEntries(productID: Int) async throws {
        self.stockProductEntries[productID] = try await grocyApi.getStockProductInfo(stockModeGet: .entries, id: productID, queries: ["include_sub_products=true"])
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
