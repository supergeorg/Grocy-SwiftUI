//
//  SystemDBChangedTimeModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 12.10.20.
//

import Foundation

struct SystemDBChangedTime: Codable {
    let changedTime: String

    enum CodingKeys: String, CodingKey {
        case changedTime = "changed_time"
    }
}
