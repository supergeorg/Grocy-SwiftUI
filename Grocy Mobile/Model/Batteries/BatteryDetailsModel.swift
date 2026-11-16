//
//  BatteryDetailsModel.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import Foundation

/// Response of `GET /batteries/{batteryId}`, shown in the battery overview.
/// Not cached in SwiftData: it's fetched each time the overview opens.
struct BatteryDetails: Codable, Equatable {
    var batteryID: Int?
    var lastCharged: Date?
    var chargeCyclesCount: Int
    var nextEstimatedChargeTime: Date?

    enum CodingKeys: String, CodingKey {
        case battery
        case lastCharged = "last_charged"
        case chargeCyclesCount = "charge_cycles_count"
        case nextEstimatedChargeTime = "next_estimated_charge_time"
    }

    enum NestedIDKeys: String, CodingKey {
        case id
    }

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let batteryContainer = try? container.nestedContainer(keyedBy: NestedIDKeys.self, forKey: .battery) {
                self.batteryID = try? batteryContainer.decodeFlexibleInt(forKey: .id)
            } else {
                self.batteryID = nil
            }
            self.lastCharged = getDateFromString(try container.decodeIfPresent(String.self, forKey: .lastCharged))
            self.chargeCyclesCount = try container.decodeFlexibleIntIfPresent(forKey: .chargeCyclesCount) ?? 0
            self.nextEstimatedChargeTime = getDateFromString(try container.decodeIfPresent(String.self, forKey: .nextEstimatedChargeTime))
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(batteryID: Int?, lastCharged: Date? = nil, chargeCyclesCount: Int = 0, nextEstimatedChargeTime: Date? = nil) {
        self.batteryID = batteryID
        self.lastCharged = lastCharged
        self.chargeCyclesCount = chargeCyclesCount
        self.nextEstimatedChargeTime = nextEstimatedChargeTime
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var batteryContainer = container.nestedContainer(keyedBy: NestedIDKeys.self, forKey: .battery)
        try batteryContainer.encode(batteryID, forKey: .id)
        try container.encode(lastCharged, forKey: .lastCharged)
        try container.encode(chargeCyclesCount, forKey: .chargeCyclesCount)
        try container.encode(nextEstimatedChargeTime, forKey: .nextEstimatedChargeTime)
    }
}
