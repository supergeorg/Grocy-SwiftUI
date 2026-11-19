//
//  DueItem.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftUI

/// How urgent a due item is, and the agenda's section. Each item is in exactly one group (unlike the overview filters,
/// where "due soon" includes "due today").
enum DueUrgency: Int, CaseIterable, Identifiable, Comparable {
    /// Products past their expiration date (not only best before).
    case expired
    case overdue, dueToday, dueSoon
    /// Products below their minimum stock amount. Not time-based, so last.
    case belowMinStock

    var id: Self { self }

    static func < (lhs: DueUrgency, rhs: DueUrgency) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .expired: "Expired"
        case .overdue: "Overdue"
        case .dueToday: "Due today"
        case .dueSoon: "Due soon"
        case .belowMinStock: "Below min. stock"
        }
    }

    var icon: String {
        switch self {
        case .expired: MySymbols.expired
        case .overdue: MySymbols.overdue
        case .dueToday: MySymbols.today
        case .dueSoon: MySymbols.soon
        case .belowMinStock: MySymbols.belowMinStock
        }
    }

    var color: Color {
        switch self {
        case .expired, .overdue: Color(.GrocyColors.grocyRed)
        case .dueToday: Color(.GrocyColors.grocyBlue)
        case .dueSoon: Color(.GrocyColors.grocyYellow)
        case .belowMinStock: Color(.GrocyColors.grocyGray)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .expired, .overdue: Color(.GrocyColors.grocyRedBackground)
        case .dueToday: Color(.GrocyColors.grocyBlueBackground)
        case .dueSoon: Color(.GrocyColors.grocyYellowBackground)
        case .belowMinStock: Color(.GrocyColors.grocyGrayBackground)
        }
    }

    /// Counted in the due tab's badge. "Due soon" and "below min. stock" don't need attention today.
    var needsAttention: Bool {
        switch self {
        case .expired, .overdue, .dueToday: true
        case .dueSoon, .belowMinStock: false
        }
    }

    /// The sections the user collapsed, as comma-separated raw values. All are expanded by default.
    static let collapsedStorageKey = "dueCollapsedSections"

    static func collapsed(from value: String) -> Set<DueUrgency> {
        Set(value.split(separator: ",").compactMap { Int($0).flatMap(DueUrgency.init(rawValue:)) })
    }

    static func encode(collapsed: Set<DueUrgency>) -> String {
        DueUrgency.allCases.filter { collapsed.contains($0) }.map { String($0.rawValue) }.joined(separator: ",")
    }

    /// Day-based, as in the chores and tasks overviews: overdue before today, due soon within `dueSoonDays`.
    static func forDay(of date: Date?, dueSoonDays: Int) -> DueUrgency? {
        guard let days = daysDifference(for: date) else { return nil }
        if days < 0 { return .overdue }
        if days == 0 { return .dueToday }
        return days <= dueSoonDays ? .dueSoon : nil
    }
}

/// What a due item is: an expiring product, a product below its minimum stock amount, a chore, a task or a battery.
enum DueKind: String, CaseIterable, Identifiable {
    case product, belowMinStock, chore, task, battery

    var id: Self { self }

    /// The kinds the user hid from the due agenda, as comma-separated raw values. All kinds are shown by default.
    static let hiddenKindsStorageKey = "dueHiddenKinds"

    static func hiddenKinds(from value: String) -> Set<DueKind> {
        Set(value.split(separator: ",").compactMap { DueKind(rawValue: String($0)) })
    }

    static func encode(hiddenKinds: Set<DueKind>) -> String {
        DueKind.allCases.filter { hiddenKinds.contains($0) }.map(\.rawValue).joined(separator: ",")
    }

    var title: LocalizedStringKey {
        switch self {
        case .product: "Products"
        case .belowMinStock: "Below min. stock"
        case .chore: "Chores"
        case .task: "Tasks"
        case .battery: "Batteries"
        }
    }

    /// The name of one item's kind, shown in the row.
    var singularTitle: LocalizedStringKey {
        switch self {
        case .product, .belowMinStock: "Product"
        case .chore: "Chore"
        case .task: "Task"
        case .battery: "Battery"
        }
    }

    var icon: String {
        switch self {
        case .product: MySymbols.product
        case .belowMinStock: MySymbols.belowMinStock
        case .chore: MySymbols.chores
        case .task: MySymbols.tasks
        case .battery: MySymbols.batteries
        }
    }

    /// The complete list of this kind.
    var place: PhonePlace {
        switch self {
        case .product, .belowMinStock: .stock
        case .chore: .chores
        case .task: .tasks
        case .battery: .batteries
        }
    }
}

/// One entry of the due agenda: a product to use up, a chore to do, a task to complete or a battery to charge.
struct DueItem: Identifiable {
    enum Source {
        case product(StockElement)
        /// `inStock` is nil for a product that isn't in stock at all.
        case belowMinStock(product: MDProduct, inStock: StockElement?, amountMissing: Double)
        case chore(Chore)
        case task(GrocyTask)
        case battery(Battery)
    }

    var source: Source
    /// Products below their minimum stock amount have no date.
    var date: Date?
    var urgency: DueUrgency

    var kind: DueKind {
        switch source {
        case .product: .product
        case .belowMinStock: .belowMinStock
        case .chore: .chore
        case .task: .task
        case .battery: .battery
        }
    }

