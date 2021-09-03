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
    case serverError(error: String)
    case encodingError
    case invalidResponse
    case unsuccessful
    case errorString(description: String)
    case timeout
    case invalidEndpoint(endpoint: String)
    case decodingError(error: Error)
    case hassError(error: Error)
    case notLoggedIn(error: Error)
}

public enum ObjectEntities: String, CaseIterable {
    case products, product_barcodes, chores, batteries, locations, quantity_units, quantity_unit_conversions, shopping_list, shopping_lists, shopping_locations, recipes, recipes_pos, recipes_nestings, tasks, task_categories, product_groups, equipment, userfields, userentities, userobjects, meal_plan, stock_log
}

public enum AdditionalEntities: String, CaseIterable {
    case system_info, system_db_changed_time, system_config, stock, users, current_user
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

struct EmptyResponse: Codable {
    
}

protocol GrocyAPI {
    func setLoginData(baseURL: String, apiKey: String)
    func setHassData(hassURL: String, hassToken: String)
    func clearHassData()
    // MARK: - System
    func getSystemInfo() -> AnyPublisher<SystemInfo, APIError>
    func getSystemDBChangedTime() -> AnyPublisher<SystemDBChangedTime, APIError>
    func getSystemConfig() -> AnyPublisher<SystemConfig, APIError>
    // MARK: - User management
    func getUsers() -> AnyPublisher<GrocyUsers, APIError>
    func postUser(user: Data) -> AnyPublisher<Int, APIError>
    func putUserWithID(id: Int, user: Data) -> AnyPublisher<Int, APIError>
    func deleteUserWithID(id: Int) -> AnyPublisher<Int, APIError>
    // MARK: - Current user
    func getUser() -> AnyPublisher<GrocyUsers, APIError>
    // MARK: - Stock
    func getStock() -> AnyPublisher<Stock, APIError>
    func getStockJournal() -> AnyPublisher<StockJournal, APIError>
    func getVolatileStock(expiringDays: Int) -> AnyPublisher<VolatileStock, APIError>
    func getStockProductDetails<T: Codable>(stockModeGet: StockProductGet, id: Int, query: String?) -> AnyPublisher<T, APIError>
    //    func getStockProductLocations(stockModeGet: StockProductGet, id: Int, query: String?) -> AnyPublisher<StockLocations, APIError>
    //    func getStockProductEntries(stockModeGet: StockProductGet, id: Int, query: String?) -> AnyPublisher<StockEntries, APIError>
    //    func getStockProductPriceHistory(stockModeGet: StockProductGet, id: Int, query: String?) -> AnyPublisher<ProductPriceHistory, APIError>
    func postStock<T: Codable>(id: Int, content: Data, stockModePost: StockProductPost) -> AnyPublisher<T, APIError>
    func getBookingWithID(id: Int) -> AnyPublisher<StockJournalEntry, APIError>
    func undoBookingWithID(id: Int) -> AnyPublisher<Int, APIError>
    func getPictureURL(groupName: String, fileName: String) -> String?
    // MARK: - Shopping List
    func shoppingListAddProduct(content: Data) -> AnyPublisher<Int, APIError>
    func shoppingListAction(content: Data, actionType: ShoppingListActionType) -> AnyPublisher<Int, APIError>
    // MARK: - Master Data
    func getObject<T: Codable>(object: ObjectEntities) -> AnyPublisher<T, APIError>
    func postObject<T: Codable>(object: ObjectEntities, content: Data) -> AnyPublisher<T, APIError>
    func getObjectWithID<T: Codable>(object: ObjectEntities, id: Int) -> AnyPublisher<T, APIError>
    func putObjectWithID(object: ObjectEntities, id: Int, content: Data) -> AnyPublisher<Int, APIError>
    func deleteObjectWithID(object: ObjectEntities, id: Int) -> AnyPublisher<Int, APIError>
    // MARK: - Files
    func putFile(fileURL: URL, fileName: String, groupName: String, completion: @escaping ((Result<Int, Error>) -> ()))
    func deleteFile(fileName: String, groupName: String) -> AnyPublisher<Int, APIError>
}

public class GrocyApi: GrocyAPI {
    var hassAuthenticator: HomeAssistantAuthenticator?
    
    private var baseURL: String = ""
    private var apiKey: String = ""
    
