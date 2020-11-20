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
    
//    @Published var users: [UserDto] = []
    @Published var stock: Stock = []
    @Published var stockJournal: StockJournal = []
//    @Published var volatileStock: VolatileStock?
//    @Published var shoppingListDescriptions: ShoppingListDescriptions = []
//    @Published var shoppingList: ShoppingList = []
//
    @Published var mdProducts: MDProducts = []
    @Published var mdLocations: MDLocations = []
    @Published var mdShoppingLocations: MDShoppingLocations = []
    @Published var mdQuantityUnits: MDQuantityUnits = []
    @Published var mdProductGroups: MDProductGroups = []

    @Published var stockProductEntries: [String: StockEntries] = [:]

    @Published var lastErrors: [ErrorMessage] = []
    
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
        default:
            print("findnextid not impl")
        }
        var startvar = 0
        while ints.contains(startvar) { startvar += 1 }
        return startvar
    }
    
    //MARK: - GET DATA
    
    func getSystemInfo() {
        let cancellable = grocyApi.getSystemInfo()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    self.lastLoadingFailed = true
                    print("Handle error: sysinfo\(error)")
                case .finished:
                    self.lastLoadingFailed = false
                    break
                }
                
            }) { (systemInfo) in
                DispatchQueue.main.async {
                    self.systemInfo = systemInfo
                }
            }
        cancellables.insert(cancellable)
    }
    
    func getSystemDBChangedTime() {
        let cancellable = grocyApi.getSystemDBChangedTime()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    print("Handle error: getsysbdch\(error)")
                case .finished:
                    break
                }
                
            }) { (systemDBChangedTime) in
                DispatchQueue.main.async {
                    self.systemDBChangedTime = systemDBChangedTime
                }
            }
        cancellables.insert(cancellable)
    }
    
//    // MARK: - USER MANAGEMENT
//
//    func getUsers() {
//        let cancellable = grocyApi.getUsers()
//            .sink(receiveCompletion: { result in
//                switch result {
//                case .failure(let error):
//                    print("Handle error: getuser\(error)")
//                case .finished:
//                    break
//                }
//
//            }) { (users) in
//                DispatchQueue.main.async {
//                    self.users = users
//                }
//            }
//        cancellables.insert(cancellable)
//    }
//
//    func postUser(user: User) {
//        do{
//            let jsonUser = try JSONEncoder().encode(user)
//            print(String(data: jsonUser, encoding: .utf8)!)
//            let cancellable = grocyApi.postUser(user: jsonUser)
//                .sink(receiveCompletion: { result in
//                    print(".sink() received the completion", String(describing: result))
//                    switch result {
//                    case .failure(let error):
//                        print("Handle error: postuser\(error)")
//                    case .finished:
//                        break
//                    }
//
//                }) { (exit) in
//                    DispatchQueue.main.async {
//                        print(exit)
//                        self.getUsers()
//                    }
//                }
//            cancellables.insert(cancellable)
//        } catch {
//            print("fehler")
//        }
//    }
//
//    func deleteUser(id: String) {
//        let cancellable = grocyApi.deleteUser(id: id)
//            .sink(receiveCompletion: { result in
//                print(".sink() received the completion", String(describing: result))
//                switch result {
//                case .failure(let error):
//                    print("Handle error: deluser\(error)")
//                case .finished:
//                    break
//                }
//
//            }) { (exit) in
//                DispatchQueue.main.async {
//                    print(exit)
//                    self.getUsers()
//                }
//            }
//        cancellables.insert(cancellable)
//    }
//
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
//    func getVolatileStock(expiringDays: Int) {
//        grocyApi.getVolatileStock(expiringDays: expiringDays)
//            .replaceError(with: VolatileStock(expiringProducts: [], expiredProducts: [], missingProducts: []))
//            .assign(to: \.volatileStock, on: self)
//            .store(in: &cancellables)
//    }
    func getProductDetails() {}
    func getProductLocations() {}
    func getProductEntries(productID: String) {
        grocyApi.getStockProduct(stockModeGet: .entries, id: productID, query: "?include_sub_products=true")
            .replaceError(with: [])
            .assign(to: \.stockProductEntries[productID], on: self)
            .store(in: &cancellables)
    }
    func getProductPriceHistory() {}

    func postStockObject<T: Codable>(id: String, stockModePost: StockProductPost, content: T) {
        let jsonContent = try! jsonEncoder.encode(content)
        print(String(data: jsonContent, encoding: .utf8)!)
        let cancellable = grocyApi.postStock(id: id, content: jsonContent, stockModePost: stockModePost)
            .replaceError(with: [])
            .assign(to: \.lastErrors, on: self)
        cancellables.insert(cancellable)
    }
//
//    // MARK: -Shopping Lists
//    func getShoppingListDescriptions() {
//        grocyApi.getObject(object: .shopping_lists)
//            .replaceError(with: [])
//            .assign(to: \.shoppingListDescriptions, on: self)
//            .store(in: &cancellables)
//    }
//
//    func getShoppingLists() {
//        grocyApi.getObject(object: .shopping_list)
//            .replaceError(with: [])
//            .assign(to: \.shoppingList, on: self)
//            .store(in: &cancellables)
//    }
//
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
