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
            Text(LocalizedStringKey("str.md.barcode.info \(barcode.amount != nil ? "\(barcode.amount!) \(quIDName)" : "") \(shoppingLocationName)"))
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

    private func delete(at offsets: IndexSet) {
        for offset in offsets {
            grocyVM.deleteMDObject(object: .product_barcodes, id: filteredBarcodes[offset].id)
            updateData()
        }
    }
    
    var body: some View {
        #if os(iOS)
        content
        #elseif os(macOS)
            content
        #endif
    }
    
    var content: some View {
        Section(header: Text(LocalizedStringKey("str.md.barcodes")).font(.headline)) {
            #if os(macOS)
            Button(action: {showAddBarcode.toggle()}, label: {Image(systemName: "plus")})
                .popover(isPresented: $showAddBarcode, content: {
                    MDBarcodeFormView(isNewBarcode: true, productID: productID)
                        .padding()
                })
            #elseif os(iOS)
            Button(action: {showAddBarcode.toggle()}, label: {
                Label("str.md.barcode.new", systemImage: "plus")
            })
            .sheet(isPresented: $showAddBarcode, content: {
                NavigationView{
                    MDBarcodeFormView(isNewBarcode: true, productID: productID)
                }
            })
            #endif
            List{
                if filteredBarcodes.isEmpty {
                    Text(LocalizedStringKey("str.md.barcodes.empty"))
                }
                ForEach(filteredBarcodes, id:\.id) {productBarcode in
                    NavigationLink(
                        destination: MDBarcodeFormView(isNewBarcode: false, productID: productID, editBarcode: productBarcode),
                        label: {
                            MDBarcodeRowView(barcode: productBarcode)
                        })
                }.onDelete(perform: delete)
            }
        }
        .onAppear(perform: updateData)
    }
}

struct MDBarcodesView_Previews: PreviewProvider {
    @StateObject var grocyVM: GrocyViewModel = .shared
    static var previews: some View {
        Group {
            Form{
                MDBarcodesView(productID: "1")
            }
        }
        Group {
            Form{
                MDBarcodesView(productID: "27")
            }
        }
    }
}
