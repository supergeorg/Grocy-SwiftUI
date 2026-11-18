//
//  ServerProfileModel.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.25.
//

import Foundation
import SwiftData

@Model
final class LoginCustomHeader {
    var id: UUID = UUID()
    var headerName: String = ""
    var headerValue: String = ""
    var serverProfile: ServerProfile?

    init(headerName: String, headerValue: String) {
        self.id = UUID()
        self.headerName = headerName
        self.headerValue = headerValue
    }
}

@Model
final class ServerProfile {
    var id: UUID = UUID()
    var name: String = ""
    var grocyServerURL: String = ""
    var grocyAPIKey: String = ""
    var useHassIngress: Bool = false
    var hassToken: String = ""
    @Relationship(deleteRule: .cascade, inverse: \LoginCustomHeader.serverProfile) var customHeaders: [LoginCustomHeader]? = nil
    var userName: String = ""
    var displayName: String = ""
    @Attribute(.externalStorage) var profilePicture: Data?

    init(
        name: String = "",
        grocyServerURL: String = "",
        grocyAPIKey: String = "",
        useHassIngress: Bool = false,
        hassToken: String = "",
        customHeaders: [LoginCustomHeader] = [],
        userName: String = "",
        displayName: String = "",
        profilePicture: Data? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.grocyServerURL = grocyServerURL
        self.grocyAPIKey = grocyAPIKey
        self.useHassIngress = useHassIngress
        self.hassToken = hassToken
        self.customHeaders = customHeaders
        self.userName = userName
        self.displayName = displayName
        self.profilePicture = profilePicture
    }
}
