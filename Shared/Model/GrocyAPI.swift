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

public enum ObjectEntities: String, CaseIterable {
    case none, products, product_barcodes, chores, batteries, locations, quantity_units, quantity_unit_conversions, shopping_list, shopping_lists, shopping_locations, recipes, recipes_pos, recipes_nestings, tasks, task_categories, product_groups, equipment, userfields, userentities, userobjects, meal_plan, stock_log
}

public enum StockProductPost: String {
    case add, consume, transfer, inventory, open
}

public enum StockProductGet: String {
    case details, locations, entries, priceHistory
}

public enum ShoppingListActionType: String {
    case clear, addExpired, addOverdue, addMissing
}

public enum ResponseCodes: Int {
    case GetSuccessful = 200
    case PostSuccessful = 204
    case Unsuccessful = 400
    case NotFound = 404
}

protocol GrocyAPIProvider {
    func setLoginData(baseURL: String, apiKey: String)
    // MARK: - System
    func getSystemInfo() -> AnyPublisher<SystemInfo, APIError>
    func getSystemDBChangedTime() -> AnyPublisher<SystemDBChangedTime, APIError>
    func getSystemConfig() -> AnyPublisher<SystemConfig, APIError>
    // MARK: - User management
    func getUsers() -> AnyPublisher<GrocyUsers, APIError>
    func postUser(user: Data) -> AnyPublisher<ErrorMessage, APIError>
    func putUserWithID(id: String, user: Data) -> AnyPublisher<ErrorMessage, APIError>
    func deleteUserWithID(id: String) -> AnyPublisher<ErrorMessage, APIError>
    // MARK: - Current user
    func getUser() -> AnyPublisher<GrocyUsers, APIError>
    // MARK: - Stock
    func getStock() -> AnyPublisher<Stock, APIError>
    func getStockJournal() -> AnyPublisher<StockJournal, APIError>
    func getVolatileStock(expiringDays: Int) -> AnyPublisher<VolatileStock, APIError>
    func getStockProductDetails<T: Codable>(stockModeGet: StockProductGet, id: String, query: String?) -> AnyPublisher<T, APIError>
//    func getStockProductLocations(stockModeGet: StockProductGet, id: String, query: String?) -> AnyPublisher<StockLocations, APIError>
//    func getStockProductEntries(stockModeGet: StockProductGet, id: String, query: String?) -> AnyPublisher<StockEntries, APIError>
//    func getStockProductPriceHistory(stockModeGet: StockProductGet, id: String, query: String?) -> AnyPublisher<ProductPriceHistory, APIError>
    func postStock<T: Codable>(id: String, content: Data, stockModePost: StockProductPost) -> AnyPublisher<T, APIError>
    func getBookingWithID(id: String) -> AnyPublisher<StockJournalEntry, APIError>
    func undoBookingWithID<T: Codable>(id: String) -> AnyPublisher<T, APIError>
    func getPictureURL(groupName: String, fileName: String) -> String?
    // MARK: - Shopping List
    func shoppingListAddProduct<T: Codable>(content: Data) -> AnyPublisher<T, APIError>
    func shoppingListAction<T: Codable>(content: Data, actionType: ShoppingListActionType) -> AnyPublisher<T, APIError>
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
                      httpResponse.statusCode == ResponseCodes.GetSuccessful.rawValue else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { _ in APIError.decodingError }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func request(for endpoint: Endpoint, method: Method, object: ObjectEntities? = nil, id: String? = nil, content: Data? = nil, groupName: String? = nil, query: String? = nil) -> URLRequest {
        var path = "\(baseURL)/api\(endpoint.rawValue)"
        if path.contains("{entity}") { path = path.replacingOccurrences(of: "{entity}", with: object!.rawValue) }
        if path.contains("{objectId}") { path = path.replacingOccurrences(of: "{objectId}", with: id!) }
        if path.contains("{userId}") { path = path.replacingOccurrences(of: "{userId}", with: id!) }
        if path.contains("{entryId}") { path = path.replacingOccurrences(of: "{entryId}", with: id!) }
        if path.contains("{productId}") { path = path.replacingOccurrences(of: "{productId}", with: id!) }
        if path.contains("{productIdToKeep}") { path = path.replacingOccurrences(of: "{productIdToKeep}", with: id!) }
        if path.contains("{productIdToRemove}") { path = path.replacingOccurrences(of: "{productIdToRemove}", with: id!) }
        if path.contains("{bookingId}") { path = path.replacingOccurrences(of: "{bookingId}", with: id!) }
        if path.contains("{transactionId}") { path = path.replacingOccurrences(of: "{transactionId}", with: id!) }
        if path.contains("{barcode}") { path = path.replacingOccurrences(of: "{barcode}", with: id!) }
        if path.contains("{recipeId}") { path = path.replacingOccurrences(of: "{recipeId}", with: id!) }
        if path.contains("{choreId}") { path = path.replacingOccurrences(of: "{choreId}", with: id!) }
        if path.contains("{executionId}") { path = path.replacingOccurrences(of: "{executionId}", with: id!) }
        if path.contains("{batteryId}") { path = path.replacingOccurrences(of: "{batteryId}", with: id!) }
        if path.contains("{chargeCycleId}") { path = path.replacingOccurrences(of: "{chargeCycleId}", with: id!) }
        if path.contains("{taskId}") { path = path.replacingOccurrences(of: "{taskId}", with: id!) }
        if path.contains("{group}") { path = path.replacingOccurrences(of: "{group}", with: groupName!) }
        if path.contains("{fileName}") { path = path.replacingOccurrences(of: "{fileName}", with: id!) }
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
        //        Generic entity interactions
        case objectsEntity = "/objects/{entity}"
        case objectsEntityWithID = "/objects/{entity}/{objectId}"
        case userfieldsEntity = "/userfields/{entity}/{objectId}"
        //        System
        case systemInfo = "/system/info"
        case systemDBChangedTime = "/system/db-changed-time"
        case systemConfig = "/system/config"
        case systemTime = "/system/time"
        case systemLogMissingLocalization = "/system/log-missing/localization"
        //        User management
        case users = "/users"
        case usersWithID = "/users/{userId}"
        case usersWithIDPermissions = "/users/{userId}/permissions"
        //        Current user
        case user = "/user"
        case userSettings = "/user/settings"
        case userSettingsWithKey = "/user/settings/{settingKey}"
        //        Stock
        case stock = "/stock"
        case stockEntryWithID = "/stock/entry/{entryId}"
        case stockVolatile = "/stock/volatile"
        case stockProductWithId = "/stock/products/{productId}"
        case stockProductWithIdLocations = "/stock/products/{productId}/locations"
        case stockProductWithIdEntries = "/stock/products/{productId}/entries"
        case stockProductWithIdPriceHistory = "/stock/products/{productId}/price-history"
        case stockProductWithIDAdd = "/stock/products/{productId}/add"
        case stockProductWithIDConsume = "/stock/products/{productId}/consume"
        case stockProductWithIDTransfer = "/stock/products/{productId}/transfer"
        case stockProductWithIDInventory = "/stock/products/{productId}/inventory"
        case stockProductWithIDOpen = "/stock/products/{productId}/open"
        case stockProductMergeWithIDs = "/stock/products/{productIdToKeep}/merge/{productIdToRemove}"
        case stockShoppingListAddMissing = "/stock/shoppinglist/add-missing-products"
        case stockShoppingListAddOverdue = "/stock/shoppinglist/add-overdue-products"
        case stockShoppingListAddExpired = "/stock/shoppinglist/add-expired-products"
        case stockShoppingListClear = "/stock/shoppinglist/clear"
        case stockShoppingListAddProduct = "/stock/shoppinglist/add-product"
        case stockShoppingListRemoveProduct = "/stock/shoppinglist/remove-product"
        case stockBookingWithId = "/stock/bookings/{bookingId}"
        case stockBookingWithIdUndo = "/stock/bookings/{bookingId}/undo"
        case stockTransactionWithID = "/stock/transactions/{transactionId}"
        case stockTransactionWithIDUndo = "/stock/transactions/{transactionId}/undo"
        case stockBarcodeExternalLookup = "/stock/barcodes/external-lookup/{barcode}"
        //        Stock by-barcode
        case stockByBarcode = "​/stock​/products​/by-barcode​/{barcode}"
        case stockByBarcodeAdd = "​/stock/products/by-barcode/{barcode}/add"
        case stockByBarcodeConsume = "​/stock/products/by-barcode/{barcode}/consume"
        case stockByBarcodeTransfer = "​/stock​/products​/by-barcode​/{barcode}/transfer"
        case stockByBarcodeInventory = "​/stock​/products​/by-barcode​/{barcode}/inventory"
        case stockByBarcodeOpen = "​/stock​/products​/by-barcode​/{barcode}/open"
        //        Recipes
        case recipeWithIDAddNotFulfilledShoppingList = "/recipes/{recipeId}/add-not-fulfilled-products-to-shoppinglist"
        case recipeWithIDFulfillment = "/recipes/{recipeId}/fulfillment"
        case recipeWithIDConsume = "/recipes/{recipeId}/consume"
        case recipesFulfillment = "/recipes/fulfillment"
        //        Chores
        case chores = "/chores"
        case choreWithID = "/chores/{choreId}"
        case choreWithIDExecute = "/chores/{choreId}/execute"
        case choreExecutionWithIDUndo = "/chores/executions/{executionId}/undo"
        case choreExecutionsCalculateNext = "/chores/executions/calculate-next-assignments"
        //        Batteries
        case batteries = "/batteries"
        case batteryWithID = "/batteries/{batteryId}"
        case batteryWithIDCharge = "/batteries/{batteryId}/charge"
        case batteryChargeCycleUndo = "/batteries/charge-cycles/{chargeCycleId}/undo"
        //        Tasks
        case tasks = "/tasks"
        case taskWithIDComplete = "/tasks/{taskId}/complete"
        case taskWithIDUndo = "/tasks/{taskId}/undo"
        //        Calendar
        case calendariCal = "/calendar/ical"
        case calendariCalSharingLink = "/calendar/ical/sharing-link"
        //        Files
        case filesGroupFilename = "/files/{group}/{fileName}"
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
    
    func getSystemConfig() -> AnyPublisher<SystemConfig, APIError> {
        return call(.systemConfig, method: .GET)
    }
    
    // MARK: - User management
    
    func getUsers() -> AnyPublisher<GrocyUsers, APIError> {
        return call(.users, method: .GET)
    }
    
    func postUser(user: Data) -> AnyPublisher<ErrorMessage, APIError> {
        return call(.users, method: .POST, content: user)
    }
    
    func putUserWithID(id: String, user: Data) -> AnyPublisher<ErrorMessage, APIError> {
        return call(.usersWithID, method: .PUT, id: id, content: user)
    }
    
    func deleteUserWithID(id: String) -> AnyPublisher<ErrorMessage, APIError> {
        return call(.usersWithID, method: .DELETE, id: id)
    }
    
    // MARK: - Current user
    func getUser() -> AnyPublisher<GrocyUsers, APIError> {
        return call(.user, method: .GET)
    }
    
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
    
    func getStockProductDetails<T: Codable>(stockModeGet: StockProductGet, id: String, query: String? = nil) -> AnyPublisher<T, APIError> {
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
            return call(.stockProductWithIDAdd, method: .POST, id: id, content: content)
        case .consume:
            return call(.stockProductWithIDConsume, method: .POST, id: id, content: content)
        case .inventory:
            return call(.stockProductWithIDInventory, method: .POST, id: id, content: content)
        case .open:
            return call(.stockProductWithIDOpen, method: .POST, id: id, content: content)
        case .transfer:
            return call(.stockProductWithIDTransfer, method: .POST, id: id, content: content)
        }
    }
    
