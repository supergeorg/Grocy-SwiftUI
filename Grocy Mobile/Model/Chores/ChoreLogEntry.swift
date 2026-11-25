//
//  ChoreLogEntry.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 11.12.25.
//

import Foundation
import SwiftData

@Model
class ChoreLogEntry: Codable {
    @Attribute(.unique) var id: Int
    var choreID: Int
    var trackedTime: Date?
    var doneByUserID: Int?
    var undone: Bool
    var undoneTimestamp: Date?
    var skipped: Bool
    var scheduledExecutionTime: Date?
    var rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case choreID = "chore_id"
        case trackedTime = "tracked_time"
        case doneByUserID = "done_by_user_id"
        case rowCreatedTimestamp = "row_created_timestamp"
        case undone
        case undoneTimestamp = "undone_timestamp"
        case skipped
        case scheduledExecutionTime = "scheduled_execution_time"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.choreID = try container.decodeFlexibleInt(forKey: .choreID)
            self.trackedTime = getDateFromString(try container.decodeIfPresent(String.self, forKey: .trackedTime))
            self.doneByUserID = try container.decodeFlexibleInt(forKey: .doneByUserID)
            self.undone = try container.decodeFlexibleBool(forKey: .undone)
            self.undoneTimestamp = getDateFromString(try container.decodeIfPresent(String.self, forKey: .undoneTimestamp))
            self.skipped = try container.decodeFlexibleBool(forKey: .skipped)
            self.scheduledExecutionTime = getDateFromString(try container.decodeIfPresent(String.self, forKey: .scheduledExecutionTime))
            self.rowCreatedTimestamp = getDateFromString(try container.decode(String.self, forKey: .rowCreatedTimestamp)) ?? .distantPast
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(
        id: Int = -1,
        choreID: Int = -1,
        trackedTime: Date = Date(),
        doneByUserID: Int = -1,
        undone: Bool = false,
        undoneTimestamp: Date? = nil,
        skipped: Bool = false,
        scheduledExecutionTime: Date? = nil,
        rowCreatedTimestamp: Date = Date(),
    ) {
        self.id = id
        self.choreID = choreID
        self.trackedTime = trackedTime
        self.doneByUserID = doneByUserID
        self.undone = undone
        self.undoneTimestamp = undoneTimestamp
        self.skipped = skipped
        self.scheduledExecutionTime = scheduledExecutionTime
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(choreID, forKey: .choreID)
        try container.encode(trackedTime, forKey: .trackedTime)
        try container.encode(doneByUserID, forKey: .doneByUserID)
        try container.encode(undone, forKey: .undone)
        try container.encode(undoneTimestamp, forKey: .undoneTimestamp)
        try container.encode(skipped, forKey: .skipped)
        try container.encode(scheduledExecutionTime, forKey: .scheduledExecutionTime)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }
}

typealias ChoreLog = [ChoreLogEntry]
