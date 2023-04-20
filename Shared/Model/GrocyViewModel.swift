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

class GrocyViewModel: ObservableObject {
    var grocyApi: GrocyAPI
    
    @AppStorage("grocyServerURL") var grocyServerURL: String = ""
    @AppStorage("grocyAPIKey") var grocyAPIKey: String = ""
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("isDemoModus") var isDemoModus: Bool = false
    @AppStorage("demoServerURL") var demoServerURL: String = GrocyAPP.DemoServers.noLanguage.rawValue
    @AppStorage("localizationKey") var localizationKey: String = "en"
    @AppStorage("timeoutInterval") var timeoutInterval: Double = 60.0
    @AppStorage("autoReload") private var autoReload: Bool = false
    @AppStorage("autoReloadInterval") private var autoReloadInterval: Int = 0
    @AppStorage("syncShoppingListToReminders") private var syncShoppingListToReminders: Bool = false
    @AppStorage("shoppingListToSyncID") private var shoppingListToSyncID: Int = 0
    
    static let shared = GrocyViewModel()
    
    let grocyLog = Logger(subsystem: "Grocy-Mobile", category: "APIAccess")
    
    @Published var systemInfo: SystemInfo?
    @Published var systemDBChangedTime: SystemDBChangedTime?
    @Published var systemConfig: SystemConfig?
    @Published var userSettings: GrocyUserSettings?
    
    @Published var users: GrocyUsers = []
    @Published var currentUser: GrocyUser? = nil
    @Published var stock: Stock = []
    @Published var volatileStock: VolatileStock? = nil
    @Published var stockJournal: StockJournal = []
    @Published var shoppingListDescriptions: ShoppingListDescriptions = []
    @Published var shoppingList: ShoppingList = []
    @Published var recipes: Recipes = []
    @Published var recipeFulfillments: RecipeFulfilments = []
    
    @Published var mdProducts: MDProducts = []
    @Published var mdProductBarcodes: MDProductBarcodes = []
    @Published var mdLocations: MDLocations = []
    @Published var mdStores: MDStores = []
    @Published var mdQuantityUnits: MDQuantityUnits = []
    @Published var mdQuantityUnitConversions: MDQuantityUnitConversions = []
    @Published var mdProductGroups: MDProductGroups = []
    @Published var mdBatteries: MDBatteries = []
    @Published var mdTaskCategories: MDTaskCategories = []
    @Published var mdUserFields: MDUserFields = []
    @Published var mdUserEntities: MDUserEntities = []
    
    @Published var stockProductDetails: [Int: StockProductDetails] = [:]
    @Published var stockProductLocations: [Int: StockLocations] = [:]
    @Published var stockProductEntries: [Int: StockEntries] = [:]
    @Published var stockProductPriceHistories: [Int: ProductPriceHistories] = [:]
    
    @Published var lastStockActions: StockJournal = []
    
    @Published var failedToLoadObjects = Set<ObjectEntities>()
    @Published var failedToLoadAdditionalObjects = Set<AdditionalEntities>()
    @Published var failedToLoadErrors: [Error] = []
    
    @Published var timeStampsObjects: [ObjectEntities: SystemDBChangedTime] = [:]
    @Published var timeStampsAdditionalObjects: [AdditionalEntities: SystemDBChangedTime] = [:]
    
    @Published var logEntries: [OSLogEntryLog] = []
    
    @Published var loadingObjectEntities: Set<ObjectEntities> = Set()
    @Published var loadingAdditionalEntities: Set<AdditionalEntities> = Set()
    
    var cancellables = Set<AnyCancellable>()
    
    @AppStorage("useHassIngress") var useHassIngress: Bool = false
    @AppStorage("hassToken") var hassToken: String = ""
    
    @State private var refreshTimer: Timer?
    
    let jsonEncoder = JSONEncoder()
    
