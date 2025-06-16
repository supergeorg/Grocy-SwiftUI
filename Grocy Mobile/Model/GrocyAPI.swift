//
//  GrocyAPI.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import Foundation

public enum APIError: Error, Equatable {
    var value: String? {
        return String(describing: self).components(separatedBy: "(").first
    }
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
       lhs.value == rhs.value
    }
    case internalError
    case serverError(error: Error)
    case serverError(errorMessage: String)
    case encodingError
    case invalidResponse
    case unsuccessful(error: Error)
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
    case system_info, system_db_changed_time, system_config, stock, volatileStock, users, current_user, user_settings, recipeFulfillments
}

public enum StockProductPost: String {
    case add, consume, transfer, inventory, open
}

public enum StockProductGet: String {
    case details, locations, entries, priceHistory
}

public enum ShoppingListActionType: String {
    case clear, clearDone, addExpired, addOverdue, addMissing
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
    func setHassData(hassURL: String, hassToken: String) async
    func clearHassData()
    func setTimeoutInterval(timeoutInterval: Double)
    // MARK: - System
    func getSystemInfo() async throws -> SystemInfo
    func getSystemDBChangedTime() async throws -> SystemDBChangedTime
    func getSystemConfig() async throws -> SystemConfig
    // MARK: - User management
    func getUsers() async throws -> GrocyUsers
    func postUser(user: Data) async throws
    func putUserWithID(id: Int, user: Data) async throws
    func deleteUserWithID(id: Int) async throws
    // MARK: - Recipes
    func getRecipeFulfillments() async throws -> RecipeFulfilments
    // MARK: - Current user
    func getUser() async throws -> GrocyUsers
    func getUserSettings() async throws -> GrocyUserSettings
    func getUserSettingKey<T: Codable>(settingKey: String) async throws -> T
    func putUserSettingKey(settingKey: String, content: Data) async throws
    // MARK: - Stock
    func getStock() async throws -> Stock
    func getStockJournal() async throws -> StockJournal
    func getVolatileStock(dueSoonDays: Int) async throws -> VolatileStock
    func getStockProductInfo<T: Codable>(stockModeGet: StockProductGet, id: Int, queries: [String]?) async throws -> T
    func putStockEntry(entryID: Int, content: Data) async throws -> StockJournal
    func postStock<T: Codable>(id: Int, content: Data, stockModePost: StockProductPost) async throws -> T
    func getBookingWithID(id: Int) async throws -> StockJournalEntry
    func undoBookingWithID(id: Int) async throws
    func getPictureURL(groupName: String, fileName: String)async throws -> String?
    // MARK: - Shopping List
    func shoppingListAddItem(content: Data) async throws
    func shoppingListAction(content: Data, actionType: ShoppingListActionType) async throws
    // MARK: - Master Data
    func getObject<T: Codable>(object: ObjectEntities) async throws -> T
    func postObject<T: Codable>(object: ObjectEntities, content: Data) async throws -> T
    func getObjectWithID<T: Codable>(object: ObjectEntities, id: Int) async throws -> T
    func putObjectWithID(object: ObjectEntities, id: Int, content: Data) async throws
    func deleteObjectWithID(object: ObjectEntities, id: Int) async throws
    // MARK: - Files
    func getFile(fileName: String, groupName: String, bestFitHeight: Int?, bestFitWidth: Int?) async throws -> Data
    func putFile(fileURL: URL, fileName: String, groupName: String) async throws
    func putFileData(fileData: Data, fileName: String, groupName: String) async throws
    func deleteFile(fileName: String, groupName: String) async throws
}

public class GrocyApi: GrocyAPI {
    var hassAuthenticator: HomeAssistantAuthenticator?
    
    private var timeoutInterval: Double = 60.0
    
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
    
    func setTimeoutInterval(timeoutInterval: Double) {
        self.timeoutInterval = timeoutInterval
    }
    
    private enum Method: String {
        case GET
        case POST
        case DELETE
        case PUT
    }
    