    func setLoginData(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    func setHassData(hassURL: String, hassToken: String) {
        self.hassAuthenticator = HomeAssistantAuthenticator(hassURL: hassURL, hassToken: hassToken)
    }
    
    func clearHassData() {
        self.hassAuthenticator = nil
    }
    
    private enum Method: String {
        case GET
        case POST
        case DELETE
        case PUT
    }
    
    private func callUpload(_ endPoint: Endpoint, fileURL: URL, id: Int? = nil, fileName: String? = nil, groupName: String? = nil, hassIngressToken: String? = nil, completion: @escaping ((Result<Int, Error>) -> ())){
        let urlRequest = request(for: endPoint, method: .PUT, id: id, fileName: fileName, groupName: groupName, isOctet: true, hassIngressToken: hassIngressToken)
        let uploadTask = URLSession.shared.uploadTask(with: urlRequest, fromFile: fileURL) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 204 else {
                completion(.failure(APIError.unsuccessful))
                return
            }
            completion(.success(204))
        }
        uploadTask.resume()
    }
    
    private func callEmptyResponse(_ endPoint: Endpoint, method: Method, object: ObjectEntities? = nil, id: Int? = nil, fileName: String? = nil, groupName: String? = nil, content: Data? = nil, query: String? = nil) -> AnyPublisher<Int, APIError> {
        if let hassAuthenticator = hassAuthenticator {
            return hassAuthenticator.validToken()
                .flatMap({ token in
                    // we can now use this token to authenticate the request
                    self.callAPIEmptyResponse(endPoint, method: method, object: object, id: id, fileName: fileName, groupName: groupName, content: content, query: query, hassIngressToken: token.data?.session)
                })
                .tryCatch({ error -> AnyPublisher<Int, APIError> in
                    return hassAuthenticator.validToken(forceRefresh: true)
                        .flatMap({ token in
                            // we can now use this new token to authenticate the second attempt at making this request
                            self.callAPIEmptyResponse(endPoint, method: method, object: object, id: id, fileName: fileName, groupName: groupName, content: content, query: query, hassIngressToken: token.data?.session)
                        })
                        .eraseToAnyPublisher()
                })
                .mapError { error in return APIError.hassError(error: error) }
                .eraseToAnyPublisher()
        } else {
            return self.callAPIEmptyResponse(endPoint, method: method, object: object, id: id, fileName: fileName, groupName: groupName, content: content, query: query)
        }
    }
    
