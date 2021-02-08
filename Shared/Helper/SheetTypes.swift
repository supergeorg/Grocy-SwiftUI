//
//  SheetTypes.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 01.02.21.
//

import Foundation

#if os(iOS)
enum QSActiveSheet: Identifiable {
    case input, selectProduct
    
    var id: Int {
        hashValue
    }
}
#endif
