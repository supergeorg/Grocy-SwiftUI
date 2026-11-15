//
//  DeepLinkHandler.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 06.12.25.
//

import Foundation
import SwiftUI

/// The deep links opened by the widgets (see `WidgetDeepLink`).
///
/// - `grocy://stock/filter/<ProductStatus>`
/// - `grocy://shoppinglist` and `grocy://shoppinglist/list/<id>`
/// - `grocy://chores/filter/<ChoreStatus>`
/// - `grocy://tasks/filter/<TaskStatus>`
enum GrocyDeepLink: Equatable {
    case stock(filter: ProductStatus)
    case shoppingList(id: Int?)
    case chores(filter: ChoreStatus)
    case tasks(filter: TaskStatus)

    init?(url: URL) {
        guard url.scheme == "grocy" else { return nil }
        guard let host = url.host else { return nil }

        let pathComponents = url.pathComponents
        let section = pathComponents.count > 1 ? pathComponents[1] : nil
        let value = pathComponents.count > 2 ? pathComponents[2] : nil

        switch (host, section) {
        case ("stock", "filter"):
            guard let value, let status = ProductStatus.fromCaseName(value) else { return nil }
            self = .stock(filter: status)

        case ("shoppinglist", nil):
            self = .shoppingList(id: nil)

        case ("shoppinglist", "list"):
            self = .shoppingList(id: value.flatMap { Int($0) })

        case ("chores", nil):
            self = .chores(filter: .all)

        case ("chores", "filter"):
            guard let value, let status = ChoreStatus.fromCaseName(value) else { return nil }
            self = .chores(filter: status)

        case ("tasks", nil):
            self = .tasks(filter: .all)

        case ("tasks", "filter"):
            guard let value, let status = TaskStatus.fromCaseName(value) else { return nil }
            self = .tasks(filter: status)

        default:
            return nil
        }
    }
}
