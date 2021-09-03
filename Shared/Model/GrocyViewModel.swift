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
#if !TESTING
import SwiftyBeaver
#endif

class GrocyViewModel: ObservableObject {
    var grocyApi: GrocyAPI
    
    @AppStorage("grocyServerURL") var grocyServerURL: String = ""
    @AppStorage("grocyAPIKey") var grocyAPIKey: String = ""
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("isDemoModus") var isDemoModus: Bool = false
    @AppStorage("demoServerURL") var demoServerURL: String = GrocyAPP.DemoServers.noLanguage.rawValue
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    static let shared = GrocyViewModel()
    
    #if TESTING
    let grocyLog = Logger(subsystem: "Grocy-SwiftUI", category: "APIAccess")
    #else
    let grocyLog = SwiftyBeaver.self
    #endif
    
    @Published var systemInfo: SystemInfo?
    @Published var systemDBChangedTime: SystemDBChangedTime?
    @Published var systemConfig: SystemConfig?
    
    @Published var users: GrocyUsers = []
    @Published var currentUser: GrocyUsers = []
    @Published var stock: Stock = []
    @Published var stockJournal: StockJournal = []
    @Published var shoppingListDescriptions: ShoppingListDescriptions = []
    @Published var shoppingList: ShoppingList = []
    
    @Published var mdProducts: MDProducts = []
    @Published var mdProductBarcodes: MDProductBarcodes = []
    @Published var mdLocations: MDLocations = []
    @Published var mdShoppingLocations: MDShoppingLocations = []
    @Published var mdQuantityUnits: MDQuantityUnits = []
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
    
    var cancellables = Set<AnyCancellable>()
    
    @AppStorage("useHassIngress") var useHassIngress: Bool = false
    @AppStorage("hassToken") var hassToken: String = ""
    @AppStorage("hassAPIPath") var hassAPIPath: String = ""
    
    let jsonEncoder = JSONEncoder()
    
    init() {
        self.grocyApi = GrocyApi()
        if isLoggedIn {
            if !isDemoModus {
                if useHassIngress {
                    grocyApi.setHassData(hassURL: hassAPIPath, hassToken: hassToken)
                }
                grocyApi.setLoginData(baseURL: grocyServerURL, apiKey: grocyAPIKey)
            } else {
                grocyApi.setLoginData(baseURL: demoServerURL, apiKey: "")
            }
            grocyLog.info("Logged in on startup")
        } else {
            grocyLog.info("Not logged in")
        }
        jsonEncoder.outputFormatting = .prettyPrinted
        
        #if !TESTING
        let console = ConsoleDestination()  // log to Xcode Console
        let file = FileDestination()  // log to default swiftybeaver.log file
        grocyLog.addDestination(console)
        grocyLog.addDestination(file)
        #endif
    }
    
    func setDemoModus() {
        isDemoModus = true
        grocyApi.setLoginData(baseURL: demoServerURL, apiKey: "")
        isLoggedIn = true
        grocyLog.info("Switched to demo modus")
    }
    
    func setLoginModus() {
        if useHassIngress {
            grocyApi.setHassData(hassURL: hassAPIPath, hassToken: hassToken)
        }
        grocyApi.setLoginData(baseURL: grocyServerURL, apiKey: grocyAPIKey)
        isDemoModus = false
        isLoggedIn = true
        grocyLog.info("Switched to login modus")
    }
    
    func logout() {
        isLoggedIn = false
        grocyApi.clearHassData()
        self.deleteAllCachedData()
    }
    
