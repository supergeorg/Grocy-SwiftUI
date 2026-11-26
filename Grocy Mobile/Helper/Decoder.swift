//
//  Decoder.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 09.12.25.
//

extension KeyedDecodingContainer {
    nonisolated func decodeFlexibleBool(forKey key: Key) throws -> Bool {
        // Try Bool directly
        if let bool = try? decode(Bool.self, forKey: key) {
            return bool
        }
        // Try Int (0 or 1)
        if let int = try? decode(Int.self, forKey: key) {
            return int == 1
        }
        // Try String ("0", "1", "true", "false")
        if let string = try? decode(String.self, forKey: key) {
            return ["1", "true"].contains(string.lowercased())
        }
        // Fallback to standard decoding error
        return try decode(Bool.self, forKey: key)
    }

    nonisolated func decodeFlexibleBoolIfPresent(forKey key: Key) throws -> Bool? {
        // Try Bool directly
        if let bool = try? decodeIfPresent(Bool.self, forKey: key) {
            return bool
        }
        // Try Int (0 or 1)
        if let int = try? decodeIfPresent(Int.self, forKey: key) {
            return int == 1
        }
        // Try String ("0", "1", "true", "false")
        if let string = try? decodeIfPresent(String.self, forKey: key) {
            return ["1", "true"].contains(string.lowercased())
        }
        return nil
    }

    nonisolated func decodeFlexibleInt(forKey key: Key) throws -> Int {
        // Try Int directly
        if let int = try? decode(Int.self, forKey: key) {
            return int
        }
        // Try String convertible to Int
        if let string = try? decode(String.self, forKey: key), let int = Int(string) {
            return int
        }
        // Try Double (in case it's a decimal number)
        if let double = try? decode(Double.self, forKey: key) {
            return Int(double)
        }
        // Fallback to standard decoding error
        return try decode(Int.self, forKey: key)
    }

    /// An optional reference to another object (a store, a location, a product). Grocy's IDs start at 1, so 0 and -1 mean
    /// "none": older app versions saved -1 for an empty picker, and Grocy stores an empty field as an empty string.
    nonisolated func decodeOptionalIDIfPresent(forKey key: Key) throws -> Int? {
        try decodeFlexibleIntIfPresent(forKey: key).flatMap { $0 > 0 ? $0 : nil }
    }

    nonisolated func decodeFlexibleIntIfPresent(forKey key: Key) throws -> Int? {
        // Try Int directly
        if let int = try? decodeIfPresent(Int.self, forKey: key) {
            return int
        }
        // Try String convertible to Int
        if let string = try? decodeIfPresent(String.self, forKey: key), let int = Int(string) {
            return int
        }
        // Try Double (in case it's a decimal number)
        if let double = try? decodeIfPresent(Double.self, forKey: key) {
            return Int(double)
        }
        return nil
    }

    nonisolated func decodeFlexibleDouble(forKey key: Key) throws -> Double {
        // Try Double directly
        if let double = try? decode(Double.self, forKey: key) {
            return double
        }
        // Try String convertible to Double
        if let string = try? decode(String.self, forKey: key), let double = Double(string) {
            return double
        }
        // Try Int (in case it's sent as integer)
        if let int = try? decode(Int.self, forKey: key) {
            return Double(int)
        }
        // Fallback to standard decoding error
        return try decode(Double.self, forKey: key)
    }

    nonisolated func decodeFlexibleDoubleIfPresent(forKey key: Key) throws -> Double? {
        // Try Double directly
        if let double = try? decodeIfPresent(Double.self, forKey: key) {
            return double
        }
        // Try String convertible to Double
        if let string = try? decodeIfPresent(String.self, forKey: key), let double = Double(string) {
            return double
        }
        // Try Int (in case it's sent as integer)
        if let int = try? decodeIfPresent(Int.self, forKey: key) {
            return Double(int)
        }
        return nil
    }

    nonisolated func decodeFlexibleString(forKey key: Key) throws -> String {
        // Try String directly
        if let str = try? decode(String.self, forKey: key) {
            return str
        }
        // Try Int convertible to String
        if let int = try? decode(Int.self, forKey: key) {
            return String(int)
        }
        // Try Double convertible to String
        if let double = try? decode(Double.self, forKey: key) {
            return String(double)
        }
        // Fallback to standard decoding error
        return try decode(String.self, forKey: key)
    }

    nonisolated func decodeFlexibleEnum<T: RawRepresentable>(
        forKey key: Key,
        default defaultValue: T
    ) throws -> T where T.RawValue: Decodable {
        if let rawValue = try? decode(T.RawValue.self, forKey: key),
            let enumValue = T(rawValue: rawValue)
        {
            return enumValue
        }
        return defaultValue
    }
}
