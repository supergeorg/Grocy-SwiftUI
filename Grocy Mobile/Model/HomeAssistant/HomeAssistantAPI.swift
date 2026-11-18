//
//  HomeAssistantAPI.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 21.08.21.
//

import Foundation

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

final class WebSocket: NSObject, URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Web Socket did connect")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Web Socket did disconnect with code \(closeCode)")
    }
}

class HomeAssistantWebSocket {
    private var webSocketTask: URLSessionWebSocketTask?
    private var requestID: Int = 1
    private var timeoutInterval: Double
    private var hassToken: String
    private var socketAuthenticated: Bool = false
    private let hassURL: String

    // Reconnection state
    private var reconnectAttempts: Int = 0
    private let maxReconnectAttempts: Int = 5
    private var lastReconnectTime: Date = Date()

    init(hassURL: String, hassToken: String, timeoutInterval: Double) {
        self.hassToken = hassToken
        self.timeoutInterval = timeoutInterval
        self.hassURL = hassURL
        self.webSocketTask = Self.createWebSocketTask(from: hassURL, with: timeoutInterval)
        self.webSocketTask?.resume()
    }

    private static func createWebSocketTask(from hassURL: String, with timeoutInterval: Double) -> URLSessionWebSocketTask {
        let webSocketURL =
            hassURL
            .replacingOccurrences(of: "https", with: "wss")
            .replacingOccurrences(of: "http", with: "ws")
        let webSocketPath = "\(webSocketURL)/api/websocket"
        guard let url = URL(string: webSocketPath) else {
            preconditionFailure("Bad URL")
        }
        let urlRequest = URLRequest(url: url, timeoutInterval: timeoutInterval)
        let session = URLSession(configuration: .default, delegate: WebSocket(), delegateQueue: OperationQueue())
        return session.webSocketTask(with: urlRequest)
    }

    // MARK: - Reconnection Logic

    private func reconnectIfNeeded() async throws {
        guard let task = webSocketTask else {
            try await performReconnect()
            return
        }

        guard task.state != .running else { return }

        try await performReconnect()
    }

    private func performReconnect() async throws {
        reconnectAttempts += 1

        guard reconnectAttempts <= maxReconnectAttempts else {
            throw APIError.hassError(error: APIError.errorString(description: "Web Socket reconnection failed after \(reconnectAttempts) attempts."))
        }

        // Exponential backoff: 1s, 2s, 4s, 8s, 16s
        let backoffDelay = pow(2.0, Double(reconnectAttempts - 1))
        let delay = min(backoffDelay, 16.0)  // Cap at 16 seconds

        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        // Create new WebSocket connection
        let newTask = Self.createWebSocketTask(from: hassURL, with: timeoutInterval)
        newTask.resume()
        self.webSocketTask = newTask

        // Re-authenticate
        socketAuthenticated = false
        try await authenticateSocket()
        reconnectAttempts = 0
    }

    func authenticateSocket() async throws {
        // Ensure WebSocket is running
        try await reconnectIfNeeded()

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
        try await webSocketTask?.send(.string(sendStr))
    }

    func receiveData<T: Codable>() async throws -> T {
        try await reconnectIfNeeded()

        guard let task = webSocketTask, task.state == .running else {
            throw APIError.hassError(error: APIError.errorString(description: "Web Socket not available."))
        }

        let webSocketResult = try await task.receive()
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
    }

    func sendDataAsString(data: Data) async throws {
        // Attempt to reconnect if necessary before sending
        try await reconnectIfNeeded()

        guard let task = webSocketTask, task.state == .running else {
            throw APIError.hassError(error: APIError.errorString(description: "Web Socket unavailable. Retrying..."))
        }
        let str = String(decoding: data, as: UTF8.self)
        try await task.send(.string(str))
    }
}

actor HomeAssistantAuthenticator {
    private var hassURL: String = ""
    private var hassToken: String

    private var hassIngressToken: String?
    private var hassIngressTokenDate: Date?

    private var timeoutInterval: Double = 60.0

    private var homeAssistantWebSocket: HomeAssistantWebSocket?

    init(hassURL: String, hassToken: String, timeoutInterval: Double = 60) {
        self.hassURL = hassURL
        self.hassToken = hassToken
        self.timeoutInterval = timeoutInterval
    }

    func validTokenAsync(forceRefresh: Bool = false) async throws -> String {
        // Create new websocket and authenticate if it doesn't exist yet
        if self.homeAssistantWebSocket == nil {
            self.homeAssistantWebSocket = await HomeAssistantWebSocket(hassURL: hassURL, hassToken: self.hassToken, timeoutInterval: self.timeoutInterval)
            try await self.homeAssistantWebSocket?.authenticateSocket()
        }

        // Scenario 1: The session Token is valid and will be returned
        if let hassIngressToken = self.hassIngressToken,
            let tokenDate = self.hassIngressTokenDate,
            tokenDate.distance(to: Date()) < 60,
            !forceRefresh
        {
            return hassIngressToken
        }

        // Scenario 2: There is no session Token, create a new one
        guard let socket = self.homeAssistantWebSocket else {
            self.homeAssistantWebSocket = await HomeAssistantWebSocket(hassURL: hassURL, hassToken: self.hassToken, timeoutInterval: self.timeoutInterval)
            try await self.homeAssistantWebSocket?.authenticateSocket()
            guard let socket = self.homeAssistantWebSocket else {
                throw APIError.hassError(error: APIError.errorString(description: "Web Socket initialization failed"))
            }
            let hassToken = try await socket.getToken()
            self.hassIngressToken = hassToken
            self.hassIngressTokenDate = Date()
            return hassToken
        }

        let hassToken = try await socket.getToken()
        self.hassIngressToken = hassToken
        self.hassIngressTokenDate = Date()
        return hassToken
    }
}
