//
//  ProductStatus.swift
//  grocy-ios
//
//  Created by Georg Meissner on 12.11.20.
//

import Foundation

enum ProductStatus: String {
    case all = "str.stock.all"
    case expiringSoon = "str.stock.expiringSoon"
    case expired = "str.stock.expired"
    case belowMinStock = "str.stock.belowMinStock"
}
