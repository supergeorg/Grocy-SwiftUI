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
    let mdBatteryDescription, used: String?
    let chargeIntervalDays, rowCreatedTimestamp, active: String
//    let userfields: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case mdBatteryDescription = "description"
        case used
        case chargeIntervalDays = "charge_interval_days"
        case rowCreatedTimestamp = "row_created_timestamp"
        case active
//        case userfields
    }
}

typealias MDBatteries = [MDBattery]
