//
//  HomeAssistantSocketMessages.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 24.04.23.
//

import Foundation

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
