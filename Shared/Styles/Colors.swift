//
//  Colors.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Color {
    static let grocyYellow = Color(red: 228 / 255, green: 174 / 255, blue: 47 / 255)
    static let grocyYellowLight = Color(red: 255 / 255, green: 250 / 255, blue: 229 / 255)
    static let grocyYellowDark = Color(red: 105 / 255, green: 77 / 255, blue: 1 / 255)
    static let grocyRed = Color(red: 172 / 255, green: 16 / 255, blue: 24 / 255)
    static let grocyRedLight = Color(red: 255 / 255, green: 233 / 255, blue: 233 / 255)
    static let grocyRedDark = Color(red: 101 / 255, green: 0 / 255, blue: 5 / 255)
    static let grocyBlue = Color(red: 58 / 255, green: 74 / 255, blue: 170 / 255)
    static let grocyBlueLight = Color(red: 216 / 255, green: 225 / 255, blue: 248 / 255)
    static let grocyBlueDark = Color(red: 33 / 255, green: 37 / 255, blue: 123 / 255)
}

extension Color {
    static let systemGray6 = Color(red: 242 / 255, green: 242 / 255, blue: 247 / 255)
}
