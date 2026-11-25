//
//  TaskModel.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 20.12.25.
//

import Foundation
import SwiftData

@Model
class GrocyTask: Codable, Equatable, Identifiable {
    @Attribute(.unique) var id: Int
    var name: String
    var taskDescription: String
    var dueDate: Date?
    var done: Bool
    var doneTimestamp: Date?
    var categoryID: Int?
    var assignedToUserID: Int?
    var rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case taskDescription = "description"
        case dueDate = "due_date"
        case done
        case doneTimestamp = "done_timestamp"
        case categoryID = "category_id"
        case assignedToUserID = "assigned_to_user_id"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)

            self.name = try container.decode(String.self, forKey: .name)
            self.taskDescription = try container.decodeIfPresent(String.self, forKey: .taskDescription) ?? ""
            self.dueDate = getDateFromString(try container.decodeIfPresent(String.self, forKey: .dueDate))
            self.done = try container.decodeFlexibleBool(forKey: .done)
            self.doneTimestamp = getDateFromString(try container.decodeIfPresent(String.self, forKey: .doneTimestamp))
            self.categoryID = try container.decodeFlexibleIntIfPresent(forKey: .categoryID)
            self.assignedToUserID = try container.decodeFlexibleIntIfPresent(forKey: .assignedToUserID)
            self.rowCreatedTimestamp = getDateFromString(try container.decodeIfPresent(String.self, forKey: .rowCreatedTimestamp)) ?? .distantPast
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(
        id: Int = -1,
        name: String = "",
        taskDescription: String = "",
        dueDate: Date? = nil,
        done: Bool = false,
        doneTimestamp: Date? = nil,
        categoryID: Int? = nil,
        assignedToUserID: Int? = nil,
        rowCreatedTimestamp: Date = Date(),
    ) {
        self.id = id
        self.name = name
        self.taskDescription = taskDescription
        self.dueDate = dueDate
        self.done = done
        self.doneTimestamp = doneTimestamp
        self.categoryID = categoryID
        self.assignedToUserID = assignedToUserID
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(taskDescription, forKey: .taskDescription)
        try container.encode(dueDate, forKey: .dueDate)
        try container.encode(done, forKey: .done)
        try container.encode(doneTimestamp, forKey: .doneTimestamp)
        try container.encode(categoryID, forKey: .categoryID)
        try container.encode(assignedToUserID, forKey: .assignedToUserID)
        try container.encode(rowCreatedTimestamp, forKey: .rowCreatedTimestamp)
    }
}

typealias GrocyTasks = [GrocyTask]
