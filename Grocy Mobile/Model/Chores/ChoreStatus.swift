//
//  ChoreStatus.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 11.12.25.
//

import SwiftUI

enum ChoreStatus: Identifiable, CaseIterable {
    case all
    case overdue
    case dueToday
    case dueSoon
    case assignedToMe

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .all: return "All"
        case .overdue: return "Overdue"
        case .dueToday: return "Due today"
        case .dueSoon: return "Due soon"
        case .assignedToMe: return "Assigned to me"
        }
    }

    func getDescription(amount: Int, dueSoonDays: Int? = 5) -> LocalizedStringKey {
        switch self {
        case .overdue:
            return "\(amount) chores are overdue to be done"
        case .dueToday:
            return "\(amount) chores are due to be done today"
        case .dueSoon:
            return "\(Text("\(amount) chores are due to be done")) \(Text("within the next \(dueSoonDays ?? 5) days"))"
        case .assignedToMe:
            return "\(amount) chores are assigned to me"
        default:
            return ""
        }
    }

    var icon: String {
        switch self {
        case .overdue:
            return MySymbols.overdue
        case .dueToday:
            return MySymbols.today
        case .dueSoon:
            return MySymbols.soon
        case .assignedToMe:
            return MySymbols.me
        default:
            return MySymbols.allEntries
        }
    }

    var caseName: String {
        switch self {
        case .all:
            return "all"
        case .overdue:
            return "overdue"
        case .dueToday:
            return "dueToday"
        case .dueSoon:
            return "dueSoon"
        case .assignedToMe:
            return "assignedToMe"
        }
    }

    /// Creates a ChoreStatus from its case name
    static func fromCaseName(_ name: String) -> ChoreStatus? {
        switch name {
        case "all":
            return .all
        case "overdue":
            return .overdue
        case "dueToday":
            return .dueToday
        case "dueSoon":
            return .dueSoon
        case "assignedToMe":
            return .assignedToMe
        default:
            return nil
        }
    }
}
