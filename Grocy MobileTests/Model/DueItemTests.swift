//
//  DueItemTests.swift
//  Grocy Mobile
//

import Foundation
import Testing

@testable import Grocy_Mobile

/// The due tab's badge counts the items without sorting them; it must count the same items as the sorted agenda.
@MainActor
@Suite("Due items")
struct DueItemTests {
    private func tasks(now: Date) -> [GrocyTask] {
        let day: TimeInterval = 24 * 3600
        return [
            GrocyTask(id: 1, name: "Later", dueDate: now.addingTimeInterval(30 * day)),
            GrocyTask(id: 2, name: "Overdue", dueDate: now.addingTimeInterval(-3 * day)),
            GrocyTask(id: 3, name: "Today", dueDate: now),
            GrocyTask(id: 4, name: "Soon", dueDate: now.addingTimeInterval(2 * day)),
            GrocyTask(id: 5, name: "Also overdue", dueDate: now.addingTimeInterval(-1 * day)),
            GrocyTask(id: 6, name: "No date"),
        ]
    }

    private func items(sorted: Bool, tasks: [GrocyTask], now: Date) -> [DueItem] {
        DueItem.items(
            stock: [],
            volatileStock: nil,
            mdProducts: [],
            chores: [],
            tasks: tasks,
            batteries: [],
            userSettings: nil,
            systemConfig: nil,
            now: now,
            sorted: sorted
        )
    }

    @Test("Unsorted items are the same items as the sorted ones")
    func unsortedHasSameItems() {
        let now = Date.now
        let tasks = tasks(now: now)
        let sortedItems = items(sorted: true, tasks: tasks, now: now)
        let unsortedItems = items(sorted: false, tasks: tasks, now: now)
        #expect(Set(sortedItems.map(\.id)) == Set(unsortedItems.map(\.id)))
        #expect(sortedItems.count(where: { $0.urgency.needsAttention }) == unsortedItems.count(where: { $0.urgency.needsAttention }))
        #expect(unsortedItems.count(where: { $0.urgency.needsAttention }) == 3)
    }

    @Test("Sorted items are the most urgent and earliest first")
    func sortedOrder() {
        let now = Date.now
        let names = items(sorted: true, tasks: tasks(now: now), now: now).map(\.name)
        #expect(names == ["Overdue", "Also overdue", "Today", "Soon"])
    }
}
