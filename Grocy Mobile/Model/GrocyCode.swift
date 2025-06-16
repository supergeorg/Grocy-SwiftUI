//
//  GrocyCode.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 04.12.21.
//

import Foundation

struct GrocyCode {
    let entityType: GCEntityType
    let entityID: Int
    let stockID: String?
    
    enum GCEntityType {
        case product, battery, chore
    }
}
