//
//  MDBarcodeRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 24.10.23.
//

import SwiftUI

struct MDBarcodeRowView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    var barcode: MDProductBarcode
    
    var body: some View {
        VStack(alignment: .leading){
            Text(barcode.barcode)
                .font(.title)
            HStack{
                if let amount = barcode.amount {
                    Text("Amount: \(amount.formattedAmount) \(grocyVM.mdQuantityUnits.first(where: {$0.id == barcode.quID})?.name ?? String(barcode.quID ?? 0))")
                }
                if let storeName = grocyVM.mdStores.first(where: {$0.id == barcode.storeID})?.name {
                    Text("Store: \(storeName)")
                }
            }.font(.caption)
        }
    }
}

#Preview {
    MDBarcodeRowView(barcode: MDProductBarcode(id: 1, productID: 1, barcode: "123456789", rowCreatedTimestamp: ""))
}