    private func callGetFileData(
        _ endPoint: Endpoint,
        fileName: String? = nil,
        groupName: String? = nil,
        bestFitHeight: Int? = nil,
        bestFitWidth: Int? = nil,
        hassIngressToken: String? = nil
    ) async throws -> Data {
        var queries = ["force_serve_as=picture"]
        if let bestFitHeight = bestFitHeight { queries.append("best_fit_height=\(bestFitHeight)") }
        if let bestFitWidth = bestFitWidth { queries.append("best_fit_width=\(bestFitWidth)") }
        
        let urlRequest = request(
            for: endPoint,
            method: .GET,
            fileName: fileName,
            groupName: groupName,
            isOctet: true,
            queries: queries,
            hassIngressToken: hassIngressToken
        )
        let (resultData, resultCode) = try await URLSession.shared.data(for: urlRequest)
        if let httpResponse = resultCode as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                return resultData
            } else if httpResponse.statusCode == 204 {
                throw APIError.serverError(errorMessage: "No content found. Wrong image?")
            } else {
                do {
                    print(httpResponse.statusCode)
                    print(resultData)
                    let responseErrorDecoded = try JSONDecoder().decode(ErrorMessage.self, from: resultData)
                    throw APIError.errorString(description: responseErrorDecoded.errorMessage)
                } catch {
                    throw APIError.decodingError(error: error)
                }
            }
        } else {
            throw APIError.internalError
        }
    }
    
    private func callUploadFileData(
        _ endPoint: Endpoint,
        fileData: Data,
        id: String? = nil,
        fileName: String? = nil,
        groupName: String? = nil,
        hassIngressToken: String? = nil
    ) async throws {
        let urlRequest = request(for: endPoint, method: .PUT, id: id, fileName: fileName, groupName: groupName, isOctet: true, hassIngressToken: hassIngressToken)
        let (resultData, resultCode) = try await URLSession.shared.upload(for: urlRequest, from: fileData)
        if let httpResponse = resultCode as? HTTPURLResponse {
            if httpResponse.statusCode != 204 {
                do {
                    let responseErrorDecoded = try JSONDecoder().decode(ErrorMessage.self, from: resultData)
                    throw APIError.errorString(description: responseErrorDecoded.errorMessage)
                } catch {
                    throw APIError.decodingError(error: error)
                }
            }
        } else {
            throw APIError.internalError
        }
    }
    
    private func callUploadFile(
        _ endPoint: Endpoint,
        fileURL: URL,
        id: String? = nil,
        fileName: String? = nil,
        groupName: String? = nil,
        hassIngressToken: String? = nil
    ) async throws {
        let urlRequest = request(for: endPoint, method: .PUT, id: id, fileName: fileName, groupName: groupName, isOctet: true, hassIngressToken: hassIngressToken)
        let (resultData, resultCode) = try await URLSession.shared.upload(for: urlRequest, fromFile: fileURL)
        if let httpResponse = resultCode as? HTTPURLResponse {
            if httpResponse.statusCode != 204 {
                do {
                    let responseErrorDecoded = try JSONDecoder().decode(ErrorMessage.self, from: resultData)
                    throw APIError.errorString(description: responseErrorDecoded.errorMessage)
                } catch {
                    throw APIError.decodingError(error: error)
                }
            }
        } else {
            throw APIError.internalError
        }
    }
    
    private func callEmptyResponse(
        _ endPoint: Endpoint,
        method: Method,
        object: ObjectEntities? = nil,
        id: String? = nil,
        fileName: String? = nil,
        groupName: String? = nil,
        content: Data? = nil,
        queries: [String]? = nil
    ) async throws {
        if let hassAuthenticator = hassAuthenticator {
            let hassToken = try await hassAuthenticator.validTokenAsync()
            try await self.callAPIEmptyResponse(
                endPoint,
                method: method,
                object: object,
                id: id,
                fileName: fileName,
                groupName: groupName,
                content: content,
                queries: queries,
                hassIngressToken: hassToken
            )
        } else {
            try await self.callAPIEmptyResponse(
                endPoint,
                method: method,
                object: object,
                id: id,
                fileName: fileName,
                groupName: groupName,
                content: content,
                queries: queries
            )
        }
    }
    
    private func callAPIEmptyResponse(
        _ endPoint: Endpoint,
        method: Method,
        object: ObjectEntities? = nil,
        id: String? = nil,
        fileName: String? = nil,
        groupName: String? = nil,
        content: Data? = nil,
        queries: [String]? = nil,
        hassIngressToken: String? = nil
    ) async throws {
        let urlRequest = request(
            for: endPoint,
            method: method,
            object: object,
            id: id,
            fileName: fileName,
            groupName: groupName,
            content: content,
            queries: queries,
            hassIngressToken: hassIngressToken
        )
        let result = try await URLSession.shared.data(for: urlRequest)
        if let httpResponse = result.1 as? HTTPURLResponse {
            if !((200...299).contains(httpResponse.statusCode)) {
                do {
                    let responseErrorDecoded = try JSONDecoder().decode(ErrorMessage.self, from: result.0)
                    throw APIError.errorString(description: responseErrorDecoded.errorMessage)
                } catch {
                    throw APIError.decodingError(error: error)
                }
            }
        } else {
            throw APIError.internalError
        }
    }
    
    private func call<T: Codable>(
        _ endPoint: Endpoint,
        method: Method,
        object: ObjectEntities? = nil,
        id: String? = nil,
        content: Data? = nil,
        queries: [String]? = nil
    ) async throws -> T {
        if let hassAuthenticator = hassAuthenticator {
            let hassToken = try await hassAuthenticator.validTokenAsync()
            return try await self.callAPI(endPoint, method: method, object: object, id: id, content: content, queries: queries, hassIngressToken: hassToken)
        } else {
            return try await self.callAPI(endPoint, method: method, object: object, id: id, content: content, queries: queries)
        }
    }
    
    private func callAPI<T: Codable>(
        _ endPoint: Endpoint,
        method: Method,
        object: ObjectEntities? = nil,
        id: String? = nil,
        content: Data? = nil,
        queries: [String]? = nil,
        hassIngressToken: String? = nil
    ) async throws -> T {
        let urlRequest = request(
            for: endPoint,
            method: method,
            object: object,
            id: id,
            content: content,
            queries: queries,
            hassIngressToken: hassIngressToken
        )
        let result = try await URLSession.shared.data(for: urlRequest)
        if let httpResponse = result.1 as? HTTPURLResponse {
            if (200...299).contains(httpResponse.statusCode) {
                do {
                    let responseDataDecoded = try JSONDecoder().decode(T.self, from: result.0)
                    return responseDataDecoded
                } catch {
                    throw APIError.decodingError(error: error)
                }
            } else {
                do {
                    let responseErrorDecoded = try JSONDecoder().decode(ErrorMessage.self, from: result.0)
                    throw APIError.errorString(description: responseErrorDecoded.errorMessage)
                } catch {
                    throw APIError.decodingError(error: error)
                }
            }
        }
        throw APIError.internalError
    }
    
    private func request(
        for endpoint: Endpoint,
        method: Method,
        object: ObjectEntities? = nil,
        id: String? = nil,
        fileName: String? = nil,
        groupName: String? = nil,
        isOctet: Bool = false,
        content: Data? = nil,
        queries: [String]? = nil,
        hassIngressToken: String? = nil
    ) -> URLRequest {
        if self.baseURL.hasSuffix("/") { self.baseURL = String(self.baseURL.dropLast()) }
        var path = "\(self.baseURL)\(self.baseURL.hasSuffix("/api") ? "" : "/api")\(endpoint.rawValue)"
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
        if path.contains("{fileName}") { path = path.replacingOccurrences(of: "{fileName}", with: fileName!) }
        if path.contains("{group}") { path = path.replacingOccurrences(of: "{group}", with: groupName!) }
        if path.contains("{settingKey}") { path = path.replacingOccurrences(of: "{settingKey}", with: id!) }
        if let queries = queries {
            let query = queries.joined(separator: "&")
            path += "?\(query)"
        }
        
        guard let url = URL(string: path)
        else { preconditionFailure("Bad URL") }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = ["Content-Type": isOctet ? "application/octet-stream" : "application/json",
                                       "Accept": "application/json",
                                       "GROCY-API-KEY": self.apiKey]
        
        if let hassIngressToken = hassIngressToken {
            request.addValue("ingress_session=\(hassIngressToken)", forHTTPHeaderField: "Cookie")
        }
        if content != nil {
            request.httpBody = content
        }
        
        print(url.absoluteString)
        
        request.timeoutInterval = self.timeoutInterval
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
        case stockEntryWithIDPrintlabel = "/stock/entry/{entryId}/printlabel"
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
        case stockLocationsWithIdEntries = "/stock/locations/{locationId}/entries"
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
    
    func getSystemInfo() async throws -> SystemInfo {
        return try await call(.systemInfo, method: .GET)
    }

    func getSystemDBChangedTime() async throws -> SystemDBChangedTime {
        return try await call(.systemDBChangedTime, method: .GET)
    }
    
    func getSystemConfig() async throws -> SystemConfig {
        return try await call(.systemConfig, method: .GET)
    }
    
    // MARK: - User management
    
    func getUsers() async throws -> GrocyUsers {
        return try await call(.users, method: .GET)
    }
    
    func getUserSettings() async throws -> GrocyUserSettings {
        return try await call(.userSettings, method: .GET)
    }
    
    func getUserSettingKey<T: Codable>(settingKey: String) async throws -> T {
        return try await call(.userSettingsWithKey, method: .GET, id: settingKey)
    }
    
    func putUserSettingKey(settingKey: String, content: Data) async throws {
        return try await callEmptyResponse(.userSettingsWithKey, method: .PUT, id: settingKey, content: content)
    }
    
    func postUser(user: Data) async throws {
        return try await callEmptyResponse(.users, method: .POST, content: user)
    }
    
    func putUserWithID(id: Int, user: Data) async throws {
        return try await callEmptyResponse(.usersWithID, method: .PUT, id: String(id), content: user)
    }
    
    func deleteUserWithID(id: Int) async throws {
        return try await callEmptyResponse(.usersWithID, method: .DELETE, id: String(id))
    }
    
    // MARK: - Recipes
    func getRecipeFulfillments() async throws -> RecipeFulfilments {
        return try await call(.recipesFulfillment, method: .GET)
    }
    
    // MARK: - Current user
    func getUser() async throws -> GrocyUsers {
        return try await call(.user, method: .GET)
    }
    
    // MARK: - Stock
    
    func getStock() async throws -> [StockElement] {
        return try await call(.stock, method: .GET)
    }
    
    func getStockJournal() async throws -> StockJournal {
        return try await call(.objectsEntity, method: .GET, object: .stock_log)
    }
    
    func getVolatileStock(dueSoonDays: Int) async throws -> VolatileStock {
        return try await call(.stockVolatile, method: .GET, queries: ["due_soon_days=\(dueSoonDays)"])
    }
    
    func getStockProductInfo<T: Codable>(stockModeGet: StockProductGet, id: Int, queries: [String]? = nil) async throws -> T {
        switch stockModeGet {
        case .details:
            return try await call(.stockProductWithId, method: .GET, id: String(id))
        case .entries:
            return try await call(.stockProductWithIdEntries, method: .GET, id: String(id), queries: queries)
        case .locations:
            return try await call(.stockProductWithIdLocations, method: .GET, id: String(id))
        case .priceHistory:
            return try await call(.stockProductWithIdPriceHistory, method: .GET, id: String(id))
        }
    }
    
    func putStockEntry(entryID: Int, content: Data) async throws -> StockJournal {
        return try await call(.stockEntryWithID, method: .PUT, id: String(entryID), content: content)
    }
    
    func postStock<T: Codable>(id: Int, content: Data, stockModePost: StockProductPost) async throws -> T {
        switch stockModePost {
        case .add:
            return try await call(.stockProductWithIDAdd, method: .POST, id: String(id), content: content)
        case .consume:
            return try await call(.stockProductWithIDConsume, method: .POST, id: String(id), content: content)
        case .inventory:
            return try await call(.stockProductWithIDInventory, method: .POST, id: String(id), content: content)
        case .open:
            return try await call(.stockProductWithIDOpen, method: .POST, id: String(id), content: content)
        case .transfer:
            return try await call(.stockProductWithIDTransfer, method: .POST, id: String(id), content: content)
        }
    }
    
    func getBookingWithID(id: Int) async throws -> StockJournalEntry {
        return try await call(.stockBookingWithId, method: .GET)
    }
    
    func undoBookingWithID(id: Int) async throws {
        return try await callEmptyResponse(.stockBookingWithIdUndo, method: .POST, id: String(id))
    }
    
    func getPictureURL(groupName: String, fileName: String) -> String? {
        let filepath = request(for: .filesGroupFilename, method: .GET, fileName: fileName, groupName: groupName, queries: ["force_serve_as=picture"]).url?.absoluteString
        if groupName == "userfiles" || groupName == "userpictures" {
            return filepath?.replacingOccurrences(of: "/api", with: "")
        } else {
            return filepath
        }
    }
    
    // MARK: - SHOPPING LIST
    
    func shoppingListAddItem(content: Data) async throws {
        try await callEmptyResponse(.objectsEntity, method: .POST, object: .shopping_list, content: content)
    }
    
    func shoppingListAction(content: Data, actionType: ShoppingListActionType) async throws {
        switch actionType {
        case .clear:
            return try await callEmptyResponse(.stockShoppingListClear, method: .POST, content: content)
        case .clearDone:
            return try await callEmptyResponse(.stockShoppingListClear, method: .POST, content: content)
        case .addExpired:
            return try await callEmptyResponse(.stockShoppingListAddExpired, method: .POST, content: content)
        case .addMissing:
            return try await callEmptyResponse(.stockShoppingListAddMissing, method: .POST, content: content)
        case .addOverdue:
            return try await callEmptyResponse(.stockShoppingListAddOverdue, method: .POST, content: content)
        }
    }
    
    // MARK: - Master Data
    
    func getObject<T: Codable>(object: ObjectEntities) async throws -> T {
        return try await call(.objectsEntity, method: .GET, object: object)
    }
    
    func postObject<T: Codable>(object: ObjectEntities, content: Data) async throws -> T {
        return try await call(.objectsEntity, method: .POST, object: object, content: content)
    }
    
    func getObjectWithID<T: Codable>(object: ObjectEntities, id: Int) async throws -> T {
        return try await call(.objectsEntityWithID, method: .GET, object: object, id: String(id))
    }
    
    func putObjectWithID(object: ObjectEntities, id: Int, content: Data) async throws {
        return try await callEmptyResponse(.objectsEntityWithID, method: .PUT, object: object, id: String(id), content: content)
    }
    
    func deleteObjectWithID(object: ObjectEntities, id: Int) async throws {
        return try await callEmptyResponse(.objectsEntityWithID, method: .DELETE, object: object, id: String(id))
    }
    
    // MARK: - Files
    func getFile(fileName: String, groupName: String, bestFitHeight: Int? = nil, bestFitWidth: Int? = nil) async throws -> Data {
        return try await callGetFileData(.filesGroupFilename, fileName: fileName, groupName: groupName, bestFitHeight: bestFitHeight, bestFitWidth: bestFitWidth)
    }
    
    func putFile(fileURL: URL, fileName: String, groupName: String) async throws {
        return try await callUploadFile(.filesGroupFilename, fileURL: fileURL, fileName: fileName, groupName: groupName)
    }

    func putFileData(fileData: Data, fileName: String, groupName: String) async throws {
        return try await callUploadFileData(.filesGroupFilename, fileData: fileData, fileName: fileName, groupName: groupName)
    }

    func deleteFile(fileName: String, groupName: String) async throws {
        return try await callEmptyResponse(.filesGroupFilename, method: .DELETE, fileName: fileName, groupName: groupName)
    }
}
