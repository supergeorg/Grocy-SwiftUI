//
//  OpenFoodFactsModel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 15.02.21.
//

import Foundation

// MARK: - OpenFoodFactsResult
struct OpenFoodFactsResult: Codable {
    let code: String
    let status: Int
    let product: Product
    let statusVerbose: String
    
    enum CodingKeys: String, CodingKey {
        case code, status, product
        case statusVerbose = "status_verbose"
    }
}

// MARK: - Product (incomplete)
struct Product: Codable {
    let productName: String
    let productNameEn: String?
    let productNameDe: String?
    let productNameFr: String?
    let productNamePl: String?
    let productNameNl: String?
    let imageURL: String?
    let imageThumbURL: String?
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case productNameEn = "product_name_en"
        case productNameDe = "product_name_de"
        case productNameFr = "product_name_fr"
        case productNamePl = "product_name_pl"
        case productNameNl = "product_name_nl"
        case imageURL = "image_url"
        case imageThumbURL = "image_thumb_url"
    }
}
