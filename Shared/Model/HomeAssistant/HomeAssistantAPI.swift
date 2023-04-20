//
//  HomeAssistantAPI.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 21.08.21.
//

import Foundation
import Combine

// MARK: - HomeAssistantSessionCookie
struct HomeAssistantSessionCookieReturn: Codable {
    let result: String
    let data: HomeAssistantSessionCookie?
    
    enum CodingKeys: String, CodingKey {
        case result, data
    }
    
    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.result = try container.decode(String.self, forKey: .result)
            do { self.data = try container.decodeIfPresent(HomeAssistantSessionCookie.self, forKey: .data) } catch { self.data = nil }
        } catch {
            throw APIError.decodingError(error: error)
        }
    }
    
    init(result: String, data: HomeAssistantSessionCookie?) {
        self.result = result
        self.data = data
    }
}

func getHomeAssistantPathFromIngress(ingressPath: String) -> String? {
    do {
        let regex = try NSRegularExpression(pattern: ".+(?=/api/hassio_ingress/.)", options: [])
        let matches = regex.matches(in: ingressPath, options: [], range: NSRange(location: 0, length: ingressPath.utf16.count))
        if let match = matches.first {
            let matchBounds = match.range(at: 0)
            if let matchRange = Range(matchBounds, in: ingressPath) {
                return String(ingressPath[matchRange])
            }
        }
        return nil
    } catch {
        return nil
    }
}

// MARK: - DataClass
struct HomeAssistantSessionCookie: Codable {
    let session: String
}
struct HomeAssistantSessionCookieEmpty: Codable {
}

protocol NetworkSession: AnyObject {
    func publisher(for request: URLRequest) -> AnyPublisher<HomeAssistantSessionCookieReturn, APIError>
}

extension URLSession: NetworkSession {
    func publisher(for request: URLRequest) -> AnyPublisher<HomeAssistantSessionCookieReturn, APIError> {
        return dataTaskPublisher(for: request)
            .mapError{ error in APIError.serverError(error: error) }
            .flatMap({ result -> AnyPublisher<HomeAssistantSessionCookieReturn, APIError> in
                if let urlResponse = result.response as? HTTPURLResponse, (200...299).contains(urlResponse.statusCode) {
                    return Just(result.data)
                        .decode(type: HomeAssistantSessionCookieReturn.self, decoder: JSONDecoder())
                        .mapError { error in (result.response as? HTTPURLResponse)?.statusCode == 401 ? APIError.notLoggedIn(error: error) : APIError.decodingError(error: error) }
                        .eraseToAnyPublisher()
                } else {
                    return Just(result.data)
                        .tryMap { _ in throw APIError.hassError(error: APIError.errorString(description: "Invalid response to Home Assistant Request. Are you authenticated?")) }
                        .mapError { $0 as! APIError }
                        .eraseToAnyPublisher()
                }
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

//extension WebSocketSession: URLSessionWebSocketTask {
//    func publisher(for request: URLRequest) -> AnyPublisher<HomeAssistantSessionCookieReturn, APIError> {
//        return URLSessionWebSocketTask
//    }
//}

class WebSocket: NSObject, URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Web Socket did connect")
        //        ping()
        //        send()
        //        receive()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Web Socket did disconnect")
        print(closeCode)
        print(reason)
    }
}

class HomeAssistantWebSocket {
    private var webSocketTask: URLSessionWebSocketTask
    private var requestID: Int = 1
    private var timeoutInterval: Double
    private var hassToken: String
    
    // MARK: - HomeAssistantSocketAuthState
    struct HomeAssistantSocketAuthState: Codable {
        let type: String
        let haVersion: String
        
        enum CodingKeys: String, CodingKey {
            case type = "type"
            case haVersion = "ha_version"
        }
    }
    
    // MARK: - HomeAssistantSocketAuthRequest
    struct HomeAssistantSocketAuthRequest: Codable {
        let type: String
        let accessToken: String
        
        enum CodingKeys: String, CodingKey {
            case type = "type"
            case accessToken = "access_token"
        }
        
        init(type: String, accessToken: String) {
            self.type = type
            self.accessToken = accessToken
        }
    }
    
    // MARK: - HomeAssistantSocketAuthReturn
    struct HomeAssistantSocketAuthReturn: Codable {
        let type: String
        let message: String
        
        enum CodingKeys: String, CodingKey {
            case type = "type"
            case message = "message"
        }
    }
    
    // MARK: - HomeAssistantSocketTokenRequest
    struct HomeAssistantSocketTokenRequest: Codable {
        let id: Int
        let type, endpoint, method: String
        
        init(
            id: Int,
            type: String,
            endpoint: String,
            method: String
        ) {
            self.id = id
            self.type = type
            self.endpoint = endpoint
            self.method = method
        }
    }
    
    // MARK: - HomeAssistantSocketTokenReturn
    struct HomeAssistantSocketTokenReturn: Codable {
        let id: Int
        let type: String
        let success: Bool
        let result: HomeAssistantSocketTokenReturnResult
    }
    struct HomeAssistantSocketTokenReturnResult: Codable {
        let session: String
    }
    
    init(hassURL: String, hassToken: String, timeoutInterval: Double) {
        self.hassToken = hassToken
        self.timeoutInterval = timeoutInterval
        let webSocketURL = hassURL
            .replacingOccurrences(of: "https", with: "wss")
            .replacingOccurrences(of: "http", with: "ws")
        let webSocketPath = "\(webSocketURL)/api/websocket"
        guard let url = URL(string: webSocketPath)
        else {
            preconditionFailure("Bad URL")
        }
        let urlRequest = URLRequest(url: url, timeoutInterval: self.timeoutInterval)
        let session = URLSession(configuration: .default, delegate: WebSocket(), delegateQueue: OperationQueue())
        self.webSocketTask = session.webSocketTask(with: urlRequest)
        self.webSocketTask.resume()
        print("INIT FINISHEDD")
    }
    
    func authenticateSocket() async throws {
        // 1. Get data, should show not authorized message
        let authStateMessageNonAuthorized: HomeAssistantSocketAuthState = try await self.receiveDataAsync()
        guard authStateMessageNonAuthorized.type == "auth_required" else {
            throw APIError.hassError(error: APIError.invalidResponse)
        }
        print("GET AUTH_REQ")
        
//        // 2. Build auth request
//        let authMessage = HomeAssistantSocketAuthRequest(type: "auth", accessToken: hassToken)
//        let jsonAuthMessage = try! JSONEncoder().encode(authMessage)
//        try await self.sendDataAsync(data: jsonAuthMessage)
//        print("SEND AUTH")
//
//        // 3. Get authentication return
//        let authStateMessageAuthorized: HomeAssistantSocketAuthState = try await self.receiveDataAsync()
//        guard authStateMessageAuthorized.type == "auth_ok" else {
//            throw APIError.hassError(error: APIError.serverError(errorMessage: "Home Assistant not authorized, state is \(authStateMessageAuthorized.type)"))
//        }
//        print("GET AUTH_OK")
    }
    
    func getToken() async throws -> String {
//        let tokenRequest = HomeAssistantSocketTokenRequest(id: self.requestID, type: "supervisor/api", endpoint: "/ingress/session", method: "post")
//        self.requestID = self.requestID + 1
//        let tokenRequestJSON = try JSONEncoder().encode(tokenRequest)
//        try await self.sendDataAsync(data: tokenRequestJSON)
//        let tokenReturn: HomeAssistantSocketTokenReturn = try await self.receiveDataAsync()
        print("TOKEN REQUESTED")
        return "8cae7765bf06d8b516d70177e2455b0f520dc9156e954065e101c43412852ff8cf68527edbbd6484309e1a23c00b7299b5f31f9546745dc33503b3a1f510f553"
//        return tokenReturn.result.session
    }
    
    func receiveDataAsync<T: Codable>() async throws -> T {
        do {
            guard self.webSocketTask.state == .running else {
                throw APIError.internalError
            }
            let webSocketResult = try await self.webSocketTask.receive()
            switch webSocketResult {
            case .data(let data):
                let decoded = try JSONDecoder().decode(T.self, from: data)
                return decoded
            case .string(let text):
                let jsonData = text.data(using: .utf8)!
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: jsonData)
                    return decoded
                } catch {
                    let decodedError = try JSONDecoder().decode(HomeAssistantSocketAuthReturn.self, from: jsonData)
                    throw APIError.serverError(errorMessage: "Socket authentication failed. \(decodedError.type): \(decodedError.message)")
                }
            @unknown default:
                throw APIError.internalError
            }
        } catch APIError.internalError {
            print(APIError.internalError)
            throw APIError.internalError
        } catch {
            print(APIError.hassError(error: error))
            throw APIError.hassError(error: error)
        }
    }
    