    func getBookingWithID(id: String) -> AnyPublisher<StockJournalEntry, APIError> {
        return call(.stockBookingWithId, method: .GET)
    }
    
    func undoBookingWithID<T: Codable>(id: String) -> AnyPublisher<T, APIError> {
        return call(.stockBookingWithIdUndo, method: .POST, id: id)
    }
    
    func getPictureURL(groupName: String, fileName: String) -> String? {
        let filepath = request(for: .filesGroupFilename, method: .GET, id: fileName, groupName: groupName, query: "?force_serve_as=picture").url?.absoluteString
        if groupName == "userfiles" || groupName == "userpictures" {
            return filepath?.replacingOccurrences(of: "/api", with: "")
        } else {
            return filepath
        }
    }
    
    // SHOPPING LIST
    
    func shoppingListAddProduct<T: Codable>(content: Data) -> AnyPublisher<T, APIError> {
        return call(.stockShoppingListAddProduct, method: .POST, content: content)
    }
    
    func shoppingListAction<T: Codable>(content: Data, actionType: ShoppingListActionType) -> AnyPublisher<T, APIError> {
        switch actionType {
        case .clear:
            return call(.stockShoppingListClear, method: .POST, content: content)
        case .addExpired:
            return call(.stockShoppingListAddExpired, method: .POST, content: content)
        case .addMissing:
            return call(.stockShoppingListAddMissing, method: .POST, content: content)
        case .addOverdue:
            return call(.stockShoppingListAddOverdue, method: .POST, content: content)
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
