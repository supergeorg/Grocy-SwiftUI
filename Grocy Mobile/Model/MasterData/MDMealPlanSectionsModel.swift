//
//  MDMealPlanSectionsModel.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import Foundation
import SwiftData

/// A section of a meal plan day, e.g. breakfast, lunch or dinner (`/objects/meal_plan_sections`).
@Model
class MDMealPlanSection: Codable, Equatable, Identifiable {
    /// Grocy's built-in section without a name, used by entries without a section. It can't be edited or deleted.
    nonisolated static let noSectionID = -1

    @Attribute(.unique) var id: Int
    var name: String
    var sortNumber: Int?
    /// A time of day as `HH:mm`, or empty.
    var timeInfo: String
    var rowCreatedTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sortNumber = "sort_number"
        case timeInfo = "time_info"
        case rowCreatedTimestamp = "row_created_timestamp"
    }

    required init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeFlexibleInt(forKey: .id)
            self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
            self.sortNumber = try container.decodeFlexibleIntIfPresent(forKey: .sortNumber)
            self.timeInfo = try container.decodeIfPresent(String.self, forKey: .timeInfo) ?? ""
            self.rowCreatedTimestamp = getDateFromString(try container.decodeIfPresent(String.self, forKey: .rowCreatedTimestamp)) ?? Date()
        } catch {
            throw APIError.decodingError(error: error)
        }
    }

    init(
        id: Int = -1,
        name: String = "",
        sortNumber: Int? = nil,
        timeInfo: String = "",
        rowCreatedTimestamp: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.sortNumber = sortNumber
        self.timeInfo = timeInfo
        self.rowCreatedTimestamp = rowCreatedTimestamp
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(sortNumber, forKey: .sortNumber)
        try container.encode(timeInfo.isEmpty ? nil : timeInfo, forKey: .timeInfo)
    }

    static func == (lhs: MDMealPlanSection, rhs: MDMealPlanSection) -> Bool {
        lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.sortNumber == rhs.sortNumber
            && lhs.timeInfo == rhs.timeInfo
            && lhs.rowCreatedTimestamp == rhs.rowCreatedTimestamp
    }

    var isNoSection: Bool { id == MDMealPlanSection.noSectionID }
}

typealias MDMealPlanSections = [MDMealPlanSection]

extension [MDMealPlanSection] {
    /// In Grocy's order: by sort number (sections without one last), then by name.
    var sortedForMealPlan: [MDMealPlanSection] {
        sorted {
            switch ($0.sortNumber, $1.sortNumber) {
            case (let lhs?, let rhs?) where lhs != rhs: return lhs < rhs
            case (.some, .none): return true
            case (.none, .some): return false
            default: return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
        }
    }
}
