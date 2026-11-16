//
//  BatteryModel.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import Foundation
import SwiftData

/// An active battery with its charge state, from `GET /batteries` (Grocy's `batteries_current` view).
/// The name and "used in" come from the battery the API nests in each entry, so lists can search them directly.
@Model
class Battery: Codable, Equatable, Identifiable {
    @Attribute(.unique) var id: Int
    var batteryID: Int
    var batteryName: String
    var usedIn: String
    var chargeIntervalDays: Int
    var lastTrackedTime: Date?
    /// `nil` when no charge cycle is planned: the charge interval is 0, or the battery was never charged.
    var nextEstimatedChargeTime: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case batteryID = "battery_id"
        case lastTrackedTime = "last_tracked_time"
        case nextEstimatedChargeTime = "next_estimated_charge_time"
        case battery
    }

    enum NestedBatteryKeys: String, CodingKey {
        case name
        case usedIn = "used_in"
        case chargeIntervalDays = "charge_interval_days"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.batteryID = try container.decodeFlexibleInt(forKey: .batteryID)
            self.lastTrackedTime = getDateFromString(try container.decodeIfPresent(String.self, forKey: .lastTrackedTime))
            if let batteryContainer = try? container.nestedContainer(keyedBy: NestedBatteryKeys.self, forKey: .battery) {
                self.batteryName = try batteryContainer.decodeIfPresent(String.self, forKey: .name) ?? ""
                self.usedIn = try batteryContainer.decodeIfPresent(String.self, forKey: .usedIn) ?? ""
                self.chargeIntervalDays = try batteryContainer.decodeFlexibleIntIfPresent(forKey: .chargeIntervalDays) ?? 0
            } else {
                self.batteryName = ""
                self.usedIn = ""
                self.chargeIntervalDays = 0
            }
            // Grocy returns 2999-12-31 when the charge interval is 0, which means "no planned charge cycle".
            let nextTime = getDateFromString(try container.decodeIfPresent(String.self, forKey: .nextEstimatedChargeTime))
            self.nextEstimatedChargeTime = self.chargeIntervalDays > 0 ? nextTime : nil
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(
        id: Int = -1,
        batteryID: Int = 0,
        batteryName: String = "",
        usedIn: String = "",
        chargeIntervalDays: Int = 0,
        lastTrackedTime: Date? = nil,
        nextEstimatedChargeTime: Date? = nil
    ) {
        self.id = id
        self.batteryID = batteryID
        self.batteryName = batteryName
        self.usedIn = usedIn
        self.chargeIntervalDays = chargeIntervalDays
        self.lastTrackedTime = lastTrackedTime
        self.nextEstimatedChargeTime = nextEstimatedChargeTime
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(batteryID, forKey: .batteryID)
        try container.encode(lastTrackedTime, forKey: .lastTrackedTime)
        try container.encode(nextEstimatedChargeTime, forKey: .nextEstimatedChargeTime)
        var batteryContainer = container.nestedContainer(keyedBy: NestedBatteryKeys.self, forKey: .battery)
        try batteryContainer.encode(batteryName, forKey: .name)
        try batteryContainer.encode(usedIn, forKey: .usedIn)
        try batteryContainer.encode(chargeIntervalDays, forKey: .chargeIntervalDays)
    }

    static func == (lhs: Battery, rhs: Battery) -> Bool {
        lhs.id == rhs.id && lhs.batteryID == rhs.batteryID && lhs.batteryName == rhs.batteryName && lhs.usedIn == rhs.usedIn && lhs.chargeIntervalDays == rhs.chargeIntervalDays
            && lhs.lastTrackedTime == rhs.lastTrackedTime && lhs.nextEstimatedChargeTime == rhs.nextEstimatedChargeTime
    }
}

typealias Batteries = [Battery]
