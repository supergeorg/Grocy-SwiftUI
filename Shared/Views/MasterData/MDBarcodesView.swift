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
    
    var shoppingLocationName: String? {
        grocyVM.mdShoppingLocations.first(where: {$0.id == barcode.shoppingLocationID})?.name
    }
    var quIDName: String? {
        grocyVM.mdQuantityUnits.first(where: {$0.id == barcode.quID})?.name
    }
    
    var body: some View {
        VStack(alignment: .leading){
            Text(barcode.barcode)
                .font(.title)
            HStack{
                if let amount = barcode.amount {
                    Text(LocalizedStringKey("str.md.barcode.info.amount \("\(formatStringAmount(amount)) \(quIDName ?? barcode.quID ?? "noQU")")"))
                }
                if let storeName = shoppingLocationName {
                    Text(LocalizedStringKey("str.md.barcode.info.store \(storeName)"))
                }
            }.font(.caption)
        }
    }
}

struct MDBarcodesView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var productID: String
    
    @State private var showAddBarcode: Bool = false
    
    @Binding var toastType: MDToastType?
    
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
                    MDBarcodeFormView(isNewBarcode: true, productID: productID, toastType: $toastType)
                        .padding()
                })
            if filteredBarcodes.isEmpty {
                Text(LocalizedStringKey("str.md.barcodes.empty"))
            }
            NavigationView{
                List{
                    ForEach(filteredBarcodes, id:\.id) {productBarcode in
                        NavigationLink(
                            destination: ScrollView{
                                MDBarcodeFormView(isNewBarcode: false, productID: productID, editBarcode: productBarcode, toastType: $toastType)
                            },
                            label: {
                                MDBarcodeRowView(barcode: productBarcode)
                            })
                    }.onDelete(perform: delete)
                }
            }
            .frame(width: 400, height: 200)
            #elseif os(iOS)
            Button(action: {showAddBarcode.toggle()}, label: {
                Label("str.md.barcode.new", systemImage: "plus")
            })
            List{
                if filteredBarcodes.isEmpty {
                    Text(LocalizedStringKey("str.md.barcodes.empty"))
                }
                ForEach(filteredBarcodes, id:\.id) {productBarcode in
                    NavigationLink(
                        destination: MDBarcodeFormView(isNewBarcode: false, productID: productID, editBarcode: productBarcode, toastType: $toastType),
                        label: {
                            MDBarcodeRowView(barcode: productBarcode)
                        })
                }.onDelete(perform: delete)
            }
            #endif
        }
        .onAppear(perform: { grocyVM.requestDataIfUnavailable(objects: [.product_barcodes]) })
        .sheet(isPresented: $showAddBarcode, content: {
            NavigationView{
                MDBarcodeFormView(isNewBarcode: true, productID: productID, toastType: $toastType)
            }
        })
    }
}

struct MDBarcodesView_Previews: PreviewProvider {
    @StateObject var grocyVM: GrocyViewModel = .shared
    static var previews: some View {
        Group {
            Form{
                MDBarcodesView(productID: "1", toastType: Binding.constant(nil))
            }
        }
        Group {
            Form{
                MDBarcodesView(productID: "27", toastType: Binding.constant(nil))
            }
        }
    }
}
