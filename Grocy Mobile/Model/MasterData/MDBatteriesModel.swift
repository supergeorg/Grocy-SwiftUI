//
//  MDBatteriesModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 25.01.21.
//

import Foundation
import SwiftData

@Model
class MDBattery: Codable, Equatable, Identifiable {
    @Attribute(.unique) var id: Int
    var name: String
    var mdBatteryDescription: String
    var usedIn: String
    var chargeIntervalDays: Int
    var active: Bool
    var rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case mdBatteryDescription = "description"
        case usedIn = "used_in"
        case chargeIntervalDays = "charge_interval_days"
        case active
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.name = try container.decode(String.self, forKey: .name)
            self.mdBatteryDescription = try container.decodeIfPresent(String.self, forKey: .mdBatteryDescription) ?? ""
            self.usedIn = try container.decodeIfPresent(String.self, forKey: .usedIn) ?? ""
            self.chargeIntervalDays = try container.decodeFlexibleIntIfPresent(forKey: .chargeIntervalDays) ?? 0
            self.active = try container.decodeFlexibleBool(forKey: .active)
            self.rowCreatedTimestamp = getDateFromString(try container.decodeIfPresent(String.self, forKey: .rowCreatedTimestamp)) ?? Date()
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(mdBatteryDescription, forKey: .mdBatteryDescription)
        try container.encode(usedIn, forKey: .usedIn)
        try container.encode(chargeIntervalDays, forKey: .chargeIntervalDays)
        try container.encode(active, forKey: .active)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }

    init(
        id: Int = -1,
        name: String = "",
        mdBatteryDescription: String = "",
        usedIn: String = "",
        chargeIntervalDays: Int = 0,
        active: Bool = true,
        rowCreatedTimestamp: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.mdBatteryDescription = mdBatteryDescription
        self.usedIn = usedIn
        self.chargeIntervalDays = chargeIntervalDays
        self.active = active
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }

    static func == (lhs: MDBattery, rhs: MDBattery) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.mdBatteryDescription == rhs.mdBatteryDescription && lhs.usedIn == rhs.usedIn
            && lhs.chargeIntervalDays == rhs.chargeIntervalDays && lhs.active == rhs.active
            && lhs.rowCreatedTimestamp == rhs.rowCreatedTimestamp
    }
}

typealias MDBatteries = [MDBattery]
