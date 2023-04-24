//
//  HomeAssistantAPI.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 21.08.21.
//

import Foundation
import Combine

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

class WebSocket: NSObject, URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Web Socket did connect")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Web Socket did disconnect with code \(closeCode)")
    }
}

class HomeAssistantWebSocket {
    private var webSocketTask: URLSessionWebSocketTask
    private var requestID: Int = 1
    private var timeoutInterval: Double
    private var hassToken: String
    private var socketAuthenticated: Bool = false
    
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
    }
    
    func authenticateSocket() async throws {
        // 1. Get data, should show not authorized message
        let authStateMessageNonAuthorized: HomeAssistantSocketAuthState = try await self.receiveData()
        guard authStateMessageNonAuthorized.type == "auth_required" else {
            throw APIError.hassError(error: APIError.invalidResponse)
        }

        // 2. Build auth request
        let authMessage = HomeAssistantSocketAuthRequest(type: "auth", accessToken: hassToken)
        let jsonAuthMessage = try! JSONEncoder().encode(authMessage)
        try await self.sendDataAsString(data: jsonAuthMessage)

        // 3. Get authentication return
        let authStateMessageAuthorized: HomeAssistantSocketAuthState = try await self.receiveData()
        guard authStateMessageAuthorized.type == "auth_ok" else {
            throw APIError.hassError(error: APIError.serverError(errorMessage: "Home Assistant not authorized, state is \(authStateMessageAuthorized.type)"))
        }
        socketAuthenticated = true
    }
    
    func getToken() async throws -> String {
        guard socketAuthenticated == true else {
            throw APIError.internalError
        }
        let tokenRequest = HomeAssistantSocketTokenRequest(id: self.requestID, type: "supervisor/api", endpoint: "/ingress/session", method: "post")
        self.requestID = self.requestID + 1
        let tokenRequestJSON = try JSONEncoder().encode(tokenRequest)
        try await self.sendDataAsString(data: tokenRequestJSON)
        let tokenReturn: HomeAssistantSocketTokenReturn = try await self.receiveData()
        return tokenReturn.result.session
    }
    
    func send(sendStr: String) async throws {
        try await webSocketTask.send(.string(sendStr))
    }
    
    func receiveData<T: Codable>() async throws -> T {
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
        } catch {
            throw APIError.hassError(error: error)
        }
    }
    
    func sendDataAsString(data: Data) async throws {
        // Sending the data as data doesn't work, so it gets sent as string.
        guard self.webSocketTask.state == .running else {
            throw APIError.internalError
        }
        let str = String(decoding: data, as: UTF8.self)
        try await self.webSocketTask.send(.string(str))
    }
}

class HomeAssistantAuthenticator {
    private var hassURL: String = ""
    private var hassToken: String
    
    private var hassIngressToken: String?
    private var hassIngressTokenDate: Date?
    
    private var timeoutInterval: Double = 60.0
    
    private var homeAssistantWebSocket: HomeAssistantWebSocket? = nil
    
    init(hassURL: String, hassToken: String, timeoutInterval: Double = 60) {
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
