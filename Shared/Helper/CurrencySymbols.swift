//
//  CurrencySymbols.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 22.02.21.
//

import Foundation

class CurrencySymbol {
    var code: String
    var symbol: String
    
    init(code: String, symbol: String) {
        self.code = code
        self.symbol = symbol
    }
}

struct CurrencySymbols {
    static let EUR = CurrencySymbol(code: "EUR", symbol: "€")
    static let USD = CurrencySymbol(code: "USD", symbol: "$")
    
    static let symbols = [EUR, USD]
}
