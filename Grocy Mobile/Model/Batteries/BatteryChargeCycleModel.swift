//
//  BatteryChargeCycleModel.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import Foundation
import SwiftData

/// One tracked charge cycle (`/objects/battery_charge_cycles`), shown in the batteries journal.
@Model
class BatteryChargeCycle: Codable, Equatable, Identifiable {
    @Attribute(.unique) var id: Int
    var batteryID: Int
    var trackedTime: Date?
    var undone: Bool
    var undoneTimestamp: Date?
    var rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case batteryID = "battery_id"
        case trackedTime = "tracked_time"
        case undone
        case undoneTimestamp = "undone_timestamp"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.batteryID = try container.decodeFlexibleInt(forKey: .batteryID)
            self.trackedTime = getDateFromString(try container.decodeIfPresent(String.self, forKey: .trackedTime))
            self.undone = try container.decodeFlexibleBool(forKey: .undone)
            self.undoneTimestamp = getDateFromString(try container.decodeIfPresent(String.self, forKey: .undoneTimestamp))
            self.rowCreatedTimestamp = getDateFromString(try container.decodeIfPresent(String.self, forKey: .rowCreatedTimestamp)) ?? Date()
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(
        id: Int = -1,
        batteryID: Int = -1,
        trackedTime: Date? = Date(),
        undone: Bool = false,
        undoneTimestamp: Date? = nil,
        rowCreatedTimestamp: Date = Date()
    ) {
        self.id = id
        self.batteryID = batteryID
        self.trackedTime = trackedTime
        self.undone = undone
        self.undoneTimestamp = undoneTimestamp
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(batteryID, forKey: .batteryID)
        try container.encode(trackedTime, forKey: .trackedTime)
        try container.encode(undone, forKey: .undone)
        try container.encode(undoneTimestamp, forKey: .undoneTimestamp)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }

    static func == (lhs: BatteryChargeCycle, rhs: BatteryChargeCycle) -> Bool {
        lhs.id == rhs.id && lhs.batteryID == rhs.batteryID && lhs.trackedTime == rhs.trackedTime && lhs.undone == rhs.undone
            && lhs.undoneTimestamp == rhs.undoneTimestamp
            && lhs.rowCreatedTimestamp == rhs.rowCreatedTimestamp
    }
}

typealias BatteryChargeCycles = [BatteryChargeCycle]

/// Request body of `POST /batteries/{batteryId}/charge`.
struct BatteryChargeModel: Codable {
    /// Local time as `Y-m-d H:i:s` (`Date.grocyDateTimeString`); Grocy uses the current time for other formats.
    let trackedTime: String

    enum CodingKeys: String, CodingKey {
        case trackedTime = "tracked_time"
    }
}