    func checkServer(baseURL: String, apiKey: String?, isDemoModus: Bool, completion: @escaping ((Result<String, Error>) -> ())) {
        if useHassIngress && !isDemoModus {
            grocyApi.setHassData(hassURL: hassAPIPath, hassToken: hassToken)
        }
        grocyApi.setLoginData(baseURL: baseURL, apiKey: apiKey ?? "")
        grocyApi.getSystemInfo()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Error at checkLoginInfo: \("\(error)")")
                    completion(.failure(error))
                case .finished:
                    break
                }
            }, receiveValue: { (systemInfo: SystemInfo) in
                DispatchQueue.main.async {
                    if !systemInfo.grocyVersion.version.isEmpty {
                        self.grocyLog.info("Login info check successful. Logging in.")
                        self.systemInfo = systemInfo
                        completion(.success(systemInfo.grocyVersion.version))
                    } else {
                        self.grocyLog.error("Selected server doesn't respond.")
                        self.isLoggedIn = false
                        completion(.failure(APIError.invalidResponse))
                    }
                }
            })
            .store(in: &cancellables)
    }
    
    func findNextID(_ object: ObjectEntities) -> Int {
        var ints: [Int] = []
        switch object {
        case .products:
            ints = self.mdProducts.map{ $0.id }
        case .locations:
            ints = self.mdLocations.map{ $0.id }
        case .shopping_locations:
            ints = self.mdShoppingLocations.map{ $0.id }
        case .quantity_units:
            ints = self.mdQuantityUnits.map{ $0.id }
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
            self.grocyLog.error("Find next ID not implemented for \(object.rawValue).")
        }
        var startvar = 1
        while ints.contains(startvar) { startvar += 1 }
        return startvar
    }
    
    // Gets the data of a selected entity
    func getEntity<T: Codable>(entity: ObjectEntities, completion: @escaping ((Result<T, Error>) -> ())) {
        grocyApi.getObject(object: entity)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .finished:
                    break
                }
                
            }) { (getEntityReturn: T) in
                DispatchQueue.main.async {
                    completion(.success(getEntityReturn))
                }
            }
            .store(in: &cancellables)
    }
    
    func requestData(objects: [ObjectEntities]? = nil, additionalObjects: [AdditionalEntities]? = nil, ignoreCached: Bool = true) {
        if let objects = objects {
            for object in objects {
                switch object {
                case .batteries:
                    if mdBatteries.isEmpty || ignoreCached {
                        getEntity(entity: object, completion: { (result: Result<MDBatteries, Error>) in
                            switch result {
                            case let .success(entityResult):
                                self.mdBatteries = entityResult
                                self.failedToLoadObjects.remove(object)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for \(object.rawValue). Message: \("\(error)")")
                                self.failedToLoadObjects.insert(object)
                            }
                        })
                    }
                case .locations:
                    if mdLocations.isEmpty || ignoreCached {
                        getEntity(entity: object, completion: { (result: Result<MDLocations, Error>) in
                            switch result {
                            case let .success(entityResult):
                                self.mdLocations = entityResult
                                self.failedToLoadObjects.remove(object)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for \(object.rawValue). Message: \("\(error)")")
                                self.failedToLoadObjects.insert(object)
                            }
                        })
                    }
                case .product_barcodes:
                    if mdProductBarcodes.isEmpty || ignoreCached {
                        getEntity(entity: object, completion: { (result: Result<MDProductBarcodes, Error>) in
                            switch result {
                            case let .success(entityResult):
                                self.mdProductBarcodes = entityResult
                                self.failedToLoadObjects.remove(object)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for \(object.rawValue). Message: \("\(error)")")
                                self.failedToLoadObjects.insert(object)
                            }
                        })
                    }
                case .product_groups:
                    if mdProductGroups.isEmpty || ignoreCached {
                        getEntity(entity: object, completion: { (result: Result<MDProductGroups, Error>) in
                            switch result {
                            case let .success(entityResult):
                                self.mdProductGroups = entityResult
                                self.failedToLoadObjects.remove(object)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for \(object.rawValue). Message: \("\(error)")")
                                self.failedToLoadObjects.insert(object)
                            }
                        })
                    }
                case .products:
                    if mdProducts.isEmpty || ignoreCached {
                        getEntity(entity: object, completion: { (result: Result<MDProducts, Error>) in
                            switch result {
                            case let .success(entityResult):
                                self.mdProducts = entityResult
                                self.failedToLoadObjects.remove(object)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for \(object.rawValue). Message: \("\(error)")")
                                self.failedToLoadObjects.insert(object)
                            }
                        })
                    }
                case .quantity_units:
                    if mdQuantityUnits.isEmpty || ignoreCached {
                        getEntity(entity: object, completion: { (result: Result<MDQuantityUnits, Error>) in
                            switch result {
                            case let .success(entityResult):
                                self.mdQuantityUnits = entityResult
                                self.failedToLoadObjects.remove(object)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for \(object.rawValue). Message: \("\(error)")")
                                self.failedToLoadObjects.insert(object)
                            }
                        })
                    }
                case .shopping_list:
                    if shoppingList.isEmpty || ignoreCached {
                        getEntity(entity: object, completion: { (result: Result<ShoppingList, Error>) in
                            switch result {
                            case let .success(entityResult):
                                self.shoppingList = entityResult
                                self.failedToLoadObjects.remove(object)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for \(object.rawValue). Message: \("\(error)")")
                                self.failedToLoadObjects.insert(object)
                            }
                        })
                    }
                case .shopping_lists:
                    if shoppingListDescriptions.isEmpty || ignoreCached {
                        getEntity(entity: object, completion: { (result: Result<ShoppingListDescriptions, Error>) in
                            switch result {
                            case let .success(entityResult):
                                self.shoppingListDescriptions = entityResult
                                self.failedToLoadObjects.remove(object)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for \(object.rawValue). Message: \("\(error)")")
                                self.failedToLoadObjects.insert(object)
                            }
                        })
                    }
                case .shopping_locations:
                    if mdShoppingLocations.isEmpty || ignoreCached {
                        getEntity(entity: object, completion: { (result: Result<MDShoppingLocations, Error>) in
                            switch result {
                            case let .success(entityResult):
                                self.mdShoppingLocations = entityResult
                                self.failedToLoadObjects.remove(object)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for \(object.rawValue). Message: \("\(error)")")
                                self.failedToLoadObjects.insert(object)
                            }
                        })
                    }
                case .stock_log:
                    if stockJournal.isEmpty || ignoreCached {
                        getEntity(entity: object, completion: { (result: Result<StockJournal, Error>) in
                            switch result {
                            case let .success(entityResult):
                                self.stockJournal = entityResult
                                self.failedToLoadObjects.remove(object)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for \(object.rawValue). Message: \("\(error)")")
                                self.failedToLoadObjects.insert(object)
                            }
                        })
                    }
                case .task_categories:
                    if mdTaskCategories.isEmpty || ignoreCached {
                        getEntity(entity: object, completion: { (result: Result<MDTaskCategories, Error>) in
                            switch result {
                            case let .success(entityResult):
                                self.mdTaskCategories = entityResult
                                self.failedToLoadObjects.remove(object)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for \(object.rawValue). Message: \("\(error)")")
                                self.failedToLoadObjects.insert(object)
                            }
                        })
                    }
                case .userentities:
                    if mdUserEntities.isEmpty || ignoreCached {
                        getEntity(entity: object, completion: { (result: Result<MDUserEntities, Error>) in
                            switch result {
                            case let .success(entityResult):
                                self.mdUserEntities = entityResult
                                self.failedToLoadObjects.remove(object)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for \(object.rawValue). Message: \("\(error)")")
                                self.failedToLoadObjects.insert(object)
                            }
                        })
                    }
                case .userfields:
                    if mdUserFields.isEmpty || ignoreCached {
                        getEntity(entity: object, completion: { (result: Result<MDUserFields, Error>) in
                            switch result {
                            case let .success(entityResult):
                                self.mdUserFields = entityResult
                                self.failedToLoadObjects.remove(object)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for \(object.rawValue). Message: \("\(error)")")
                                self.failedToLoadObjects.insert(object)
                            }
                        })
                    }
                default:
                    self.grocyLog.error("Request data not implemented for \(object.rawValue).")
                }
            }
        }
        if let additionalObjects = additionalObjects {
            for additionalObject in additionalObjects {
                switch additionalObject {
                case .system_config:
                    if systemConfig == nil || ignoreCached {
                        getSystemConfig(completion: { result in
                            switch result {
                            case let .success(syscfg):
                                self.systemConfig = syscfg
                                self.failedToLoadAdditionalObjects.remove(additionalObject)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for SystemConfig. Message: \("\(error)")")
                                self.failedToLoadAdditionalObjects.insert(additionalObject)
                            }
                        })
                    }
                case .system_info:
                    if systemInfo == nil || ignoreCached  {
                        getSystemInfo(completion: { result in
                            switch result {
                            case let .success(sysinfo):
                                self.systemInfo = sysinfo
                                self.failedToLoadAdditionalObjects.remove(additionalObject)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for SystemInfo. Message: \("\(error)")")
                                self.failedToLoadAdditionalObjects.insert(additionalObject)
                            }
                        })
                    }
                case .system_db_changed_time:
                    if systemDBChangedTime == nil || ignoreCached  {
                        getSystemDBChangedTime(completion: { result in
                            switch result {
                            case let .success(sysdbchangedtime):
                                self.systemDBChangedTime = sysdbchangedtime
                                self.failedToLoadAdditionalObjects.remove(additionalObject)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for SystemDBChangedTime. Message: \("\(error)")")
                                self.failedToLoadAdditionalObjects.insert(additionalObject)
                            }
                        })
                    }
                case .stock:
                    if stock.isEmpty || ignoreCached  {
                        getStock(completion: { result in
                            switch result {
                            case let .success(stockRet):
                                self.stock = stockRet
                                self.failedToLoadAdditionalObjects.remove(additionalObject)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for Stock. Message: \("\(error)")")
                                self.failedToLoadAdditionalObjects.insert(additionalObject)
                            }
                        })
                    }
                case .users:
                    if users.isEmpty || ignoreCached  {
                        getUsers(completion: { result in
                            switch result {
                            case let .success(grocyusers):
                                self.users = grocyusers
                                self.failedToLoadAdditionalObjects.remove(additionalObject)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for Users. Message: \("\(error)")")
                                self.failedToLoadAdditionalObjects.insert(additionalObject)
                            }
                        })
                    }
                case .current_user:
                    if currentUser.isEmpty || ignoreCached  {
                        getUser(completion: { result in
                            switch result {
                            case let .success(currUsRet):
                                self.currentUser = currUsRet
                                self.failedToLoadAdditionalObjects.remove(additionalObject)
                            case let .failure(error):
                                self.grocyLog.error("Data request failed for current user. Message: \("\(error)")")
                                self.failedToLoadAdditionalObjects.insert(additionalObject)
                            }
                        })
                    }
                }
            }
        }
    }
    
    func retryFailedRequests() {
        self.requestData(objects: Array(failedToLoadObjects), additionalObjects: Array(failedToLoadAdditionalObjects))
    }
    
    func deleteAllCachedData() {
        systemInfo = nil
        systemDBChangedTime = nil
        systemConfig = nil
        
        users = []
        currentUser = []
        stock = []
        stockJournal = []
        shoppingListDescriptions = []
        shoppingList = []
        
        mdProducts = []
        mdProductBarcodes = []
        mdLocations = []
        mdShoppingLocations = []
        mdQuantityUnits = []
        mdProductGroups = []
        mdBatteries = []
        mdUserFields = []
        mdUserEntities = []
        
        stockProductDetails = [:]
        stockProductLocations = [:]
        stockProductEntries = [:]
        stockProductPriceHistories = [:]
        
        lastStockActions = []
        failedToLoadObjects.removeAll()
        failedToLoadAdditionalObjects.removeAll()
        self.grocyLog.info("Deleted all cached data from the viewmodel.")
    }
    
    func postLog(message: String, type: OSLogType) {
        switch type {
        case .error:
            self.grocyLog.error("\(message)")
        case .info:
            self.grocyLog.info("\(message)")
        case .debug:
            self.grocyLog.debug("\(message)")
        case .fault:
            self.grocyLog.error("\(message)")
        //            self.grocyLog.fault("\(message)")
        default:
            #if TESTING
            self.grocyLog.log("\(message)")
            #else
            self.grocyLog.verbose("\(message)")
            #endif
        }
    }
    
    func getLog() -> [String] {
        print("Log reading is not possible, at least not on iOS.")
        do {
            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            print(cachesDirectory.absoluteString)
            #if os(macOS)
            let logFolder = cachesDirectory.appendingPathComponent("Grocy-SwiftUI/")
            #elseif os(iOS)
            let logFolder = cachesDirectory
            #endif
            let filePath = logFolder.appendingPathComponent("swiftybeaver.log")
            let logText = try String(contentsOf: filePath, encoding: .utf8)
            let logLines : [String] = logText.components(separatedBy: NSCharacterSet.newlines)
            return logLines
        } catch {
            return ["Error reading log"]
        }
        //        let fileManager = FileManager.default
        //        let documentsURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        //        do {
        //            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
        //            for file in fileURLs {
        //                print(file.absoluteString)
        //            }
        //            return ""
        //            // process files
        //        } catch {
        //            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        //            return "Error"
        //        }
    }
    
    //MARK: - SYSTEM
    
    func getSystemInfo(completion: @escaping ((Result<SystemInfo, Error>) -> ())) {
        grocyApi.getSystemInfo()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get system info failed. \("\(error)")")
                    completion(.failure(error))
                case .finished:
                    break
                }
            }, receiveValue: { (sysinfo) in
                DispatchQueue.main.async {
                    completion(.success(sysinfo))
                }
            })
            .store(in: &cancellables)
    }
    
    func getSystemDBChangedTime(completion: @escaping ((Result<SystemDBChangedTime, Error>) -> ())) {
        grocyApi.getSystemDBChangedTime()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get systemdbchangedtime failed. \("\(error)")")
                    completion(.failure(error))
                case .finished:
                    break
                }
            }, receiveValue: { (dbchangedtime) in
                DispatchQueue.main.async {
                    completion(.success(dbchangedtime))
                }
            })
            .store(in: &cancellables)
    }
    
    func getSystemConfig(completion: @escaping ((Result<SystemConfig, Error>) -> ())) {
        grocyApi.getSystemConfig()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get systemconfig failed. \("\(error)")")
                    completion(.failure(error))
                case .finished:
                    break
                }
            }, receiveValue: { (syscfg) in
                DispatchQueue.main.async {
                    
                    completion(.success(syscfg))
                }
            })
            .store(in: &cancellables)
    }
    
    func getCurrencySymbol() -> String {
        let locale = NSLocale(localeIdentifier: localizationKey)
        return locale.displayName(forKey: NSLocale.Key.currencySymbol, value: self.systemConfig?.currency ?? "CURRENCY") ?? "CURRENCY"
    }
    
    // MARK: - USER MANAGEMENT
    
    func getUsers(completion: @escaping ((Result<GrocyUsers, Error>) -> ())) {
        grocyApi.getUsers()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get users failed. \("\(error)")")
                    completion(.failure(error))
                case .finished:
                    break
                }
            }, receiveValue: { (usersOut) in
                DispatchQueue.main.async {
                    completion(.success(usersOut))
                }
            })
            .store(in: &cancellables)
    }
    
    func postUser(user: GrocyUserPOST, completion: @escaping ((Result<SuccessfulCreationMessage, Error>) -> ())) {
        let jsonUser = try! JSONEncoder().encode(user)
        grocyApi.postUser(user: jsonUser)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Post user failed. \("\(error)")")
                    completion(.failure(error))
                case .finished:
                    break
                }
            }, receiveValue: { (response: Int) in
                DispatchQueue.main.async {
                    completion(.success(SuccessfulCreationMessage(createdObjectID: user.id)))
                }
            })
            .store(in: &cancellables)
    }
    
    func putUser(id: Int, user: GrocyUserPOST, completion: @escaping ((Result<SuccessfulPutMessage, Error>) -> ())) {
        let jsonUser = try! JSONEncoder().encode(user)
        grocyApi.putUserWithID(id: id, user: jsonUser)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Put User failed. \("\(error)")")
                    completion(.failure(error))
                case .finished:
                    break
                }
            }, receiveValue: { (response: Int) in
                DispatchQueue.main.async {
                    completion(.success(SuccessfulPutMessage(changedObjectID: id)))
                }
            })
            .store(in: &cancellables)
    }
    
    func deleteUser(id: Int, completion: @escaping ((Result<DeleteMessage, Error>) -> ())) {
        grocyApi.deleteUserWithID(id: id)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Delete User failed. \("\(error)")")
                    completion(.failure(error))
                case .finished:
                    break
                }
            }, receiveValue: { (responseCode: Int) in
                DispatchQueue.main.async {
                    completion(.success(DeleteMessage(deletedObjectID: id)))
                }
            })
            .store(in: &cancellables)
    }
    
    func getNewUserID() -> Int {
        let ints = self.users.map{ $0.id }
        var startvar = 0
        while ints.contains(startvar) { startvar += 1 }
        return startvar
    }
    
    // MARK: - Current user
    func getUser(completion: @escaping ((Result<GrocyUsers, Error>) -> ())) {
        grocyApi.getUser()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get current user failed. \("\(error)")")
                    completion(.failure(error))
                case .finished:
                    break
                }
            }, receiveValue: { (currentUserOut) in
                DispatchQueue.main.async {
                    completion(.success(currentUserOut))
                }
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Stock management
    
    func getStock(completion: @escaping ((Result<Stock, Error>) -> ())) {
        grocyApi.getStock()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get stock failed. \("\(error)")")
                    completion(.failure(error))
                case .finished:
                    break
                }
            }, receiveValue: { (stockOut) in
                DispatchQueue.main.async {
                    completion(.success(stockOut))
                }
            })
            .store(in: &cancellables)
    }
    
    func getStockProductLocations(productID: Int) {}
    
    func getStockProductEntries(productID: Int) {
        grocyApi.getStockProductDetails(stockModeGet: .entries, id: productID, query: "?include_sub_products=true")
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get stock product details failed. \("\(error)")")
                    break
                case .finished:
                    break
                }
            }, receiveValue: { (productEntriesOut: StockEntries) in
                DispatchQueue.main.async {
                    self.stockProductEntries[productID] = productEntriesOut
                }
            })
            .store(in: &cancellables)
    }
    
    func postStockObject<T: Codable>(id: Int, stockModePost: StockProductPost, content: T, completion: @escaping ((Result<StockJournal, Error>) -> ())) {
        let jsonContent = try! jsonEncoder.encode(content)
//        print(String(data: jsonContent, encoding: String.Encoding.utf8))
        grocyApi.postStock(id: id, content: jsonContent, stockModePost: stockModePost)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Post stock object failed. \("\(error)")")
                    completion(.failure(error))
                case .finished:
                    break
                }
                
            }) { (stockJournalReturn: StockJournal) in
                DispatchQueue.main.async {
                    self.lastStockActions.append(contentsOf: stockJournalReturn)
                    completion(.success(stockJournalReturn))
                }
            }
            .store(in: &cancellables)
    }
    
    func undoBookingWithID(id: Int, completion: @escaping ((Result<SuccessfulActionMessage, Error>) -> ())) {
        grocyApi.undoBookingWithID(id: id)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Undo booking failed. \("\(error)")")
                    completion(.failure(error))
                case .finished:
                    break
                }
            }, receiveValue: { (responseCode: Int) in
                DispatchQueue.main.async {
                    completion(.success(SuccessfulActionMessage(responseCode: responseCode)))
                }
            })
            .store(in: &cancellables)
    }
    
    func getPictureURL(groupName: String, fileName: String) -> String? {
        grocyApi.getPictureURL(groupName: groupName, fileName: fileName)
    }
    
    func uploadFile(fileURL: URL, groupName: String, fileName: String, completion: @escaping ((Result<Int, Error>) -> ())) {
        grocyApi.putFile(fileURL: fileURL, fileName: fileName, groupName: groupName, completion: completion)
    }
    
    func deleteFile(groupName: String, fileName: String, completion: @escaping ((Result<Int, Error>) -> ())) {
        grocyApi.deleteFile(fileName: fileName, groupName: groupName)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Delete file failed. \("\(error)")")
                    completion(.failure(error))
                case .finished:
                    break
                }
            }, receiveValue: { (responseCode: Int) in
                DispatchQueue.main.async {
                    completion(.success(responseCode))
                }
            })
            .store(in: &cancellables)
    }
    
    // MARK: -Shopping Lists
    
    func addShoppingListProduct(content: ShoppingListAddProduct, completion: @escaping ((Result<SuccessfulCreationMessage, Error>) -> ())) {
        let jsonContent = try! jsonEncoder.encode(content)
        grocyApi.shoppingListAddProduct(content: jsonContent)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Add product to shopping list failed. \("\(error)")")
                    completion(.failure(error))
                case .finished:
                    break
                }
            }, receiveValue: { (responseCode: Int) in
                completion(.success(SuccessfulCreationMessage(createdObjectID: content.productID)))
            })
            .store(in: &cancellables)
    }
    
    func shoppingListAction(content: ShoppingListAction, actionType: ShoppingListActionType, completion: @escaping ((Result<SuccessfulActionMessage, Error>) -> ())) {
        let jsonContent = try! jsonEncoder.encode(content)
        grocyApi.shoppingListAction(content: jsonContent, actionType: actionType)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Shopping list action failed. \("\(error)")")
                    completion(.failure(error))
                case .finished:
                    break
                }
            }, receiveValue: { (responseCode: Int) in
                DispatchQueue.main.async {
                    completion(.success(SuccessfulActionMessage(responseCode: responseCode)))
                }
            })
            .store(in: &cancellables)
    }
    
    // MARK: -Master Data
    
    // Generic POST and DELETE and PUT
    
    func postMDObject<T: Codable>(object: ObjectEntities, content: T, completion: @escaping ((Result<SuccessfulCreationMessage, Error>) -> ())) {
        let jsonContent = try! JSONEncoder().encode(content)
        grocyApi.postObject(object: object, content: jsonContent)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Post MD Object failed. \("\(error)")")
                    completion(.failure(error))
                case .finished:
                    break
                }
            }, receiveValue: { (successfulMessage: SuccessfulCreationMessage) in
                DispatchQueue.main.async {
                    completion(.success(successfulMessage))
                }
            })
            .store(in: &cancellables)
    }
    
    func deleteMDObject(object: ObjectEntities, id: Int, completion: @escaping ((Result<DeleteMessage, Error>) -> ())) {
        grocyApi.deleteObjectWithID(object: object, id: id)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Delete MD Object failed. \("\(error)")")
                    completion(.failure(error))
                case .finished:
                    break
                }
            }, receiveValue: { (responseCode: Int) in
                DispatchQueue.main.async {
                    completion(.success(DeleteMessage(deletedObjectID: id)))
                }
            })
            .store(in: &cancellables)
    }
    
    func putMDObjectWithID<T: Codable>(object: ObjectEntities, id: Int, content: T, completion: @escaping ((Result<SuccessfulCreationMessage, Error>) -> ())) {
        let jsonContent = try! JSONEncoder().encode(content)
        grocyApi.putObjectWithID(object: object, id: id, content: jsonContent)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Put MD Object failed. \("\(error)")")
                    completion(.failure(error))
                case .finished:
                    break
                }
            }, receiveValue: { (response: Int) in
                DispatchQueue.main.async {
                    completion(.success(SuccessfulCreationMessage(createdObjectID: id)))
                }
            })
            .store(in: &cancellables)
    }
}
