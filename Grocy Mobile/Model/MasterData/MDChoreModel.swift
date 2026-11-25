//
//  ChoreModel.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 09.12.25.
//

import Foundation
import SwiftData

@Model
class MDChore: Codable, Equatable, Identifiable {
    @Attribute(.unique) var id: Int
    var name: String
    var mdChoreDescription: String
    var periodType: ChorePeriodType
    var periodDays: Int?
    var periodConfig: String?
    var trackDateOnly: Bool
    var rollover: Bool
    var assignmentType: ChoreAssignmentType
    var assignmentConfig: String?
    var nextExecutionAssignedToUserID: Int?
    var consumeProductOnExecution: Bool
    var productID: Int?
    var productAmount: Double?
    var periodInterval: Int
    var active: Bool
    var startDate: Date
    var rescheduledDate: Date?
    var rescheduledNextExecutionAssignedToUserID: Int?
    var rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case choreDescription = "description"
        case periodType = "period_type"
        case periodDays = "period_days"
        case rowCreatedTimestamp = "row_created_timestamp"
        case periodConfig = "period_config"
        case trackDateOnly = "track_date_only"
        case rollover
        case assignmentType = "assignment_type"
        case assignmentConfig = "assignment_config"
        case nextExecutionAssignedToUserID = "next_execution_assigned_to_user_id"
        case consumeProductOnExecution = "consume_product_on_execution"
        case productID = "product_id"
        case productAmount = "product_amount"
        case periodInterval = "period_interval"
        case active
        case startDate = "start_date"
        case rescheduledDate = "rescheduled_date"
        case rescheduledNextExecutionAssignedToUserID = "rescheduled_next_execution_assigned_to_user_id"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.name = try container.decode(String.self, forKey: .name)
            self.mdChoreDescription = try container.decodeIfPresent(String.self, forKey: .choreDescription) ?? ""
            self.periodType = ChorePeriodType(rawValue: try container.decode(String.self, forKey: .periodType))!
            self.periodDays = try container.decodeFlexibleIntIfPresent(forKey: .periodDays)
            self.periodConfig = try container.decodeIfPresent(String.self, forKey: .periodConfig)
            self.trackDateOnly = try container.decodeFlexibleBool(forKey: .trackDateOnly)
            self.rollover = try container.decodeFlexibleBool(forKey: .rollover)
            self.assignmentType = try container.decodeFlexibleEnum(forKey: .assignmentType, default: ChoreAssignmentType.random)
            self.assignmentConfig = try container.decodeIfPresent(String.self, forKey: .assignmentConfig)
            self.nextExecutionAssignedToUserID = try container.decodeFlexibleIntIfPresent(forKey: .nextExecutionAssignedToUserID)
            self.consumeProductOnExecution = try container.decodeFlexibleBool(forKey: .consumeProductOnExecution)
            self.productID = try container.decodeFlexibleIntIfPresent(forKey: .productID)
            self.productAmount = try container.decodeFlexibleDoubleIfPresent(forKey: .productAmount)
            self.periodInterval = try container.decodeFlexibleInt(forKey: .periodInterval)
            self.active = try container.decodeFlexibleBool(forKey: .active)
            self.startDate = getDateFromString(try container.decode(String.self, forKey: .startDate))!
            self.rescheduledDate = getDateFromString(try container.decodeIfPresent(String.self, forKey: .rescheduledDate) ?? "")
            self.rescheduledNextExecutionAssignedToUserID = try container.decodeFlexibleIntIfPresent(forKey: .rescheduledNextExecutionAssignedToUserID)
            self.rowCreatedTimestamp = getDateFromString(try container.decode(String.self, forKey: .rowCreatedTimestamp)) ?? .distantPast
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(mdChoreDescription, forKey: .choreDescription)
        try container.encode(periodType.rawValue, forKey: .periodType)
        try container.encode(periodDays, forKey: .periodDays)
        try container.encode(periodConfig, forKey: .periodConfig)
        try container.encode(trackDateOnly, forKey: .trackDateOnly)
        try container.encode(rollover, forKey: .rollover)
        try container.encode(assignmentType.rawValue, forKey: .assignmentType)
        try container.encode(assignmentConfig, forKey: .assignmentConfig)
        try container.encode(nextExecutionAssignedToUserID, forKey: .nextExecutionAssignedToUserID)
        try container.encode(consumeProductOnExecution, forKey: .consumeProductOnExecution)
        try container.encode(productID, forKey: .productID)
        try container.encode(productAmount, forKey: .productAmount)
        try container.encode(periodInterval, forKey: .periodInterval)
        try container.encode(assignmentConfig, forKey: .assignmentConfig)
        try container.encode(active, forKey: .active)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(rescheduledDate, forKey: .rescheduledDate)
        try container.encode(rescheduledNextExecutionAssignedToUserID, forKey: .rescheduledNextExecutionAssignedToUserID)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }

    init(
        id: Int = -1,
        name: String = "",
        choreDescription: String = "",
        periodType: ChorePeriodType = ChorePeriodType.hourly,
        periodDays: Int? = 0,
        periodConfig: String? = nil,
        trackDateOnly: Bool = false,
        rollover: Bool = false,
        assignmentType: ChoreAssignmentType = ChoreAssignmentType.inAlphabeticalOrder,
        assignmentConfig: String? = nil,
        nextExecutionAssignedToUserID: Int? = nil,
        consumeProductOnExecution: Bool = false,
        productID: Int? = nil,
        productAmount: Double? = nil,
        periodInterval: Int = 1,
        active: Bool = true,
        startDate: Date = Date(),
        rescheduledDate: Date? = nil,
        rescheduledNextExecutionAssignedToUserID: Int? = nil,
        rowCreatedTimestamp: Date = Date(),
    ) {
        self.id = id
        self.name = name
        self.mdChoreDescription = choreDescription
        self.periodType = periodType
        self.periodDays = periodDays
        self.periodConfig = periodConfig
        self.trackDateOnly = trackDateOnly
        self.rollover = rollover
        self.assignmentType = assignmentType
        self.assignmentConfig = assignmentConfig
        self.nextExecutionAssignedToUserID = nextExecutionAssignedToUserID
        self.consumeProductOnExecution = consumeProductOnExecution
        self.productID = productID
        self.productAmount = productAmount
        self.periodInterval = periodInterval
        self.active = active
        self.startDate = startDate
        self.rescheduledDate = rescheduledDate
        self.rescheduledNextExecutionAssignedToUserID = rescheduledNextExecutionAssignedToUserID
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }
}

typealias MDChores = [MDChore]
