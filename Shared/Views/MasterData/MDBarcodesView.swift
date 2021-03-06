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
                    Text(LocalizedStringKey("str.md.barcode.info.amount \("\(formatAmount(amount)) \(quIDName ?? String(barcode.quID ?? 0))")"))
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
    
    var productID: Int
    
    @State private var showAddBarcode: Bool = false
    
    @Binding var toastType: MDToastType?
    
    private let dataToUpdate: [ObjectEntities] = [.product_barcodes]
    
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate)
    }
    
    var filteredBarcodes: MDProductBarcodes {
        grocyVM.mdProductBarcodes
            .filter{
                $0.productID == productID
            }
    }
    
    private func delete(at offsets: IndexSet) {
        for offset in offsets {
            grocyVM.deleteMDObject(object: .product_barcodes, id: filteredBarcodes[offset].id, completion: { result in
                switch result {
                case let .success(message):
                    print(message)
                    updateData()
                case let .failure(error):
                    print("\(error)")
                    toastType = .failDelete
                }
            })
        }
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count == 0 {
            bodyContent
        } else {
            ServerOfflineView()
                .navigationTitle(LocalizedStringKey("str.md.barcodes"))
        }
    }
    
    #if os(macOS)
    var bodyContent: some View {
        Section(header: Text(LocalizedStringKey("str.md.barcodes")).font(.headline)) {
            
            Button(action: {showAddBarcode.toggle()}, label: {Image(systemName: MySymbols.new)})
                .popover(isPresented: $showAddBarcode, content: {
                    MDBarcodeFormView(isNewBarcode: true, productID: productID, toastType: $toastType)
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
                .frame(minWidth: 200, minHeight: 400)
            }
        }
        .onAppear(perform: { grocyVM.requestData(objects: dataToUpdate, ignoreCached: false) })
    }
    #elseif os(iOS)
    var bodyContent: some View {
        Form {
            if filteredBarcodes.isEmpty {
                Text(LocalizedStringKey("str.md.barcodes.empty"))
            } else {
                ForEach(filteredBarcodes, id:\.id) {productBarcode in
                    NavigationLink(
                        destination: MDBarcodeFormView(isNewBarcode: false, productID: productID, editBarcode: productBarcode, toastType: $toastType),
                        label: {
                            MDBarcodeRowView(barcode: productBarcode)
                        })
                }.onDelete(perform: delete)
            }
        }
        .navigationTitle(LocalizedStringKey("str.md.barcodes"))
        .onAppear(perform: { grocyVM.requestData(objects: [.product_barcodes], ignoreCached: false) })
        .toolbar(content: {
            ToolbarItem(placement: .automatic, content: {
                Button(action: {showAddBarcode.toggle()}, label: {
                    Label("str.md.barcode.new", systemImage: "plus")
                        .labelStyle(TextIconLabelStyle())
                })
            })
            ToolbarItem(placement: .navigationBarLeading) {
                // Back not shown without it
                Text("")
            }
        })
        .sheet(isPresented: $showAddBarcode, content: {
            NavigationView{
                MDBarcodeFormView(isNewBarcode: true, productID: productID, toastType: $toastType)
            }
        })
    }
    #endif
}

struct MDBarcodesView_Previews: PreviewProvider {
    @StateObject var grocyVM: GrocyViewModel = .shared
    static var previews: some View {
        NavigationView{
            MDBarcodesView(productID: 27, toastType: Binding.constant(nil))
        }
    }
}
