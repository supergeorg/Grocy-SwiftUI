//
//  MDUserEntityModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 22.01.21.
//

import Foundation

// MARK: - MDUserEntity

/// A custom entity (`/objects/userentities`). Only kept in memory, not in SwiftData.
struct MDUserEntity: Codable, Equatable, Identifiable {
    let id: Int
    let name: String
    let caption: String
    let mdUserEntityDescription: String?
    let showInSidebarMenu: Int?
    let iconCSSClass: String?
    let rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case caption
        case mdUserEntityDescription = "description"
        case showInSidebarMenu = "show_in_sidebar_menu"
        case iconCSSClass = "icon_css_class"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.name = try container.decode(String.self, forKey: .name)
            self.caption = try container.decode(String.self, forKey: .caption)
            self.mdUserEntityDescription = try? container.decodeIfPresent(String.self, forKey: .mdUserEntityDescription) ?? nil
            self.showInSidebarMenu = try container.decodeFlexibleIntIfPresent(forKey: .showInSidebarMenu)
            self.iconCSSClass = try? container.decodeIfPresent(String.self, forKey: .iconCSSClass) ?? nil
            self.rowCreatedTimestamp = getDateFromString(try container.decode(String.self, forKey: .rowCreatedTimestamp)) ?? Date()
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(
        id: Int = -1,
        name: String = "",
        caption: String = "",
        mdUserEntityDescription: String? = nil,
        showInSidebarMenu: Int? = nil,
        iconCSSClass: String? = nil,
        rowCreatedTimestamp: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.caption = caption
        self.mdUserEntityDescription = mdUserEntityDescription
        self.showInSidebarMenu = showInSidebarMenu
        self.iconCSSClass = iconCSSClass
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }
}

typealias MDUserEntities = [MDUserEntity]
