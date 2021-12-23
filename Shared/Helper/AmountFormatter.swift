//
//  AmountFormatter.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 30.11.20.
//

import Foundation

extension Double {
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let outStr = formatter.string(from: NSNumber(value: self))
        return outStr ?? "Format Error"
    }
}
