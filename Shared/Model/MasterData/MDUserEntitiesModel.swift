//
//  MDUserEntityModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 22.01.21.
//

import Foundation

// MARK: - MDUserEntity
struct MDUserEntity: Codable {
    let id, name, caption: String
    let mdUserEntityDescription: String?
    let showInSidebarMenu: String
    let iconCSSClass: String?
    let rowCreatedTimestamp: String
    let userfields: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, caption
        case mdUserEntityDescription = "description"
        case showInSidebarMenu = "show_in_sidebar_menu"
        case iconCSSClass = "icon_css_class"
        case rowCreatedTimestamp = "row_created_timestamp"
        case userfields
    }
}

typealias MDUserEntities = [MDUserEntity]
