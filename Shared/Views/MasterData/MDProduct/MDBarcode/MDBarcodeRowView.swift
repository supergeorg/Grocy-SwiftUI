//
//  MDBarcodeRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 24.10.23.
//

import SwiftUI
import SwiftData

struct MDBarcodeRowView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \MDStore.name, order: .forward) var mdStores: MDStores
    
    var barcode: MDProductBarcode
    
    var body: some View {
        VStack(alignment: .leading){
            Text(barcode.barcode)
                .font(.title)
            HStack{
                if let amount = barcode.amount {
                    Text("Amount") + Text(": \(amount.formattedAmount) \(mdQuantityUnits.first(where: {$0.id == barcode.quID})?.name ?? String(barcode.quID ?? 0))")
                }
                if let storeName = mdStores.first(where: {$0.id == barcode.storeID})?.name {
                    Text("Store") + Text(": \(storeName)")
                }
            }.font(.caption)
        }
    }
}

#Preview {
    MDBarcodeRowView(barcode: MDProductBarcode(id: 1, productID: 1, barcode: "123456789", rowCreatedTimestamp: ""))
}