    private func callAPIEmptyResponse(_ endPoint: Endpoint, method: Method, object: ObjectEntities? = nil, id: Int? = nil, fileName: String? = nil, groupName: String? = nil, content: Data? = nil, query: String? = nil, hassIngressToken: String? = nil) -> AnyPublisher<Int, APIError> {
        let urlRequest = request(for: endPoint, method: method, object: object, id: id, fileName: fileName, groupName: groupName, content: content, query: query, hassIngressToken: hassIngressToken)
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .mapError{ error in
                APIError.serverError(error: "\(error)") }
            .flatMap({ result -> Just<Int> in
                guard let urlResponse = result.response as? HTTPURLResponse else {
                    return Just(0)
                }
                return Just(urlResponse.statusCode)
            })
            .mapError { _ in APIError.invalidResponse }
            .eraseToAnyPublisher()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func call<T: Codable>(_ endPoint: Endpoint, method: Method, object: ObjectEntities? = nil, id: Int? = nil, content: Data? = nil, query: String? = nil) -> AnyPublisher<T, APIError> {
        if let hassAuthenticator = hassAuthenticator {
            return hassAuthenticator.validToken()
                .flatMap({ token in
                    // we can now use this token to authenticate the request
                    self.callAPI(endPoint, method: method, object: object, id: id, content: content, query: query, hassIngressToken: token.data?.session)
                })
                .tryCatch({ error -> AnyPublisher<T, APIError> in
                    return hassAuthenticator.validToken(forceRefresh: true)
                        .flatMap({ token in
                            // we can now use this new token to authenticate the second attempt at making this request
                            token.data != nil ? self.callAPI(endPoint, method: method, object: object, id: id, content: content, query: query, hassIngressToken: token.data?.session) : self.callAPI(endPoint, method: method, object: object, id: id, content: content, query: query, hassIngressToken: hassAuthenticator.getToken())
                        })
                        .eraseToAnyPublisher()
                })
                .mapError { error in return APIError.hassError(error: error) }
                .eraseToAnyPublisher()
        } else {
            return self.callAPI(endPoint, method: method, object: object, id: id, content: content, query: query)
        }
    }
    
    private func callAPI<T: Codable>(_ endPoint: Endpoint, method: Method, object: ObjectEntities? = nil, id: Int? = nil, content: Data? = nil, query: String? = nil, hassIngressToken: String? = nil) -> AnyPublisher<T, APIError> {
        let urlRequest = request(for: endPoint, method: method, object: object, id: id, content: content, query: query, hassIngressToken: hassIngressToken)
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .mapError{ error in
                APIError.serverError(error: "\(error)") }
            .flatMap({ result -> AnyPublisher<T, APIError> in
                if let urlResponse = result.response as? HTTPURLResponse, (200...299).contains(urlResponse.statusCode) {
                    return Just(result.data)
                        .decode(type: T.self, decoder: JSONDecoder())
                        .mapError{ error in APIError.decodingError(error: error) }
                        .eraseToAnyPublisher()
                } else {
                    return Just(result.data)
                        // decode if it is an error message
                        .decode(type: ErrorMessage.self, decoder: JSONDecoder())
                        // neither valid response nor error message
                        .mapError { error in (result.response as? HTTPURLResponse)?.statusCode == 401 ? APIError.notLoggedIn(error: error) : APIError.decodingError(error: error) }
                        // display error message
                        .tryMap { throw APIError.errorString(description: $0.errorMessage) }
                        .mapError { $0 as! APIError }
                        .eraseToAnyPublisher()
                }
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func request(for endpoint: Endpoint, method: Method, object: ObjectEntities? = nil, id: Int? = nil, fileName: String? = nil, groupName: String? = nil, isOctet: Bool = false, content: Data? = nil, query: String? = nil, hassIngressToken: String? = nil) -> URLRequest {
        var path = "\(baseURL)/api\(endpoint.rawValue)"
        if path.contains("{entity}") { path = path.replacingOccurrences(of: "{entity}", with: object!.rawValue) }
        if path.contains("{objectId}") { path = path.replacingOccurrences(of: "{objectId}", with: String(id!)) }
        if path.contains("{userId}") { path = path.replacingOccurrences(of: "{userId}", with: String(id!)) }
        if path.contains("{entryId}") { path = path.replacingOccurrences(of: "{entryId}", with: String(id!)) }
        if path.contains("{productId}") { path = path.replacingOccurrences(of: "{productId}", with: String(id!)) }
        if path.contains("{productIdToKeep}") { path = path.replacingOccurrences(of: "{productIdToKeep}", with: String(id!)) }
        if path.contains("{productIdToRemove}") { path = path.replacingOccurrences(of: "{productIdToRemove}", with: String(id!)) }
        if path.contains("{bookingId}") { path = path.replacingOccurrences(of: "{bookingId}", with: String(id!)) }
        if path.contains("{transactionId}") { path = path.replacingOccurrences(of: "{transactionId}", with: String(id!)) }
        if path.contains("{barcode}") { path = path.replacingOccurrences(of: "{barcode}", with: String(id!)) }
        if path.contains("{recipeId}") { path = path.replacingOccurrences(of: "{recipeId}", with: String(id!)) }
        if path.contains("{choreId}") { path = path.replacingOccurrences(of: "{choreId}", with: String(id!)) }
        if path.contains("{executionId}") { path = path.replacingOccurrences(of: "{executionId}", with: String(id!)) }
        if path.contains("{batteryId}") { path = path.replacingOccurrences(of: "{batteryId}", with: String(id!)) }
        if path.contains("{chargeCycleId}") { path = path.replacingOccurrences(of: "{chargeCycleId}", with: String(id!)) }
        if path.contains("{taskId}") { path = path.replacingOccurrences(of: "{taskId}", with: String(id!)) }
        if path.contains("{fileName}") { path = path.replacingOccurrences(of: "{fileName}", with: fileName!) }
        if path.contains("{group}") { path = path.replacingOccurrences(of: "{group}", with: groupName!) }
        if let query = query { path += query }
        
        guard let url = URL(string: path)
        else { preconditionFailure("Bad URL") }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = ["Content-Type": isOctet ? "application/octet-stream" : "application/json",
                                       "Accept": "application/json",
                                       "GROCY-API-KEY": apiKey]
        
        if let hassIngressToken = hassIngressToken {
            request.addValue("ingress_session=\(hassIngressToken)", forHTTPHeaderField: "Cookie")
        }
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
    
    func postUser(user: Data) -> AnyPublisher<Int, APIError> {
        return callEmptyResponse(.users, method: .POST, content: user)
    }
    
    func putUserWithID(id: Int, user: Data) -> AnyPublisher<Int, APIError> {
        return callEmptyResponse(.usersWithID, method: .PUT, id: id, content: user)
    }
    
    func deleteUserWithID(id: Int) -> AnyPublisher<Int, APIError> {
        return callEmptyResponse(.usersWithID, method: .DELETE, id: id)
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
    
    func getStockProductDetails<T: Codable>(stockModeGet: StockProductGet, id: Int, query: String? = nil) -> AnyPublisher<T, APIError> {
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
    
    func postStock<T: Codable>(id: Int, content: Data, stockModePost: StockProductPost) -> AnyPublisher<T, APIError> {
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
    
    func getBookingWithID(id: Int) -> AnyPublisher<StockJournalEntry, APIError> {
        return call(.stockBookingWithId, method: .GET)
    }
    
    func undoBookingWithID(id: Int) -> AnyPublisher<Int, APIError> {
        return callEmptyResponse(.stockBookingWithIdUndo, method: .POST, id: id)
    }
    
    func getPictureURL(groupName: String, fileName: String) -> String? {
        let filepath = request(for: .filesGroupFilename, method: .GET, fileName: fileName, groupName: groupName, query: "?force_serve_as=picture").url?.absoluteString
        if groupName == "userfiles" || groupName == "userpictures" {
            return filepath?.replacingOccurrences(of: "/api", with: "")
        } else {
            return filepath
        }
    }
    
    // SHOPPING LIST
    
    func shoppingListAddProduct(content: Data) -> AnyPublisher<Int, APIError> {
        return callEmptyResponse(.stockShoppingListAddProduct, method: .POST, content: content)
    }
    
    func shoppingListAction(content: Data, actionType: ShoppingListActionType) -> AnyPublisher<Int, APIError> {
        switch actionType {
        case .clear:
            return callEmptyResponse(.stockShoppingListClear, method: .POST, content: content)
        case .addExpired:
            return callEmptyResponse(.stockShoppingListAddExpired, method: .POST, content: content)
        case .addMissing:
            return callEmptyResponse(.stockShoppingListAddMissing, method: .POST, content: content)
        case .addOverdue:
            return callEmptyResponse(.stockShoppingListAddOverdue, method: .POST, content: content)
        }
        
    }
    
    // MARK: - Master Data
    
    func getObject<T: Codable>(object: ObjectEntities) -> AnyPublisher<T, APIError> {
        return call(.objectsEntity, method: .GET, object: object)
    }
    
    func postObject<T: Codable>(object: ObjectEntities, content: Data) -> AnyPublisher<T, APIError> {
        return call(.objectsEntity, method: .POST, object: object, content: content)
    }
    
    func getObjectWithID<T: Codable>(object: ObjectEntities, id: Int) -> AnyPublisher<T, APIError> {
        return call(.objectsEntityWithID, method: .GET, object: object, id: id)
    }
    
    func putObjectWithID(object: ObjectEntities, id: Int, content: Data) -> AnyPublisher<Int, APIError> {
        return callEmptyResponse(.objectsEntityWithID, method: .PUT, object: object, id: id, content: content)
    }
    
    func deleteObjectWithID(object: ObjectEntities, id: Int) -> AnyPublisher<Int, APIError> {
        return callEmptyResponse(.objectsEntityWithID, method: .DELETE, object: object, id: id)
    }
    
    // MARK: - Files
    func putFile(fileURL: URL, fileName: String, groupName: String, completion: @escaping ((Result<Int, Error>) -> ())) {
        return callUpload(.filesGroupFilename, fileURL: fileURL, fileName: fileName, groupName: groupName, completion: completion)
    }
    
    func deleteFile(fileName: String, groupName: String) -> AnyPublisher<Int, APIError> {
        return callEmptyResponse(.filesGroupFilename, method: .DELETE, fileName: fileName, groupName: groupName)
    }
}
