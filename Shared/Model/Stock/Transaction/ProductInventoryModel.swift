//
//  ProductInventoryModel.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 07.12.20.
//

import Foundation

// MARK: - ProductInventory

struct ProductInventory: Codable {
    var newAmount: Double
    var bestBeforeDate: Date
    var storeID: Int?
    var locationID: Int?
    var price: Double?
    var note: String
    
    enum CodingKeys: String, CodingKey {
        case newAmount = "new_amount"
        case bestBeforeDate = "best_before_date"
        case storeID = "shopping_location_id"
        case locationID = "location_id"
        case price
        case note
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(newAmount, forKey: .newAmount)
        try container.encode(bestBeforeDate.asJSONDateString, forKey: .bestBeforeDate)
        try container.encode(storeID, forKey: .storeID)
        try container.encode(locationID, forKey: .locationID)
        try container.encode(price, forKey: .price)
        try container.encode(note.isEmpty ? nil : note, forKey: .note)
    }
    
    init(
        newAmount: Double,
        bestBeforeDate: Date,
        storeID: Int?,
        locationID: Int?,
        price: Double?,
        note: String
    ) {
        self.newAmount = newAmount
        self.bestBeforeDate = bestBeforeDate
        self.storeID = storeID
        self.locationID = locationID
        self.price = price
        self.note = note
    }
}
