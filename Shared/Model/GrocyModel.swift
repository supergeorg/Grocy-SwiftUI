//
//  GrocyModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import Foundation
import Combine
import SwiftUI

enum getDataMode {
    case systemInfo, systemDBChangedTime//, users, stock, mdProducts, mdLocations, mdShoppingLocations, mdQuantityUnits, mdProductGroups
}

class GrocyViewModel: ObservableObject {
    var grocyApi: GrocyAPIProvider
    
    //    @AppStorage("grocyServerURL") var grocyServerURL: String = "https://demo-prerelease.grocy.info"
    @AppStorage("grocyServerURL") var grocyServerURL: String = "https://test-7acbku5yigb6xne7xp2fo9.demo-prerelease.grocy.info"
    @AppStorage("grocyAPIKey") var grocyAPIKey: String = ""
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = true
    @AppStorage("isDemoModus") var isDemoModus: Bool = true
    
    static let shared = GrocyViewModel()
    
    @Published var lastLoadingFailed: Bool = false
    
    @Published var systemInfo: SystemInfo?
    @Published var systemDBChangedTime: SystemDBChangedTime?
    @Published var systemConfig: SystemConfig?
    
    @Published var users: GrocyUsers = []
    @Published var stock: Stock = []
    @Published var stockJournal: StockJournal = []
    @Published var shoppingListDescriptions: ShoppingListDescriptions = []
    @Published var shoppingList: ShoppingList = []
    
    @Published var mdProducts: MDProducts = []
    @Published var mdLocations: MDLocations = []
    @Published var mdShoppingLocations: MDShoppingLocations = []
    @Published var mdQuantityUnits: MDQuantityUnits = []
    @Published var mdProductGroups: MDProductGroups = []
    
    @Published var stockProductDetails: [String: StockProductDetails] = [:]
    @Published var stockProductLocations: [String: StockLocations] = [:]
    @Published var stockProductEntries: [String: StockEntries] = [:]
    @Published var stockProductPriceHistories: [String: ProductPriceHistories] = [:]
    
    @Published var lastErrors: [ErrorMessage] = []
    @Published var lastError: ErrorMessage = ErrorMessage(errorMessage: "")
    
    var cancellables = Set<AnyCancellable>()
    
    let jsonEncoder = JSONEncoder()
    
    init() {
        self.grocyApi = GrocyApi()
        if !isDemoModus {
            grocyApi.setLoginData(baseURL: grocyServerURL, apiKey: grocyAPIKey)
        } else {
            //            grocyApi.setLoginData(baseURL: "https://demo-prerelease.grocy.info", apiKey: "")
            grocyApi.setLoginData(baseURL: "https://test-7acbku5yigb6xne7xp2fo9.demo-prerelease.grocy.info", apiKey: "")
        }
        jsonEncoder.outputFormatting = .prettyPrinted
        //        self.lastLoadingFailed = true
    }
    
    func setDemoModus() {
        //        grocyApi.setLoginData(baseURL: "https://demo-prerelease.grocy.info", apiKey: "")
        grocyApi.setLoginData(baseURL: "https://test-7acbku5yigb6xne7xp2fo9.demo-prerelease.grocy.info", apiKey: "")
        isDemoModus = true
        isLoggedIn = true
    }
    
    func setLoginModus() {
        grocyApi.setLoginData(baseURL: grocyServerURL, apiKey: grocyAPIKey)
        isDemoModus = false
        isLoggedIn = true
    }
    
