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

enum QSToastType: Identifiable {
    case successQSPurchase, failQSPurchase, successQSOpen, failQSOpen, successQSConsume, failQSConsume, successQSAddProduct, failQSAddProduct, invalidBarcode
    
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
