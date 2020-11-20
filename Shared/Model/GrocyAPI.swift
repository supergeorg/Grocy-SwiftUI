//
//  GrocyAPI.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import Foundation
import Combine

public enum APIError: Error {
    case internalError
    case serverError
    case decodingError
    case encodingError
    case invalidResponse
    case unsuccessful
    case errorString(String)
    case timeout
}

//public enum Mode {
//    case Generic, System, UserManagement, UserSettings, Stock, StockByBarcode, Recipes, Chores, Batteries, Tasks, Calendar, Files
//}

public enum ObjectEntities: String {
    case products, product_barcodes, chores, batteries, locations, quantity_units, quantity_unit_conversions, shopping_list, shopping_lists, shopping_locations, recipes, recipes_pos, recipes_nestings, tasks, task_categories, product_groups, equipment, userfields, userentities, userobjects, meal_plan, stock_log
}

public enum StockProductPost: String {
    case add, consume, transfer, inventory, open
}

public enum StockProductGet: String {
    case details, locations, entries, priceHistory
}

public enum ResponseCodes: Int {
    case GetSuccessful = 200
    case PostSuccessful = 204
    case Unsuccessful = 400
}

protocol GrocyAPIProvider {
    func setLoginData(baseURL: String, apiKey: String)
    // MARK: - System
    func getSystemInfo() -> AnyPublisher<SystemInfo, APIError>
    func getSystemDBChangedTime() -> AnyPublisher<SystemDBChangedTime, APIError>
    // MARK: - User
//    func getUsers() -> AnyPublisher<[UserDto], APIError>
//    func postUser(user: Data) -> AnyPublisher<User, APIError>
//    func deleteUser(id: String) -> AnyPublisher<UserDto, APIError>
    // MARK: - Stock
    func getStock() -> AnyPublisher<Stock, APIError>
    func getStockJournal() -> AnyPublisher<StockJournal, APIError>
    func getVolatileStock(expiringDays: Int) -> AnyPublisher<VolatileStock, APIError>
    func getStockProduct<T: Codable>(stockModeGet: StockProductGet, id: String, query: String?) -> AnyPublisher<T, APIError>
    func postStock<T: Codable>(id: String, content: Data, stockModePost: StockProductPost) -> AnyPublisher<T, APIError>
    // MARK: - Master Data
    func getObject<T: Codable>(object: ObjectEntities) -> AnyPublisher<T, APIError>
    func postObject<T: Codable>(object: ObjectEntities, content: Data) -> AnyPublisher<T, APIError>
    func getObjectWithID<T: Codable>(object: ObjectEntities, id: String) -> AnyPublisher<T, APIError>
    func putObjectWithID<T: Codable>(object: ObjectEntities, id: String, content: Data) -> AnyPublisher<T, APIError>
    func deleteObjectWithID<T: Codable>(object: ObjectEntities, id: String) -> AnyPublisher<T, APIError>
}

public class GrocyApi: GrocyAPIProvider {
    
    private var baseURL: String = ""
    private var apiKey: String = ""
    
//    init(baseURL: String, apiKey: String) {
//            self.baseURL = baseURL
//            self.apiKey = apiKey
//        }
    
