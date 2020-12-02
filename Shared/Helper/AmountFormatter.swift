//
//  AmountFormatter.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 30.11.20.
//

import Foundation

func formatAmount(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    let outStr = formatter.string(from: NSNumber(value: amount))
    return outStr ?? "Format Error"
}
