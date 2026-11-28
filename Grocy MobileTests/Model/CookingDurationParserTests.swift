//
//  CookingDurationParserTests.swift
//  Grocy MobileTests
//
//  Created by Georg Meißner on 28.11.26.
//

import Testing

@testable import Grocy_Mobile

@Suite("Times in cooking steps")
struct CookingDurationParserTests {
    private func seconds(in text: String) -> [Double] {
        CookingDurationParser.durations(in: text).map(\.seconds)
    }

    @Test(
        "Digits and units",
        arguments: [
            ("Bake for 25 minutes.", 1500.0),
            ("Im Ofen 25 Minuten backen.", 1500),
            ("Ca. 10 Min. ziehen lassen", 600),
            ("Cook 2 h", 7200),
            ("1,5 Stunden schmoren", 5400),
            ("1½ hours", 5400),
            ("30 Sekunden pürieren", 30),
            ("Rest 45 secs", 45),
        ]
    )
    func digits(text: String, expected: Double) {
        #expect(seconds(in: text) == [expected])
    }

    @Test(
        "Number words and phrases",
        arguments: [
            ("Fünf Minuten köcheln lassen.", 300.0),
            ("eine Stunde gehen lassen", 3600),
            ("Simmer for ten minutes", 600),
            ("Eine halbe Stunde ruhen lassen", 1800),
            ("Leave for half an hour", 1800),
            ("Eine Viertelstunde quellen lassen", 900),
            ("Anderthalb Stunden garen", 5400),
            ("a minute more", 60),
        ]
    )
    func words(text: String, expected: Double) {
        #expect(seconds(in: text) == [expected])
    }

    @Test("A range is the shorter time, and keeps the longer one")
    func range() throws {
        let durations = CookingDurationParser.durations(in: "Backen, 20-25 Minuten, dann 10 bis 12 min ruhen")
        #expect(durations.map(\.seconds) == [1200, 600])
        #expect(durations.map(\.upperSeconds) == [1500, 720])
        let first = try #require(durations.first)
        #expect(first.text == "20-25 Minuten")
    }

    @Test("Hours and minutes together are one time")
    func hoursAndMinutes() {
        #expect(seconds(in: "1 Stunde 30 Minuten schmoren") == [5400])
        #expect(seconds(in: "Braise for 2 hours and 15 minutes") == [8100])
    }

    @Test("Several times in one step")
    func several() {
        #expect(seconds(in: "Zuerst 5 Minuten anbraten, dann 1 Stunde schmoren und 10 Minuten ruhen lassen.") == [300, 3600, 600])
    }

    @Test(
        "Text that isn't a time",
        arguments: [
            "Add a handful of herbs.",
            "200 g Mehl und 3 Eier",
            "Minuten und Stunden",
            "Die Hähnchenbrust in Streifen schneiden",
            "Mit 2 EL Öl beträufeln",
            "a h",
        ]
    )
    func noTime(text: String) {
        #expect(CookingDurationParser.durations(in: text).isEmpty)
    }
}