    func setLoginData(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    private enum Method: String {
        case GET
        case POST
        case DELETE
        case PUT
    }
    
    private func call<T: Codable>(_ endPoint: Endpoint, method: Method, object: ObjectEntities? = nil, id: String? = nil, content: Data? = nil, query: String? = nil) -> AnyPublisher<T, APIError> {
        let urlRequest = request(for: endPoint, method: method, object: object, id: id, content: content, query: query)
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .mapError{ _ in APIError.serverError }
            .tryMap() { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { _ in APIError.decodingError }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func request(for endpoint: Endpoint, method: Method, object: ObjectEntities? = nil, id: String? = nil, content: Data? = nil, query: String? = nil) -> URLRequest {
        var path = "\(baseURL)/api\(endpoint.rawValue)"
        if path.contains("{entity}") { path = path.replacingOccurrences(of: "{entity}", with: object!.rawValue) }
        if path.contains("{objectId}") { path = path.replacingOccurrences(of: "{objectId}", with: id!) }
        if path.contains("{userId}") { path = path.replacingOccurrences(of: "{userId}", with: id!) }
        if path.contains("{entryId}") { path = path.replacingOccurrences(of: "{entryId}", with: id!) }
        if path.contains("{productId}") { path = path.replacingOccurrences(of: "{productId}", with: id!) }
        if path.contains("{bookingId}") { path = path.replacingOccurrences(of: "{bookingId}", with: id!) }
        if path.contains("{transactionId}") { path = path.replacingOccurrences(of: "{transactionId}", with: id!) }
        if query != nil { path += query! }
        
        guard let url = URL(string: path)
        else { preconditionFailure("Bad URL") }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = ["Content-Type": "application/json",
                                       "Accept": "application/json",
                                       "GROCY-API-KEY": apiKey]
        if content != nil {
            request.httpBody = content
        }
        
        request.timeoutInterval = 3
        return request
    }
}

extension GrocyApi {
    private enum Endpoint: String {
        //        Generic
        case objectsEntity = "/objects/{entity}"
        case objectsEntityWithID = "/objects/{entity}/{objectId}"
        case objectsEntitySearch = "/objects/{entity}/search/{searchString}"
        case userfieldsEntity = "/userfields/{entity}/{objectId}"
        //        System
        case systemInfo = "/system/info"
        case systemDBChangedTime = "/system/db-changed-time"
        case systemConfig = "/system/config"
        case systemLogMissingLocalization = "/system/log-missing/localization"
        //        User management
        case users = "/users"
        case usersWithID = "/users/{userId}"
        //        User settings
        case userSettings = "/user/settings"
        case userSettingsWithKey = "/user/settings/{settingKey}"
        //        Stock
        case stock = "/stock"
        case stockEntry = "/stock/entry/{entryId}"
        case stockVolatile = "/stock/volatile"
        case stockProductWithId = "/stock/products/{productId}"
        case stockProductWithIdLocations = "/stock/products/{productId}/locations"
        case stockProductWithIdEntries = "/stock/products/{productId}/entries"
        case stockProductWithIdPriceHistory = "/stock/products/{productId}/price-history"
        case stockProductAdd = "/stock/products/{productId}/add"
        case stockProductConsume = "/stock/products/{productId}/consume"
        case stockProductTransfer = "/stock/products/{productId}/transfer"
        case stockProductInventory = "/stock/products/{productId}/inventory"
        case stockProductOpen = "/stock/products/{productId}/open"
        //        TODO
        //        Stock by-barcode
        //        Recipes
        //        Chores
        //        Batteries
        //        Tasks
        //        Calendar
        //        Files
    }
}

extension GrocyApi {
    // MARK: - System
    
    func getSystemInfo() -> AnyPublisher<SystemInfo, APIError> {
        return call(.systemInfo, method: .GET)
    }
    
    func getSystemDBChangedTime() -> AnyPublisher<SystemDBChangedTime, APIError> {
        return call(.systemDBChangedTime, method: .GET)
    }
    
    // MARK: - User
    
//    func getUsers() -> AnyPublisher<[UserDto], APIError> {
//        return call(.users, method: .GET)
//    }
//    
//    func postUser(user: Data) -> AnyPublisher<User, APIError> {
//        return call(.users, method: .POST, content: user)
//    }
//    
//    func deleteUser(id: String) -> AnyPublisher<UserDto, APIError> {
//        return call(.users, method: .DELETE, id: id)
//    }
//    
    // MARK: - Stock
    
    func getStock() -> AnyPublisher<[StockElement], APIError> {
        return call(.stock, method: .GET)
    }
    
    func getStockJournal() -> AnyPublisher<StockJournal, APIError> {
        return call(.objectsEntity, method: .GET, object: .stock_log)
    }
    
    func getVolatileStock(expiringDays: Int) -> AnyPublisher<VolatileStock, APIError> {
        return call(.stockVolatile, method: .GET, query: "?expiring_days=\(expiringDays)")
    }
    
    func getStockProduct<T: Codable>(stockModeGet: StockProductGet, id: String, query: String? = nil) -> AnyPublisher<T, APIError> {
        switch stockModeGet {
        case .details:
            return call(.stockProductWithId, method: .GET, id: id)
        case .entries:
            return call(.stockProductWithIdEntries, method: .GET, id: id, query: query)
        case .locations:
            return call(.stockProductWithIdLocations, method: .GET, id: id)
        case .priceHistory:
            return call(.stockProductWithIdPriceHistory, method: .GET, id: id)
        }
    }
    
    func postStock<T: Codable>(id: String, content: Data, stockModePost: StockProductPost) -> AnyPublisher<T, APIError> {
        switch stockModePost {
        case .add:
            return call(.stockProductAdd, method: .POST, id: id, content: content)
        case .consume:
            return call(.stockProductConsume, method: .POST, id: id, content: content)
        case .inventory:
            return call(.stockProductInventory, method: .POST, id: id, content: content)
        case .open:
            return call(.stockProductOpen, method: .POST, id: id, content: content)
        case .transfer:
            return call(.stockProductTransfer, method: .POST, id: id, content: content)
        }
    }
    
    // MARK: - Master Data
    
    func getObject<T: Codable>(object: ObjectEntities) -> AnyPublisher<T, APIError> {
        return call(.objectsEntity, method: .GET, object: object)
    }
    
    func postObject<T: Codable>(object: ObjectEntities, content: Data) -> AnyPublisher<T, APIError> {
        return call(.objectsEntity, method: .POST, object: object, content: content)
    }
    
    func getObjectWithID<T: Codable>(object: ObjectEntities, id: String) -> AnyPublisher<T, APIError> {
        return call(.objectsEntityWithID, method: .GET, object: object, id: id)
    }
    
    func putObjectWithID<T: Codable>(object: ObjectEntities, id: String, content: Data) -> AnyPublisher<T, APIError> {
        return call(.objectsEntityWithID, method: .PUT, object: object, id: id, content: content)
    }
    
    func deleteObjectWithID<T: Codable>(object: ObjectEntities, id: String) -> AnyPublisher<T, APIError> {
        return call(.objectsEntityWithID, method: .DELETE, object: object, id: id)
    }
}