    func checkLoginInfo(baseURL: String, apiKey: String) {
        grocyApi.setLoginData(baseURL: baseURL, apiKey: apiKey)
        let cancellable = grocyApi.getSystemInfo()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    print("Handle error: sysinfo\(error)")
                case .finished:
                    break
                }
                
            }) { (systemInfo) in
                DispatchQueue.main.async {
                    if !systemInfo.grocyVersion.version.isEmpty {
                        print("login success")
                        self.systemInfo = systemInfo
                        self.isLoggedIn = true
                        self.setLoginModus()
                    } else {
                        print("login fail")
                        self.isLoggedIn = false
                    }
                }
            }
        cancellables.insert(cancellable)
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
        default:
            print("findnextid not impl")
        }
        var startvar = 0
        while ints.contains(startvar) { startvar += 1 }
        return startvar
    }
    
    //MARK: - SYSTEM
    
    func getSystemInfo() {
        let cancellable = grocyApi.getSystemInfo()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    print("Handle error: sysinfo\(error)")
                case .finished:
                    break
                }
                
            }) { (systemInfoOut) in
                DispatchQueue.main.async {
                    self.systemInfo = systemInfoOut
                }
            }
        cancellables.insert(cancellable)
    }
    
    func getSystemDBChangedTime() {
        let cancellable = grocyApi.getSystemDBChangedTime()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    print("Handle error: sysct\(error)")
                case .finished:
                    break
                }
                
            }) { (systemDBChangedTimeOut) in
                DispatchQueue.main.async {
                    self.systemDBChangedTime = systemDBChangedTimeOut
                }
            }
        cancellables.insert(cancellable)
    }
    
    func getSystemConfig() {
        let cancellable = grocyApi.getSystemConfig()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    print("Handle error: sysconfig\(error)")
                case .finished:
                    break
                }
                
            }) { (systemConfigOut) in
                DispatchQueue.main.async {
                    self.systemConfig = systemConfigOut
                }
            }
        cancellables.insert(cancellable)
    }
    
    // MARK: - USER MANAGEMENT
    
    func getUsers() {
        grocyApi.getUsers()
            .replaceError(with: [])
            .assign(to: \.users, on: self)
            .store(in: &cancellables)
    }
    
    func postUser(user: GrocyUserPOST) {
        let jsonUser = try! JSONEncoder().encode(user)
        //                print(String(data: jsonUser, encoding: .utf8)!)
        grocyApi.postUser(user: jsonUser)
            .replaceError(with: ErrorMessage(errorMessage: "delete user error"))
            .assign(to: \.lastError, on: self)
            .store(in: &cancellables)
    }
    
    func deleteUser(id: String) {
        grocyApi.deleteUserWithID(id: id)
            .replaceError(with: ErrorMessage(errorMessage: "delete user error"))
            .assign(to: \.lastError, on: self)
            .store(in: &cancellables)
    }
    
    func getNewUserID() -> Int {
        let ints = self.users.map{ Int($0.id) ?? 0 }
        var startvar = 0
        while ints.contains(startvar) { startvar += 1 }
        return startvar
    }
    
    // MARK: - Stock management
    
    func getStock() {
        let cancellable = grocyApi.getStock()
            .replaceError(with: [])
            .assign(to: \.stock, on: self)
        cancellables.insert(cancellable)
    }
    
    func getStockJournal() {
        let cancellable = grocyApi.getStockJournal()
            .replaceError(with: [])
            .assign(to: \.stockJournal, on: self)
        cancellables.insert(cancellable)
    }
    
    func getStockEntry() {}
    
    //    func getStockProductDetails(productID: String) {
    //        grocyApi.getStockProductDetails(stockModeGet: .details, id: productID, query: "?include_sub_products=true")
    //            .replaceError(with: [])
    //            .assign(to: \.stockProductDetails[productID], on: self)
    //            .store(in: &cancellables)
    //    }
    func getStockProductLocations(productID: String) {}
    func getStockProductEntries(productID: String) {
        grocyApi.getStockProductDetails(stockModeGet: .entries, id: productID, query: "?include_sub_products=true")
            .replaceError(with: [])
            .assign(to: \.stockProductEntries[productID], on: self)
            .store(in: &cancellables)
    }
    func getStockProductPriceHistory(productID: String) {}
    
    func postStockObject<T: Codable>(id: String, stockModePost: StockProductPost, content: T) {
        let jsonContent = try! jsonEncoder.encode(content)
        //        print(String(data: jsonContent, encoding: .utf8)!)
        grocyApi.postStock(id: id, content: jsonContent, stockModePost: stockModePost)
            .replaceError(with: [])
            .assign(to: \.lastErrors, on: self)
            .store(in: &cancellables)
    }
    
    func undoBookingWithID(id: String) {
        grocyApi.undoBookingWithID(id: id)
            .replaceError(with: [])
            .assign(to: \.lastErrors, on: self)
            .store(in: &cancellables)
    }
    
        // MARK: -Shopping Lists
        func getShoppingListDescriptions() {
            grocyApi.getObject(object: .shopping_lists)
                .replaceError(with: [])
                .assign(to: \.shoppingListDescriptions, on: self)
                .store(in: &cancellables)
        }
    
        func getShoppingList() {
            grocyApi.getObject(object: .shopping_list)
                .replaceError(with: [])
                .assign(to: \.shoppingList, on: self)
                .store(in: &cancellables)
        }
    
    // MARK: -Master Data
    
    func getMDProducts() {
        let cancellable = grocyApi.getObject(object: .products)
            .replaceError(with: [])
            .assign(to: \.mdProducts, on: self)
        cancellables.insert(cancellable)
    }
    
    func getMDLocations() {
        let cancellable = grocyApi.getObject(object: .locations)
            .replaceError(with: [])
            .assign(to: \.mdLocations, on: self)
        cancellables.insert(cancellable)
    }
    
    func getMDShoppingLocations() {
        let cancellable = grocyApi.getObject(object: .shopping_locations)
            .replaceError(with: [])
            .assign(to: \.mdShoppingLocations, on: self)
        cancellables.insert(cancellable)
    }
    
    func getMDQuantityUnits() {
        let cancellable = grocyApi.getObject(object: .quantity_units)
            .replaceError(with: [])
            .assign(to: \.mdQuantityUnits, on: self)
        cancellables.insert(cancellable)
    }
    
    func getMDProductGroups() {
        let cancellable = grocyApi.getObject(object: .product_groups)
            .replaceError(with: [])
            .assign(to: \.mdProductGroups, on: self)
        cancellables.insert(cancellable)
    }
    
    // Generic POST and DELETE
    
    func postMDObject<T: Codable>(object: ObjectEntities, content: T) {
        let jsonContent = try! JSONEncoder().encode(content)
        print(String(data: jsonContent, encoding: .utf8)!)
        grocyApi.postObject(object: object, content: jsonContent)
            .replaceError(with: [])
            .assign(to: \.lastErrors, on: self)
            .store(in: &cancellables)
    }
    
    func deleteMDObject(object: ObjectEntities, id: String) {
        grocyApi.deleteObjectWithID(object: object, id: id)
            .replaceError(with: [])
            .assign(to: \.lastErrors, on: self)
            .store(in: &cancellables)
    }
    
    func putMDObjectWithID<T: Codable>(object: ObjectEntities, id: String, content: T) {
        let jsonContent = try! JSONEncoder().encode(content)
        grocyApi.putObjectWithID(object: object, id: id, content: jsonContent)
            .replaceError(with: [])
            .assign(to: \.lastErrors, on: self)
            .store(in: &cancellables)
    }
}
