//
//  GrocyLogger.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.06.25.
//

import OSLog

public enum GrocyLogger {
    private static let logger = Logger(subsystem: "georgappdev.Grocy", category: "AppLogger")

    public static func error(_ message: String) {
        logger.error("\(message)")
    }

    public static func info(_ message: String) {
        logger.info("\(message)")
    }

    public static func debug(_ message: String) {
        logger.debug("\(message)")
    }
}
