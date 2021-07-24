//
//  MDBatteriesModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 25.01.21.
//

import Foundation

// MARK: - MDBattery
struct MDBattery: Codable {
    let id: Int
    let name: String
    let mdBatteryDescription: String?
    let usedIn: String?
    let chargeIntervalDays: Int
    let active: Int
    let rowCreatedTimestamp: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case mdBatteryDescription = "description"
        case usedIn = "used_in"
        case chargeIntervalDays = "charge_interval_days"
        case active
        case rowCreatedTimestamp = "row_created_timestamp"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.mdBatteryDescription = try? container.decodeIfPresent(String.self, forKey: .mdBatteryDescription) ?? nil
        self.usedIn = try? container.decodeIfPresent(String.self, forKey: .usedIn) ?? nil
        self.chargeIntervalDays = try container.decode(Int.self, forKey: .chargeIntervalDays)
        self.active = try container.decode(Int.self, forKey: .active)
        self.rowCreatedTimestamp = try container.decode(String.self, forKey: .rowCreatedTimestamp)
    }
    
    init(id: Int,
         name: String,
         mdBatteryDescription: String? = nil,
         usedIn: String? = nil,
         chargeIntervalDays: Int,
         active: Int,
         rowCreatedTimestamp: String) {
        self.id = id
        self.name = name
        self.mdBatteryDescription = mdBatteryDescription
        self.usedIn = usedIn
        self.chargeIntervalDays = chargeIntervalDays
        self.active = active
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }
}

typealias MDBatteries = [MDBattery]
