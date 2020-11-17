//
//  SystemInfoModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 12.10.20.
//

import Foundation

// MARK: - SystemInfo
struct SystemInfo: Codable {
    struct GrocyVersion: Codable {
        let version, releaseDate: String

        enum CodingKeys: String, CodingKey {
            case version = "Version"
            case releaseDate = "ReleaseDate"
        }
    }
    
    let grocyVersion: GrocyVersion
    let phpVersion, sqliteVersion: String

    enum CodingKeys: String, CodingKey {
        case grocyVersion = "grocy_version"
        case phpVersion = "php_version"
        case sqliteVersion = "sqlite_version"
    }
}
