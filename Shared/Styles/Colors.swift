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
    static let grocyGray = Color(red: 85 / 255, green: 86 / 255, blue: 88 / 255)
    static let grocyGrayLight = Color(red: 218 / 255, green: 221 / 255, blue: 227 / 255)
    static let grocyGrayDark = Color(red: 61 / 255, green: 69 / 255, blue: 77 / 255)
    
    static let grocyTurquoise = Color(red: 17 / 255, green: 145 / 255, blue: 171 / 255)
    
    static let grocyDelete = Color(red: 212 / 255, green: 27 / 255, blue: 50 / 255)
    static let grocyDeleteLocked = Color(red: 221 / 255, green: 95 / 255, blue: 110 / 255)
    static let grocyGreen = Color(red: 31 / 255, green: 156 / 255, blue: 49 / 255)
    static let grocyGreenLocked = Color(red: 74 / 255, green: 179 / 255, blue: 106 / 255)
}

extension Color {
    static let systemGray6 = Color(red: 242 / 255, green: 242 / 255, blue: 247 / 255)
}
