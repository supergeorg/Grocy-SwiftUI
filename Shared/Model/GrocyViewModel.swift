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
    
    static let shared = GrocyViewModel()
    
    let grocyLog = Logger()
    
    @Published var lastLoadingFailed: Bool = false
    
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
    @Published var mdUserFields: MDUserFields = []
    @Published var mdUserEntities: MDUserEntities = []
    
    @Published var stockProductDetails: [String: StockProductDetails] = [:]
    @Published var stockProductLocations: [String: StockLocations] = [:]
    @Published var stockProductEntries: [String: StockEntries] = [:]
    @Published var stockProductPriceHistories: [String: ProductPriceHistories] = [:]

    @Published var lastStockActions: StockJournal = []
    
    var cancellables = Set<AnyCancellable>()
    
    let jsonEncoder = JSONEncoder()
    
    init() {
        self.grocyApi = GrocyApi()
        if isLoggedIn {
            if !isDemoModus {
                grocyApi.setLoginData(baseURL: grocyServerURL, apiKey: grocyAPIKey)
            } else {
                grocyApi.setLoginData(baseURL: demoServerURL, apiKey: "")
            }
            grocyLog.info("Logged in on startup")
        } else {
            grocyLog.info("Not logged in")
        }
        jsonEncoder.outputFormatting = .prettyPrinted
    }
    
    func setDemoModus() {
        grocyApi.setLoginData(baseURL: demoServerURL, apiKey: "")
        isDemoModus = true
        isLoggedIn = true
        grocyLog.info("Switched to demo modus")
    }
    
    func setLoginModus() {
        grocyApi.setLoginData(baseURL: grocyServerURL, apiKey: grocyAPIKey)
        isDemoModus = false
        isLoggedIn = true
        grocyLog.info("Switched to login modus")
    }
    
    func checkServer(baseURL: String, apiKey: String?, completion: @escaping ((Result<String, Error>) -> ())) {
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
            ints = self.mdProducts.map{ Int($0.id) ?? 0 }
        case .locations:
            ints = self.mdLocations.map{ Int($0.id) ?? 0 }
        case .shopping_locations:
            ints = self.mdShoppingLocations.map{ Int($0.id) ?? 0 }
        case .quantity_units:
            ints = self.mdQuantityUnits.map{ Int($0.id) ?? 0 }
        case .product_groups:
            ints = self.mdProductGroups.map{ Int($0.id) ?? 0 }
        case .shopping_lists:
            ints = self.shoppingListDescriptions.map{ Int($0.id) ?? 0 }
        case .shopping_list:
            ints = self.shoppingList.map{ Int($0.id) ?? 0 }
        case .product_barcodes:
            ints = self.mdProductBarcodes.map{ Int($0.id) ?? 0 }
        case .userfields:
            ints = self.mdUserFields.map{ Int($0.id) ?? 0 }
        case .userentities:
            ints = self.mdUserEntities.map{ Int($0.id) ?? 0 }
        default:
            self.grocyLog.error("Find next ID not implemented for \(object.rawValue).")
        }
        var startvar = 1
        while ints.contains(startvar) { startvar += 1 }
        return startvar
    }
    
    func requestDataIfUnavailable(objects: [ObjectEntities]?, additionalObjects: [AdditionalEntities]? = nil) {
        if let objects = objects {
            for object in objects {
                switch object {
//                case .batteries:
//                    if mdBatteries.isEmpty { getMDBatteries() }
//                case .locations:
//                    if mdLocations.isEmpty { getMDLocations() }
//                case .product_barcodes:
//                    if mdProductBarcodes.isEmpty { getMDProductBarcodes() }
//                case .product_groups:
//                    if mdProductGroups.isEmpty { getMDProductGroups() }
//                case .products:
//                    if mdProducts.isEmpty { getMDProducts() }
//                case .quantity_units:
//                    if mdQuantityUnits.isEmpty { getMDQuantityUnits() }
//                case .shopping_list:
//                    if shoppingList.isEmpty { getShoppingList() }
//                case .shopping_lists:
//                    if shoppingListDescriptions.isEmpty { getShoppingListDescriptions() }
//                case .shopping_locations:
//                    if mdShoppingLocations.isEmpty { getMDShoppingLocations() }
//                case .stock_log:
//                    if stockJournal.isEmpty { getStockJournal() }
//                case .userentities:
//                    if mdUserEntities.isEmpty { getMDUserEntities() }
//                case .userfields:
//                    if mdUserFields.isEmpty { getMDUserFields() }
                case .batteries:
                    if mdBatteries.isEmpty { getEntity(entity: .batteries, type: MDBatteries()) }
                case .locations:
                    if mdLocations.isEmpty { getEntity(entity: .locations, type: MDLocations()) }
                case .product_barcodes:
                    if mdProductBarcodes.isEmpty { getEntity(entity: .product_barcodes, type: MDProductBarcodes()) }
                case .product_groups:
                    if mdProductGroups.isEmpty { getEntity(entity: .product_groups, type: MDProductGroups()) }
                case .products:
                    if mdProducts.isEmpty { getEntity(entity: .products, type: MDProducts()) }
                case .quantity_units:
                    if mdQuantityUnits.isEmpty { getEntity(entity: .quantity_units, type: MDQuantityUnits()) }
                case .shopping_list:
                    if shoppingList.isEmpty { getEntity(entity: .shopping_list, type: ShoppingList()) }
                case .shopping_lists:
                    if shoppingListDescriptions.isEmpty { getEntity(entity: .shopping_lists, type: ShoppingListDescriptions()) }
                case .shopping_locations:
                    if mdShoppingLocations.isEmpty { getEntity(entity: .shopping_locations, type: MDShoppingLocations()) }
                case .stock_log:
                    if stockJournal.isEmpty { getEntity(entity: .stock_log, type: StockJournal()) }
                case .userentities:
                    if mdUserEntities.isEmpty { getEntity(entity: .userentities, type: MDUserEntities()) }
                case .userfields:
                    if mdUserFields.isEmpty { getEntity(entity: .userfields, type: MDUserFields()) }
                default:
                    self.grocyLog.error("Request data not implemented for \(object.rawValue).")
                }
            }
        }
        if let additionalObjects = additionalObjects {
            for additionalObject in additionalObjects {
                switch additionalObject {
                case .system_config:
                    if systemConfig == nil { getSystemConfig() }
                case .system_info:
                    if systemInfo == nil { getSystemInfo() }
                case .system_db_changed_time:
                    if systemDBChangedTime == nil { getSystemDBChangedTime() }
                case .stock:
                    if stock.isEmpty { getStock() }
                case .users:
                    if users.isEmpty { getUsers() }
                }
            }
        }
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
            self.grocyLog.fault("\(message)")
        default:
            self.grocyLog.log("\(message)")
        }
    }
    
    func getLog() {
        print("Log reading is not possible, at least not on iOS.")
    }
    
    //MARK: - SYSTEM
    
    func getSystemInfo() {
        grocyApi.getSystemInfo()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get system info failed. \("\(error)")")
                case .finished:
                    break
                }
            }, receiveValue: { (sysinfo) in
                DispatchQueue.main.async { self.systemInfo = sysinfo }
            })
            .store(in: &cancellables)
    }
    
    func getSystemDBChangedTime() {
        grocyApi.getSystemDBChangedTime()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get systemdbchangedtime failed. \("\(error)")")
                case .finished:
                    break
                }
            }, receiveValue: { (dbchangedtime) in
                DispatchQueue.main.async { self.systemDBChangedTime = dbchangedtime }
            })
            .store(in: &cancellables)
    }
    
    func getSystemConfig() {
        grocyApi.getSystemConfig()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get systemconfig failed. \("\(error)")")
                case .finished:
                    break
                }
            }, receiveValue: { (syscfg) in
                DispatchQueue.main.async { self.systemConfig = syscfg }
            })
            .store(in: &cancellables)
    }
    
    func getCurrencySymbol() -> String {
        switch self.systemConfig?.currency {
        case "EUR":
            return "€"
        case "USD":
            return "$"
        default:
            self.grocyLog.info("Currency symbol for code \(self.systemConfig?.currency ?? "?") not implemented.")
            return "CURRENCY"
        }
    }
    
    // MARK: - USER MANAGEMENT
    
    func getUsers() {
        grocyApi.getUsers()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get users failed. \("\(error)")")
                case .finished:
                    break
                }
            }, receiveValue: { (usersOut) in
                DispatchQueue.main.async { self.users = usersOut }
            })
            .store(in: &cancellables)
    }