    init() {
        self.grocyApi = GrocyApi()
        //        jsonEncoder.dateEncodingStrategy = .iso8601
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
    
    //    // Gets the data of a selected entity
    //    func getEntity<T: Codable>(entity: ObjectEntities, completion: @escaping ((Result<T, APIError>) -> ())) {
    //        grocyApi.getObject(object: entity)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //
    //            }) { (getEntityReturn: T) in
    //                DispatchQueue.main.async {
    //                    completion(.success(getEntityReturn))
    //                }
    //            }
    //            .store(in: &cancellables)
    //    }
    // Gets the data of a selected entity
    
    //    // Gets the data of a selected additional entity
    //    func getRecipeFulfillments(completion: @escaping ((Result<RecipeFulfilments, APIError>) -> ())) {
    //        grocyApi.getRecipeFulfillments()
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //
    //            }) { (recipeFulfillments: RecipeFulfilments) in
    //                DispatchQueue.main.async {
    //                    completion(.success(recipeFulfillments))
    //                }
    //            }
    //            .store(in: &cancellables)
    //    }
    
    func requestData(objects: [ObjectEntities]? = nil, additionalObjects: [AdditionalEntities]? = nil) async {
        do {
            let timestamp = try await grocyApi.getSystemDBChangedTime()
            await self.requestDataWithTimeStamp(objects: objects, additionalObjects: additionalObjects, timeStamp: timestamp)
        } catch {
            self.postLog("Getting timestamp failed. Message: \("\(error)")", type: .error)
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
                            self.mdLocations = try await grocyApi.getObject(object: object)
                        case .product_barcodes:
                            self.mdProductBarcodes = try await grocyApi.getObject(object: object)
                        case .product_groups:
                            self.mdProductGroups = try await grocyApi.getObject(object: object)
                        case .products:
                            self.mdProducts = try await grocyApi.getObject(object: object)
                        case .quantity_unit_conversions:
                            self.mdQuantityUnitConversions = try await grocyApi.getObject(object: object)
                        case .quantity_units:
                            self.mdQuantityUnits = try await grocyApi.getObject(object: object)
                        case .shopping_list:
                            self.shoppingList = try await grocyApi.getObject(object: object)
                        case .shopping_lists:
                            self.shoppingListDescriptions = try await grocyApi.getObject(object: object)
                        case .shopping_locations:
                            self.mdStores = try await grocyApi.getObject(object: object)
                        case .stock_log:
                            self.stockJournal = try await grocyApi.getObject(object: object)
                        default:
                            self.postLog("Object not implemented", type: .error)
                        }
                    }
                    self.timeStampsObjects[object] = timeStamp
                    self.loadingObjectEntities.remove(object)
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
                        case .system_config:
                            self.systemConfig = try await grocyApi.getSystemConfig()
                        case .system_db_changed_time:
                            self.systemDBChangedTime = try await grocyApi.getSystemDBChangedTime()
                        case .system_info:
                            self.systemInfo = try await grocyApi.getSystemInfo()
                        case .user_settings:
                            self.userSettings = try await grocyApi.getUserSettings()
                        case .users:
                            self.users = try await grocyApi.getUsers()
                        case .volatileStock:
                            self.volatileStock = try await grocyApi.getVolatileStock(expiringDays: self.userSettings?.stockDueSoonDays ?? 5)
                        default:
                            self.postLog("Additional object not implemented", type: .error)
                        }
                    }
                    self.timeStampsAdditionalObjects[additionalObject] = timeStamp
                    self.loadingAdditionalEntities.remove(additionalObject)
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
    
    //    func updateShoppingListFromReminders(reminders: [Reminder]) {
    //        for reminder in reminders {
    //            var nameComponents = reminder.title.components(separatedBy: " ")
    //            let amount = Double(nameComponents.removeFirst())
    //            let name = nameComponents.joined(separator: " ")
    //
    //            if let product = self.mdProducts.first(where: { $0.name == name }), let entry = self.shoppingList.first(where: { $0.productID == product.id } ) {
    //                let shoppingListEntryNew = ShoppingListItem(
    //                    id: entry.id,
    //                    productID: entry.productID,
    //                    note: reminder.notes,
    //                    amount: amount ?? entry.amount,
    //                    shoppingListID: entry.shoppingListID,
    //                    done: reminder.isComplete ? 1 : 0,
    //                    quID: entry.quID,
    //                    rowCreatedTimestamp: entry.rowCreatedTimestamp
    //                )
    //                if shoppingListEntryNew.note != entry.note, shoppingListEntryNew.amount != entry.amount, shoppingListEntryNew.done != entry.done {
    //                    self.putMDObjectWithID(
    //                        object: .shopping_list,
    //                        id: entry.id,
    //                        content: shoppingListEntryNew, completion: { result in
    //                            switch result {
    //                            case let .success(message):
    //                                self.postLog("Shopping entry edited successfully. \(message)", type: .info)
    //                            case let .failure(error):
    //                                self.postLog("Shopping entry edit failed. \(error)", type: .error)
    //                            }
    //                        })
    //                }
    //            } else {
    //                self.postLog("Found no matching product for the shopping list entry \(name).", type: .info)
    //            }
    //        }
    //    }
    
    //MARK: - SYSTEM
    func getSystemInfo() async throws -> SystemInfo {
        return try await grocyApi.getSystemInfo()
    }
    
    //    func getSystemDBChangedTime(completion: @escaping ((Result<SystemDBChangedTime, APIError>) -> ())) {
    //        grocyApi.getSystemDBChangedTime()
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Get systemdbchangedtime failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (dbchangedtime) in
    //                DispatchQueue.main.async {
    //                    completion(.success(dbchangedtime))
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    
    //    func getSystemConfig(completion: @escaping ((Result<SystemConfig, APIError>) -> ())) {
    //        grocyApi.getSystemConfig()
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Get systemconfig failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (syscfg) in
    //                DispatchQueue.main.async {
    //
    //                    completion(.success(syscfg))
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    
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
    
    //    func getUsers(completion: @escaping ((Result<GrocyUsers, APIError>) -> ())) {
    //        grocyApi.getUsers()
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Get users failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (usersOut) in
    //                DispatchQueue.main.async {
    //                    completion(.success(usersOut))
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    
    //    func postUser(user: GrocyUserPOST, completion: @escaping ((Result<SuccessfulCreationMessage, APIError>) -> ())) {
    //        let jsonUser = try! jsonEncoder.encode(user)
    //        grocyApi.postUser(user: jsonUser)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Post users failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (response: Int) in
    //                DispatchQueue.main.async {
    //                    completion(.success(SuccessfulCreationMessage(createdObjectID: user.id)))
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    //
    //    func putUser(id: Int, user: GrocyUserPOST, completion: @escaping ((Result<SuccessfulPutMessage, APIError>) -> ())) {
    //        let jsonUser = try! jsonEncoder.encode(user)
    //        grocyApi.putUserWithID(id: id, user: jsonUser)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Put User failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (response: Int) in
    //                DispatchQueue.main.async {
    //                    completion(.success(SuccessfulPutMessage(changedObjectID: id)))
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    //
    //    func deleteUser(id: Int, completion: @escaping ((Result<DeleteMessage, APIError>) -> ())) {
    //        grocyApi.deleteUserWithID(id: id)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Delete User failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (responseCode: Int) in
    //                DispatchQueue.main.async {
    //                    completion(.success(DeleteMessage(deletedObjectID: id)))
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    
    func getNewUserID() -> Int {
        let ints = self.users.map{ $0.id }
        var startvar = 0
        while ints.contains(startvar) { startvar += 1 }
        return startvar
    }
    
    // MARK: - Current user
    //    func getUser(completion: @escaping ((Result<GrocyUsers, APIError>) -> ())) {
    //        grocyApi.getUser()
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Get user failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (currentUserOut) in
    //                DispatchQueue.main.async {
    //                    completion(.success(currentUserOut))
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    
    //    func getUserSettings(completion: @escaping ((Result<GrocyUserSettings, APIError>) -> ())) {
    //        grocyApi.getUserSettings()
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Getting user settings failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (userSettingsOut) in
    //                DispatchQueue.main.async {
    //                    completion(.success(userSettingsOut))
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    
    //    func getUserSettingsEntry<T: Codable>(settingKey: String, completion: @escaping ((Result<T, APIError>) -> ())) {
    //        grocyApi.getUserSettingKey(settingKey: settingKey)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Getting user settings key failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (usersettingKeyOut) in
    //                DispatchQueue.main.async {
    //                    completion(.success(usersettingKeyOut))
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    //
    //    func putUserSettingsEntry<T: Codable>(settingKey: String, content: T, completion: @escaping ((Result<Int, Error>) -> ())) {
    //        let jsonContent = try! jsonEncoder.encode(content)
    //        grocyApi.putUserSettingKey(settingKey: settingKey, content: jsonContent)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Put user settings key failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }) { (returnCode: Int) in
    //                DispatchQueue.main.async {
    //                    completion(.success(returnCode))
    //                }
    //            }
    //            .store(in: &cancellables)
    //    }
    
    // MARK: - Stock management
    
    //    func getStock(completion: @escaping ((Result<Stock, APIError>) -> ())) {
    //        grocyApi.getStock()
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Get stock failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (stockOut) in
    //                DispatchQueue.main.async {
    //                    completion(.success(stockOut))
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    //
    //    func getVolatileStock(completion: @escaping ((Result<VolatileStock, APIError>) -> ())) {
    //        grocyApi.getVolatileStock(expiringDays: self.userSettings?.stockDueSoonDays ?? 5)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Get volatile stock failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (volatileStockOut) in
    //                DispatchQueue.main.async {
    //                    completion(.success(volatileStockOut))
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    //
    //    func getStockProductInfo<T: Codable>(mode: StockProductGet, productID: Int, query: String? = nil, completion: @escaping ((Result<T, Error>) -> ())) {
    //        grocyApi.getStockProductInfo(stockModeGet: mode, id: productID, query: query)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Get stock product info failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //
    //            }) { (getStockProductInfoReturn: T) in
    //                DispatchQueue.main.async {
    //                    completion(.success(getStockProductInfoReturn))
    //                }
    //            }
    //            .store(in: &cancellables)
    //    }
    //
    //    func requestStockInfo(stockModeGet: [StockProductGet]? = nil, productID: Int, ignoreCached: Bool = true) {
    //        if let stockModeGet = stockModeGet {
    //            for mode in stockModeGet {
    //                switch mode {
    //                case .details:
    //                    if stockProductDetails.isEmpty || ignoreCached {
    //                        getStockProductInfo(mode: mode, productID: productID, completion: { (result: Result<StockProductDetails, Error>) in
    //                            switch result {
    //                            case let .success(productDetailResult):
    //                                self.stockProductDetails[productID] = productDetailResult
    //                            case let .failure(error):
    //                                self.postLog("Data request failed for \(mode.rawValue). Message: \("\(error)")", type: .error)
    //                            }
    //                        })
    //                    }
    //                case .locations:
    //                    print("not implemented")
    //                case .entries:
    //                    if stockProductEntries[productID]?.isEmpty ?? true || ignoreCached {
    //                        getStockProductInfo(mode: mode, productID: productID, completion: { (result: Result<StockEntries, Error>) in
    //                            switch result {
    //                            case let .success(productEntriesResult):
    //                                self.stockProductEntries[productID] = productEntriesResult
    //                            case let .failure(error):
    //                                self.postLog("Data request failed for \(mode.rawValue). Message: \("\(error)")", type: .error)
    //                            }
    //                        })
    //                    }
    //                case .priceHistory:
    //                    print("not implemented")
    //                }
    //            }
    //        }
    //    }
    //
    //    func getStockProductLocations(productID: Int) {
    //        grocyApi.getStockProductInfo(stockModeGet: .locations, id: productID, query: nil)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Get stock product locations failed. \("\(error)")", type: .error)
    //                    break
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (stockLocationsOut: StockLocations) in
    //                DispatchQueue.main.async {
    //                    self.stockProductLocations[productID] = stockLocationsOut
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    //
    //    func getStockProductDetails(productID: Int) {
    //        grocyApi.getStockProductInfo(stockModeGet: .details, id: productID, query: nil)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Get stock product details failed. \("\(error)")", type: .error)
    //                    break
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (productDetailsOut: StockProductDetails) in
    //                DispatchQueue.main.async {
    //                    self.stockProductDetails[productID] = productDetailsOut
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    //
    //    func getStockProductEntries(productID: Int) {
    //        grocyApi.getStockProductInfo(stockModeGet: .entries, id: productID, query: "?include_sub_products=true")
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Get stock product entries failed. \("\(error)")", type: .error)
    //                    break
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (productEntriesOut: StockEntries) in
    //                DispatchQueue.main.async {
    //                    self.stockProductEntries[productID] = productEntriesOut
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    //
    //    func putStockProductEntry(id: Int, content: StockEntry, completion: @escaping ((Result<StockJournal, Error>) -> ())) {
    //        let jsonContent = try! jsonEncoder.encode(content)
    //        print(String(data: jsonContent, encoding: String.Encoding.utf8) ?? "")
    //        grocyApi.putStockEntry(entryID: id, content: jsonContent)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Put stock object failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }) { (stockJournalReturn: StockJournal) in
    //                DispatchQueue.main.async {
    //                    completion(.success(stockJournalReturn))
    //                }
    //            }
    //            .store(in: &cancellables)
    //    }
    //
    //    func postStockObject<T: Codable>(id: Int, stockModePost: StockProductPost, content: T, completion: @escaping ((Result<StockJournal, Error>) -> ())) {
    //        let jsonContent = try! jsonEncoder.encode(content)
    //        //        print(String(data: jsonContent, encoding: String.Encoding.utf8))
    //        grocyApi.postStock(id: id, content: jsonContent, stockModePost: stockModePost)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Post stock object failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //
    //            }) { (stockJournalReturn: StockJournal) in
    //                DispatchQueue.main.async {
    //                    self.lastStockActions.append(contentsOf: stockJournalReturn)
    //                    completion(.success(stockJournalReturn))
    //                }
    //            }
    //            .store(in: &cancellables)
    //    }
    //
    //    func undoBookingWithID(id: Int, completion: @escaping ((Result<SuccessfulActionMessage, Error>) -> ())) {
    //        grocyApi.undoBookingWithID(id: id)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Undo booking failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (responseCode: Int) in
    //                DispatchQueue.main.async {
    //                    completion(.success(SuccessfulActionMessage(responseCode: responseCode)))
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    //
    //    func getPictureURL(groupName: String, fileName: String) -> String? {
    //        grocyApi.getPictureURL(groupName: groupName, fileName: fileName)
    //    }
    //
    //    func uploadFile(fileURL: URL, groupName: String, fileName: String, completion: @escaping ((Result<Int, Error>) -> ())) {
    //        grocyApi.putFile(fileURL: fileURL, fileName: fileName, groupName: groupName, completion: completion)
    //    }
    //
    //    func uploadFileData(fileData: Data, groupName: String, fileName: String, completion: @escaping ((Result<Int, Error>) -> ())) {
    //        grocyApi.putFileData(fileData: fileData, fileName: fileName, groupName: groupName, completion: completion)
    //    }
    //
    //    func deleteFile(groupName: String, fileName: String, completion: @escaping ((Result<Int, Error>) -> ())) {
    //        grocyApi.deleteFile(fileName: fileName, groupName: groupName)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Delete file failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (responseCode: Int) in
    //                DispatchQueue.main.async {
    //                    completion(.success(responseCode))
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    
    // MARK: -Shopping Lists
    
    //    func addShoppingListItem(content: ShoppingListItemAdd, completion: @escaping ((Result<SuccessfulCreationMessage, Error>) -> ())) {
    //        let jsonContent = try! jsonEncoder.encode(content)
    //        grocyApi.shoppingListAddItem(content: jsonContent)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Add product to shopping list failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (creationMessage: SuccessfulCreationMessage) in
    //                completion(.success(creationMessage))
    //            })
    //            .store(in: &cancellables)
    //    }
    //
    //    func shoppingListAction(content: ShoppingListAction, actionType: ShoppingListActionType, completion: @escaping ((Result<SuccessfulActionMessage, Error>) -> ())) {
    //        let jsonContent = try! jsonEncoder.encode(content)
    //        grocyApi.shoppingListAction(content: jsonContent, actionType: actionType)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Shopping list action failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (responseCode: Int) in
    //                DispatchQueue.main.async {
    //                    completion(.success(SuccessfulActionMessage(responseCode: responseCode)))
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    //
    //    // MARK: -Master Data
    //
    //    // Generic POST and DELETE and PUT
    //
    //    func postMDObject<T: Codable>(object: ObjectEntities, content: T, completion: @escaping ((Result<SuccessfulCreationMessage, Error>) -> ())) {
    //        let jsonContent = try! jsonEncoder.encode(content)
    //        grocyApi.postObject(object: object, content: jsonContent)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Post MD Object failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (successfulMessage: SuccessfulCreationMessage) in
    //                DispatchQueue.main.async {
    //                    completion(.success(successfulMessage))
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    //
    //    func deleteMDObject(object: ObjectEntities, id: Int, completion: @escaping ((Result<DeleteMessage, Error>) -> ())) {
    //        grocyApi.deleteObjectWithID(object: object, id: id)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Delete MD Object failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (responseCode: Int) in
    //                DispatchQueue.main.async {
    //                    completion(.success(DeleteMessage(deletedObjectID: id)))
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
    //
    //    func putMDObjectWithID<T: Codable>(object: ObjectEntities, id: Int, content: T, completion: @escaping ((Result<SuccessfulCreationMessage, Error>) -> ())) {
    //        let jsonContent = try! jsonEncoder.encode(content)
    //        grocyApi.putObjectWithID(object: object, id: id, content: jsonContent)
    //            .sink(receiveCompletion: { result in
    //                switch result {
    //                case .failure(let error):
    //                    self.postLog("Put MD Object failed. \("\(error)")", type: .error)
    //                    completion(.failure(error))
    //                case .finished:
    //                    break
    //                }
    //            }, receiveValue: { (response: Int) in
    //                DispatchQueue.main.async {
    //                    completion(.success(SuccessfulCreationMessage(createdObjectID: id)))
    //                }
    //            })
    //            .store(in: &cancellables)
    //    }
}
