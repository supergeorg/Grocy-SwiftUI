//
//  ToastTypes.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 29.01.21.
//

import Foundation

enum MDToastType: Identifiable {
    case successAdd, failAdd, successEdit, failEdit
    
    var id: Int {
        self.hashValue
    }
}

enum QSToastTypeSuccess: Identifiable {
    case successQSPurchase, successQSOpen, successQSConsume, successQSAddProduct, invalidBarcode
    
    var id: Int {
        self.hashValue
    }
}

enum QSToastTypeFail: Identifiable {
    case failQSPurchase, failQSOpen, failQSConsume, failQSAddProduct
    
    var id: Int {
        self.hashValue
    }
}

enum RowActionToastType: Identifiable {
    case successConsumeOne, successConsumeAll, successOpenOne, successConsumeAllSpoiled, fail
    
    var id: Int {
        self.hashValue
    }
}