//    
//    func deleteUser(id: String) {
//        grocyApi.deleteUserWithID(id: id)
//            .replaceError(with: ErrorMessage(errorMessage: "delete user error"))
//            .assign(to: \.lastError, on: self)
//            .store(in: &cancellables)
//    }
    
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
                    completion(.success(SuccessfulCreationMessage(createdObjectID: "\(user.id)")))
                }
            })
            .store(in: &cancellables)
    }
    
    func putUser(id: String, user: GrocyUserPOST, completion: @escaping ((Result<SuccessfulPutMessage, Error>) -> ())) {
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
    
    func deleteUser(id: String, completion: @escaping ((Result<DeleteMessage, Error>) -> ())) {
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
        let ints = self.users.map{ Int($0.id) ?? 0 }
        var startvar = 0
        while ints.contains(startvar) { startvar += 1 }
        return startvar
    }
    
    // MARK: - Current user
    func getUser() {
        grocyApi.getUser()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get current user failed. \("\(error)")")
                case .finished:
                    break
                }
            }, receiveValue: { (currentUserOut) in
                DispatchQueue.main.async { self.currentUser = currentUserOut }
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Stock management
    
    func getStock() {
        grocyApi.getStock()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get stock failed. \("\(error)")")
                case .finished:
                    break
                }
            }, receiveValue: { (stockOut) in
                DispatchQueue.main.async { self.stock = stockOut }
            })
            .store(in: &cancellables)
    }
    
    func getStockJournal() {
        grocyApi.getStockJournal()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get stock journal failed. \("\(error)")")
                case .finished:
                    break
                }
            }, receiveValue: { (stockJOut) in
                DispatchQueue.main.async { self.stockJournal = stockJOut }
            })
            .store(in: &cancellables)
    }

    func getStockProductLocations(productID: String) {}
    func getStockProductEntries(productID: String) {
        grocyApi.getStockProductDetails(stockModeGet: .entries, id: productID, query: "?include_sub_products=true")
            .replaceError(with: [])
            .assign(to: \.stockProductEntries[productID], on: self)
            .store(in: &cancellables)
    }
    
    func postStockObject<T: Codable>(id: String, stockModePost: StockProductPost, content: T, completion: @escaping ((Result<StockJournal, Error>) -> ())) {
        let jsonContent = try! jsonEncoder.encode(content)
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
    
    func undoBookingWithID(id: String, completion: @escaping ((Result<SuccessfulActionMessage, Error>) -> ())) {
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
    
    // MARK: -Shopping Lists
    func getShoppingListDescriptions() {
        grocyApi.getObject(object: .shopping_lists)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get shopping lists failed. \("\(error)")")
                case .finished:
                    break
                }
            }, receiveValue: { (shLDesc) in
                DispatchQueue.main.async { self.shoppingListDescriptions = shLDesc }
            })
            .store(in: &cancellables)
    }
    
    func getShoppingList() {
        grocyApi.getObject(object: .shopping_list)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get shopping list failed. \("\(error)")")
                case .finished:
                    break
                }
            }, receiveValue: { (shoppingListOut) in
                DispatchQueue.main.async { self.shoppingList = shoppingListOut }
            })
            .store(in: &cancellables)
    }
    
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
                completion(.success(SuccessfulCreationMessage(createdObjectID: "\(content.productID)")))
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

    // TEST: I try to build a function which can get all types of data and assign it. The problem for now is the generic type, which has to be defined seperately.
    func getEntity<T: Codable>(entity: ObjectEntities, type: T) {
        grocyApi.getObject(object: entity)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get entity \(entity.rawValue) failed. \("\(error)")")
                case .finished:
                    break
                }
                
            }) { (getEntityReturn: T) in
                DispatchQueue.main.async {
                    switch entity {
                    case .batteries:
                        self.mdBatteries = getEntityReturn as! MDBatteries
                    case .locations:
                        self.mdLocations = getEntityReturn as! MDLocations
                    case .product_barcodes:
                        self.mdProductBarcodes = getEntityReturn as! MDProductBarcodes
                    case .product_groups:
                        self.mdProductGroups = getEntityReturn as! MDProductGroups
                    case .products:
                        self.mdProducts = getEntityReturn as! MDProducts
                    case .quantity_units:
                        self.mdQuantityUnits = getEntityReturn as! MDQuantityUnits
                    case .shopping_list:
                        self.shoppingList = getEntityReturn as! ShoppingList
                    case .shopping_lists:
                        self.shoppingListDescriptions = getEntityReturn as! ShoppingListDescriptions
                    case .shopping_locations:
                        self.mdShoppingLocations = getEntityReturn as! MDShoppingLocations
                    case .stock_log:
                        self.stockJournal = getEntityReturn as! StockJournal
                    case .userentities:
                        self.mdUserEntities = getEntityReturn as! MDUserEntities
                    default:
                        print(getEntityReturn as! MDProducts)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func getMDProducts() {
        grocyApi.getObject(object: .products)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get MDProducts failed. \("\(error)")")
                case .finished:
                    break
                }
            }, receiveValue: { (products) in
                DispatchQueue.main.async { self.mdProducts = products }
            })
            .store(in: &cancellables)
    }
    
    func getMDLocations() {
        grocyApi.getObject(object: .locations)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get MDLocations failed. \("\(error)")")
                case .finished:
                    break
                }
            }, receiveValue: { (locations) in
                DispatchQueue.main.async { self.mdLocations = locations }
            })
            .store(in: &cancellables)
    }
    
    func getMDShoppingLocations() {
        grocyApi.getObject(object: .shopping_locations)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get MDShoppingLocations failed. \("\(error)")")
                case .finished:
                    break
                }
            }, receiveValue: { (shoppingLocations) in
                DispatchQueue.main.async { self.mdShoppingLocations = shoppingLocations }
            })
            .store(in: &cancellables)
    }
    
    func getMDQuantityUnits() {
        grocyApi.getObject(object: .quantity_units)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get MDQuantityUnits failed. \("\(error)")")
                case .finished:
                    break
                }
            }, receiveValue: { (quantityUnits) in
                DispatchQueue.main.async { self.mdQuantityUnits = quantityUnits }
            })
            .store(in: &cancellables)
    }
    
    func getMDProductGroups() {
        grocyApi.getObject(object: .product_groups)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get MDProductGroups failed. \("\(error)")")
                case .finished:
                    break
                }
            }, receiveValue: { (productGroups) in
                DispatchQueue.main.async { self.mdProductGroups = productGroups }
            })
            .store(in: &cancellables)
    }
    
    func getMDProductBarcodes() {
        grocyApi.getObject(object: .product_barcodes)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get MDProductBarcodes failed. \("\(error)")")
                case .finished:
                    break
                }
            }, receiveValue: { (productBarcodes) in
                DispatchQueue.main.async { self.mdProductBarcodes = productBarcodes }
            })
            .store(in: &cancellables)
    }
    
    func getMDBatteries() {
        grocyApi.getObject(object: .batteries)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get MDBatteries failed. \("\(error)")")
                case .finished:
                    break
                }
            }, receiveValue: { (batteries) in
                DispatchQueue.main.async { self.mdBatteries = batteries }
            })
            .store(in: &cancellables)
    }
    
    func getMDUserFields() {
        grocyApi.getObject(object: .userfields)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get MDUserFields failed. \("\(error)")")
                case .finished:
                    break
                }
            }, receiveValue: { (userfields) in
                DispatchQueue.main.async { self.mdUserFields = userfields }
            })
            .store(in: &cancellables)
    }
    
    func getMDUserEntities() {
        grocyApi.getObject(object: .userentities)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.grocyLog.error("Get MDUserEntities failed. \("\(error)")")
                case .finished:
                    break
                }
            }, receiveValue: { (userentities) in
                DispatchQueue.main.async { self.mdUserEntities = userentities }
            })
            .store(in: &cancellables)
    }
    
    // Generic POST and DELETE
    
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
    
    func deleteMDObject(object: ObjectEntities, id: String, completion: @escaping ((Result<DeleteMessage, Error>) -> ())) {
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
    
    func putMDObjectWithID<T: Codable>(object: ObjectEntities, id: String, content: T, completion: @escaping ((Result<SuccessfulCreationMessage, Error>) -> ())) {
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
