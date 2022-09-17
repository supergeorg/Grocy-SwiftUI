//
//  ToastTypes.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 29.01.21.
//

import Foundation

enum ToastType: Identifiable {
    case successPurchase,
         failPurchase,
         successOpen,
         failOpen,
         successConsume,
         failConsume,
         successTransfer,
         failTransfer,
         successAdd,
         failAdd,
         successEdit,
         failEdit,
         successDelete,
         failDelete,
         successConsumeOne,
         successConsumeAll,
         successOpenOne,
         successConsumeAllSpoiled,
         successConsumeEntry,
         successOpenEntry,
         shLActionFail
    
    var id: Int {
        self.hashValue
    }
}
