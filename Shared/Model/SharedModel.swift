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

enum DefaultStockLabelType: Int, Codable {
    case none = 0
    case singleLabel = 1
    case labelPerUnit = 2
}
