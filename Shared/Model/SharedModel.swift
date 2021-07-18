//
//  SharedModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 20.11.20.
//

import Foundation

enum DueType: Int, Codable {
    case bestBefore = 1
    case expires = 2
}

//// https://stackoverflow.com/questions/45090671/convert-received-int-to-bool-decoding-json-using-codable
//@propertyWrapper
//struct SomeKindOfBool: Codable {
//    var wrappedValue: Bool
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.singleValueContainer()
//
//        //Handle String value
//        if let stringValue = try? container.decode(String.self) {
//            switch stringValue.lowercased() {
//            case "false", "no", "0": wrappedValue = false
//            case "true", "yes", "1": wrappedValue = true
//            default: throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expect true/false, yes/no or 0/1 but`\(stringValue)` instead")
//            }
//        }
//
//        //Handle Int value
//        else if let intValue = try? container.decode(Int.self) {
//            switch intValue {
//            case 0: wrappedValue = false
//            case 1: wrappedValue = true
//            default: throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expect `0` or `1` but found `\(intValue)` instead")
//            }
//        }
//
//        else {
//            wrappedValue = try container.decode(Bool.self)
//        }
//    }
//
//    mutating func encode(to encoder: Encoder) throws {
////        try wrappedValue.encode(to: encoder)
//        let container = try encoder.singleValueContainer()
//        try wrappedValue = container.encode("false")
//    }
//}