    /// Products use the stock element's own ID, which changes with every stock sync (the old elements are deleted).
    /// A row keyed only by the product would be kept, and SwiftUI would compare the deleted element with the new one,
    /// which crashes ("backing data was detached").
    var id: String {
        switch source {
        case .product(let element): "product-\(element.id)"
        case .belowMinStock(let product, let inStock, _): "missing-\(product.id)-\(inStock?.id.uuidString ?? "")"
        case .chore(let chore): "chore-\(chore.id)"
        case .task(let task): "task-\(task.id)"
        case .battery(let battery): "battery-\(battery.id)"
        }
    }

    var name: String {
        switch source {
        case .product(let element): element.product?.name ?? ""
        case .belowMinStock(let product, _, _): product.name
        case .chore(let chore): chore.choreName
        case .task(let task): task.name
        case .battery(let battery): battery.batteryName
        }
    }

    /// Everything due within each kind's "due soon" days (from the user settings), most urgent and earliest first.
    /// Done tasks, kinds the server disabled and kinds the user hid are left out.
    ///
    /// Products follow the stock overview (Grocy's volatile stock), so both show the same products.
    static func items(
        stock: [StockElement],
        volatileStock: VolatileStock?,
        mdProducts: [MDProduct],
        chores: [Chore],
        tasks: [GrocyTask],
        batteries: [Battery],
        userSettings: GrocyUserSettings?,
        systemConfig: SystemConfig?,
        hiddenKinds: Set<DueKind> = [],
        now: Date = .now
    ) -> [DueItem] {
        var items: [DueItem] = []
        if systemConfig?.featureFlagStock != false, let volatileStock {
            let stockByProductID = Dictionary(stock.map { ($0.productID, $0) }, uniquingKeysWith: { first, _ in first })
            // Without due date tracking (FEATURE_FLAG_STOCK_BEST_BEFORE_DATE_TRACKING), no product is due.
            if !hiddenKinds.contains(.product), systemConfig?.featureFlagStockBestBeforeDateTracking != false {
                let expiredIDs = Set(volatileStock.expiredProducts.map(\.productID))
                let overdueIDs = Set(volatileStock.overdueProducts.map(\.productID))
                let dueIDs = Set(volatileStock.dueProducts.map(\.productID))
                let dueSoonDays = userSettings?.stockDueSoonDays ?? 5
                for productID in expiredIDs.union(overdueIDs).union(dueIDs) {
                    guard let element = stockByProductID[productID] else { continue }
                    let urgency: DueUrgency
                    if expiredIDs.contains(productID) {
                        urgency = .expired
                    } else if overdueIDs.contains(productID) {
                        urgency = .overdue
                    } else {
                        urgency = DueUrgency.forDay(of: element.bestBeforeDate, dueSoonDays: dueSoonDays) == .dueToday ? .dueToday : .dueSoon
                    }
                    items.append(DueItem(source: .product(element), date: element.bestBeforeDate, urgency: urgency))
                }
            }
            if !hiddenKinds.contains(.belowMinStock) {
                let productsByID = Dictionary(mdProducts.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
                for missing in volatileStock.missingProducts {
                    guard let product = productsByID[missing.productID] else { continue }
                    let source = Source.belowMinStock(product: product, inStock: stockByProductID[missing.productID], amountMissing: missing.amountMissing)
                    items.append(DueItem(source: source, date: nil, urgency: .belowMinStock))
                }
            }
        }
        if systemConfig?.featureFlagChores != false, !hiddenKinds.contains(.chore) {
            let dueSoonDays = userSettings?.choresDueSoonDays ?? 5
            for chore in chores {
                guard let date = chore.nextEstimatedExecutionTime, let urgency = DueUrgency.forDay(of: date, dueSoonDays: dueSoonDays) else { continue }
                items.append(DueItem(source: .chore(chore), date: date, urgency: urgency))
            }
        }
        if systemConfig?.featureFlagTasks != false, !hiddenKinds.contains(.task) {
            let dueSoonDays = userSettings?.tasksDueSoonDays ?? 5
            for task in tasks where !task.done {
                guard let date = task.dueDate, let urgency = DueUrgency.forDay(of: date, dueSoonDays: dueSoonDays) else { continue }
                items.append(DueItem(source: .task(task), date: date, urgency: urgency))
            }
        }
        if systemConfig?.featureFlagBatteries != false, !hiddenKinds.contains(.battery) {
            let dueSoonDays = userSettings?.batteriesDueSoonDays ?? 5
            for battery in batteries {
                // Batteries follow Grocy's own rules (time-based overdue), as in the batteries overview.
                guard let date = battery.nextEstimatedChargeTime, let status = BatteryStatus.status(of: battery, dueSoonDays: dueSoonDays, now: now) else {
                    continue
                }
                let urgency: DueUrgency
                switch status {
                case .overdue: urgency = .overdue
                case .dueToday: urgency = .dueToday
                case .dueSoon: urgency = .dueSoon
                case .all: continue
                }
                items.append(DueItem(source: .battery(battery), date: date, urgency: urgency))
            }
        }
        return items.sorted {
            ($0.urgency, $0.date ?? .distantFuture, $0.name) < ($1.urgency, $1.date ?? .distantFuture, $1.name)
        }
    }
}
