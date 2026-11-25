//
//  ShoppingListNotesTests.swift
//  Grocy Mobile
//

import Foundation
import Testing

@testable import Grocy_Mobile

@MainActor
@Suite("Shopping list notes")
struct ShoppingListNotesTests {
    private func decode(_ json: String) throws -> ShoppingListDescription {
        try JSONDecoder().decode(ShoppingListDescription.self, from: Data(json.utf8))
    }

    @Test("The notes are read from description")
    func decodesNotes() throws {
        let list = try decode(#"{"id":1,"name":"Shopping list","description":"<p>Bring <b>bags</b></p>","row_created_timestamp":"2026-11-25 00:24:35"}"#)
        #expect(list.notes == "<p>Bring <b>bags</b></p>")
    }

    @Test("A list without notes")
    func noNotes() throws {
        #expect(try decode(#"{"id":1,"name":"Shopping list","description":null,"row_created_timestamp":"2026-11-25 00:24:35"}"#).notes == nil)
    }

    @Test("Saving a list doesn't send the notes, so the web's rich text stays as it is")
    func notesAreNotEncoded() throws {
        let data = try JSONEncoder().encode(ShoppingListDescription(id: 1, name: "Shopping list", notes: "<p>Bring bags</p>"))
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["description"] == nil)
        #expect(object["name"] as? String == "Shopping list")
    }
}