    func sendDataAsync(data: Data) async throws {
        guard self.webSocketTask.state == .running else {
            throw APIError.internalError
        }
        try await self.webSocketTask.send(.data(data))
    }
}

class HomeAssistantAuthenticator {
    private var hassURL: String = ""
    private var hassToken: String
    
    private var hassIngressToken: String?
    private var hassIngressTokenDate: Date?
    
    private var timeoutInterval: Double = 60.0
    
    private var homeAssistantWebSocket: HomeAssistantWebSocket? = nil
    
    init(hassURL: String, hassToken: String, timeoutInterval: Double = 60) async {
        self.hassURL = hassURL
        self.hassToken = hassToken
        self.timeoutInterval = timeoutInterval
    }
    
    func validTokenAsync(forceRefresh: Bool = false) async throws -> String {
        if self.homeAssistantWebSocket == nil {
            self.homeAssistantWebSocket = HomeAssistantWebSocket(hassURL: hassURL, hassToken: self.hassToken, timeoutInterval: self.timeoutInterval)
            try await self.homeAssistantWebSocket?.authenticateSocket()
        }
        // Scenario 2: There is no session Token, create a new one
        if self.hassIngressToken == nil {
            if let hassToken = try await self.homeAssistantWebSocket?.getToken() {
                self.hassIngressToken = hassToken
                self.hassIngressTokenDate = Date()
                return hassToken
            } else {
                // TODO: handle error encoding
                throw APIError.hassError(error: APIError.invalidResponse)
            }
        }
        
        // Scenario 3: The session Token is valid and will be returned
        if let hassIngressToken = self.hassIngressToken, self.hassIngressTokenDate?.distance(to: Date()) ?? 100 < 60, !forceRefresh {
            return hassIngressToken
        }
        
        if let hassToken = try await self.homeAssistantWebSocket?.getToken() {
            self.hassIngressToken = hassToken
            self.hassIngressTokenDate = Date()
            return hassToken
        } else {
            // TODO: handle error encoding
            throw APIError.hassError(error: APIError.invalidResponse)
        }
    }
}
