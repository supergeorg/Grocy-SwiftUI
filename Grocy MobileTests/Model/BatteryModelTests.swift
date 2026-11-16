//
//  BatteryModelTests.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import Foundation
import SwiftData
import Testing

@testable import Grocy_Mobile

@MainActor
@Suite("Batteries and equipment models")
struct BatteryModelTests {
    let context: ModelContext

    init() {
        context = ModelContext(PreviewContainer.shared)
    }

    @Test("Preview fixtures decode into SwiftData")
    func fixturesDecode() throws {
        #expect(try context.fetchCount(FetchDescriptor<MDBattery>()) > 0)
        #expect(try context.fetchCount(FetchDescriptor<Battery>()) > 0)
        #expect(try context.fetchCount(FetchDescriptor<BatteryChargeCycle>()) > 0)
        #expect(try context.fetchCount(FetchDescriptor<MDEquipment>()) > 0)
    }

    @Test("The current battery takes its name from the nested battery")
    func currentBatteryUsesNestedBattery() throws {
        let json = """
            {"id": 3, "battery_id": 3, "last_tracked_time": "2025-09-22 20:37:49", "next_estimated_charge_time": "2025-11-21 20:37:49",
             "battery": {"id": 3, "name": "Battery3", "used_in": "Heat remote control", "charge_interval_days": "60", "active": 1}}
            """
        let battery = try JSONDecoder().decode(Battery.self, from: Data(json.utf8))
        #expect(battery.batteryName == "Battery3")
        #expect(battery.usedIn == "Heat remote control")
        #expect(battery.chargeIntervalDays == 60)
        #expect(battery.nextEstimatedChargeTime != nil)
    }

    @Test("A charge interval of 0 means no planned charge cycle")
    func noIntervalHasNoNextChargeCycle() throws {
        let json = """
            {"id": 2, "battery_id": 2, "last_tracked_time": "2025-10-07 20:37:49", "next_estimated_charge_time": "2999-12-31 23:59:59",
             "battery": {"id": 2, "name": "Battery2", "used_in": "Alarm clock", "charge_interval_days": 0, "active": 1}}
            """
        let battery = try JSONDecoder().decode(Battery.self, from: Data(json.utf8))
        #expect(battery.nextEstimatedChargeTime == nil)
        #expect(BatteryStatus.status(of: battery, dueSoonDays: 5) == nil)
    }

    @Test("Battery details decode the nested battery ID")
    func batteryDetailsDecode() throws {
        let json = """
            {"battery": {"id": "1", "name": "Battery1"}, "last_charged": "2025-05-30 23:59:59", "charge_cycles_count": 4,
             "next_estimated_charge_time": "2025-11-26 23:59:59"}
            """
        let details = try JSONDecoder().decode(BatteryDetails.self, from: Data(json.utf8))
        #expect(details.batteryID == 1)
        #expect(details.chargeCyclesCount == 4)
        #expect(details.lastCharged != nil)
    }

    @Test(
        "Due status follows Grocy's rules",
        arguments: [
            (-2, BatteryStatus.overdue),
            (0, BatteryStatus.dueToday),
            (3, BatteryStatus.dueSoon),
            (10, nil),
        ] as [(Int, BatteryStatus?)]
    )
    func dueStatus(daysFromNow: Int, expected: BatteryStatus?) {
        // Noon, so "today" plus an hour is still the same day.
        let now = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now) ?? .now
        let offset = daysFromNow == 0 ? 3600 : TimeInterval(daysFromNow * 86400)
        let battery = Battery(batteryName: "Battery", chargeIntervalDays: 30, nextEstimatedChargeTime: now.addingTimeInterval(offset))
        #expect(BatteryStatus.status(of: battery, dueSoonDays: 5, now: now) == expected)
    }

    @Test("Due soon is off with 0 days and includes batteries due today")
    func dueSoonFilter() {
        let now = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now) ?? .now
        let inThreeDays = Battery(batteryName: "Soon", chargeIntervalDays: 30, nextEstimatedChargeTime: now.addingTimeInterval(3 * 86400))
        let today = Battery(batteryName: "Today", chargeIntervalDays: 30, nextEstimatedChargeTime: now.addingTimeInterval(3600))
        #expect(BatteryStatus.status(of: inThreeDays, dueSoonDays: 0, now: now) == nil)
        #expect(BatteryStatus.dueSoon.matches(today, dueSoonDays: 5, now: now))
    }

    @Test("Tracked times use the format Grocy accepts")
    func trackedTimeFormat() throws {
        let date = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 4, hour: 5, minute: 6, second: 7)))
        #expect(date.grocyDateTimeString == "2026-03-04 05:06:07")
    }

    @Test("Equipment without a manual has no file name")
    func equipmentWithoutManual() throws {
        let json = """
            {"id": 2, "name": "Dishwasher", "description": "", "instruction_manual_file_name": "", "row_created_timestamp": "2025-11-26 20:37:48"}
            """
        let equipment = try JSONDecoder().decode(MDEquipment.self, from: Data(json.utf8))
        #expect(equipment.instructionManualFileName == nil)
    }
}
