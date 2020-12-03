//
//  MDBarcodesView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 03.12.20.
//

import SwiftUI

struct MDBarcodeRowView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var barcode: MDProductBarcode
    
    var shoppingLocationName: String {
        grocyVM.mdShoppingLocations.first(where: {$0.id == barcode.shoppingLocationID})?.name ?? "ShopID ERROR"
    }
    var quIDName: String {
        grocyVM.mdQuantityUnits.first(where: {$0.id == barcode.quID})?.name ?? "quID ERROR"
    }
    
    var body: some View {
        VStack(alignment: .leading){
            Text(barcode.barcode)
                .font(.title)
            Text(LocalizedStringKey("str.md.barcode.info \("\(barcode.amount) \(quIDName)") \(shoppingLocationName)"))
                .font(.caption)
        }
    }
}

struct MDBarcodesView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var productID: String
    
    @State private var showAddBarcode: Bool = false
    
    private func updateData() {
        grocyVM.getMDProductBarcodes()
    }
    
    var filteredBarcodes: MDProductBarcodes {
        grocyVM.mdProductBarcodes
            .filter{
                $0.productID == productID
            }
    }
    
    var body: some View {
        VStack(alignment: .leading){
            HStack{
                Text("str.md.barcodes")
                Spacer()
                Button("str.add") {
                    showAddBarcode.toggle()
                }
                .popover(isPresented: $showAddBarcode, content: {
                    MDBarcodeFormView(isNewBarcode: true, productID: productID)
                        .padding()
                })
            }
            Spacer()
            ForEach(filteredBarcodes, id:\.id) {productBarcode in
                MDBarcodeRowView(barcode: productBarcode)
            }
        }
        .onAppear(perform: updateData)
    }
}

struct MDBarcodesView_Previews: PreviewProvider {
    static var previews: some View {
        MDBarcodesView(productID: "1")
    }
}
