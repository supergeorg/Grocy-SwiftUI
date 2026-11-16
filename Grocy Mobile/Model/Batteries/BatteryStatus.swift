//
//  BatteryStatus.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import SwiftUI

/// Due states of the batteries overview, as in the Grocy web app (overdue, due today, due soon).
enum BatteryStatus: Identifiable, CaseIterable {
    case all
    case overdue
    case dueToday
    case dueSoon

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .all: return "All"
        case .overdue: return "Overdue"
        case .dueToday: return "Due today"
        case .dueSoon: return "Due soon"
        }
    }

    func getDescription(amount: Int, dueSoonDays: Int? = 5) -> LocalizedStringKey {
        switch self {
        case .overdue:
            return "\(amount) batteries are overdue to be charged"
        case .dueToday:
            return "\(amount) batteries are due to be charged today"
        case .dueSoon:
            return "\(Text("\(amount) batteries are due to be charged")) \(Text("within the next \(dueSoonDays ?? 5) days"))"
        case .all:
            return ""
        }
    }

    var icon: String {
        switch self {
        case .overdue: return MySymbols.overdue
        case .dueToday: return MySymbols.today
        case .dueSoon: return MySymbols.soon
        case .all: return MySymbols.batteries
        }
    }

    /// The status of a battery, using Grocy's rules: only batteries with a charge interval are due,
    /// "due today" lasts until the end of the day, and "due soon" is off when `dueSoonDays` is 0.
    static func status(of battery: Battery, dueSoonDays: Int, now: Date = .now) -> BatteryStatus? {
        guard battery.chargeIntervalDays > 0, let next = battery.nextEstimatedChargeTime else { return nil }
        if next < now {
            return .overdue
        }
        if Calendar.current.isDate(next, inSameDayAs: now) {
            return .dueToday
        }
        if dueSoonDays > 0, let limit = Calendar.current.date(byAdding: .day, value: dueSoonDays, to: now), next <= limit {
            return .dueSoon
        }
        return nil
    }

    /// Whether a battery is shown under this filter. "Due soon" includes the batteries due today, as in Grocy.
    func matches(_ battery: Battery, dueSoonDays: Int, now: Date = .now) -> Bool {
        let status = BatteryStatus.status(of: battery, dueSoonDays: dueSoonDays, now: now)
        switch self {
        case .all: return true
        case .overdue: return status == .overdue
        case .dueToday: return status == .dueToday
        case .dueSoon: return status == .dueSoon || status == .dueToday
        }
    }

    var backgroundColor: Color? {
        switch self {
        case .overdue: return Color(.GrocyColors.grocyRedBackground)
        case .dueToday: return Color(.GrocyColors.grocyBlueBackground)
        case .dueSoon: return Color(.GrocyColors.grocyYellowBackground)
        case .all: return nil
        }
    }

    var color: Color {
        switch self {
        case .overdue: return Color(.GrocyColors.grocyRed)
        case .dueToday: return Color(.GrocyColors.grocyBlue)
        case .dueSoon: return Color(.GrocyColors.grocyYellow)
        case .all: return Color(.GrocyColors.grocyGray)
        }
    }
}
