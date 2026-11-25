//
//  MDChoreModelTests.swift
//  Grocy Mobile
//

import Foundation
import Testing

@testable import Grocy_Mobile

@MainActor
@Suite("Chore model")
struct MDChoreModelTests {
    private func chore(periodType: String) throws -> MDChore {
        let json = """
            {"id": 1, "name": "Chore", "period_type": "\(periodType)", "period_days": 3, "track_date_only": 0, "rollover": 0,
             "assignment_type": "no-assignment", "consume_product_on_execution": 0, "period_interval": 1, "active": 1,
             "start_date": "2026-11-01 08:00:00", "row_created_timestamp": "2026-11-01 08:00:00"}
            """
        return try JSONDecoder().decode(MDChore.self, from: Data(json.utf8))
    }

    @Test("Grocy's period types decode", arguments: ChorePeriodType.allCases)
    func knownPeriodTypes(type: ChorePeriodType) throws {
        #expect(try chore(periodType: type.rawValue).periodType == type)
    }

    @Test("An unknown period type decodes as manually instead of crashing")
    func unknownPeriodType() throws {
        #expect(try chore(periodType: "dynamic-regular").periodType == .manually)
    }
}
