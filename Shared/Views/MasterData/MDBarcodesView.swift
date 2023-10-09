//
//  MDBarcodesView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 03.12.20.
//

import SwiftUI

struct MDBarcodeRowView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    var barcode: MDProductBarcode
    
    var storeName: String? {
        grocyVM.mdStores.first(where: {$0.id == barcode.storeID})?.name
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
                    Text(LocalizedStringKey("str.md.barcode.info.amount \("\(amount.formattedAmount) \(quIDName ?? String(barcode.quID ?? 0))")"))
                }
                if let storeName = storeName {
                    Text(LocalizedStringKey("str.md.barcode.info.store \(storeName)"))
                }
            }.font(.caption)
        }
    }
}

struct MDBarcodesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    var productID: Int
    
    @State private var productBarcodeToDelete: MDProductBarcode? = nil
    @State private var showDeleteAlert: Bool = false
    
    @State private var showAddBarcode: Bool = false
    
    
    
    private let dataToUpdate: [ObjectEntities] = [.product_barcodes]
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    var filteredBarcodes: MDProductBarcodes {
        grocyVM.mdProductBarcodes
            .filter{
                $0.productID == productID
            }
    }
    
    private func deleteItem(itemToDelete: MDProductBarcode) {
        productBarcodeToDelete = itemToDelete
        showDeleteAlert.toggle()
    }
    private func deleteProductBarcode(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .product_barcodes, id: toDelID)
            grocyVM.postLog("Deleting barcode was successful.", type: .info)
            await updateData()
        } catch {
            grocyVM.postLog("Deleting barcode failed. \(error)", type: .error)
        }
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count == 0 {
            bodyContent
        } else {
            ServerProblemView()
                .navigationTitle(LocalizedStringKey("str.md.barcodes"))
        }
    }
    
#if os(macOS)
    var bodyContent: some View {
        Section(header: Text(LocalizedStringKey("str.md.barcodes")).font(.headline)) {
            
            Button(action: {showAddBarcode.toggle()}, label: {Image(systemName: MySymbols.new)})
                .popover(isPresented: $showAddBarcode, content: {
                    ScrollView {
                        MDBarcodeFormView(isNewBarcode: true, productID: productID)
                    }
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
                                MDBarcodeFormView(isNewBarcode: false, productID: productID, editBarcode: productBarcode)
                            },
                            label: {
                                MDBarcodeRowView(barcode: productBarcode)
                            })
                        .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                            Button(role: .destructive,
                                   action: { deleteItem(itemToDelete: productBarcode) },
                                   label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) }
                            )
                        })
                    }
                }
                .frame(minWidth: 200, minHeight: 400)
            }
        }
        .task {
            Task {
                await updateData()
            }
        }
        .alert(LocalizedStringKey("str.md.barcode.delete.confirm"), isPresented: $showDeleteAlert, actions: {
            Button("Cancel", role: .cancel) { }
            Button(LocalizedStringKey("str.delete"), role: .destructive) {
                if let toDelID = productBarcodeToDelete?.id {
                    Task {
                        await deleteProductBarcode(toDelID: toDelID)
                    }
                }
            }
        }, message: { Text(productBarcodeToDelete?.barcode ?? "Name not found") })
    }
#elseif os(iOS)
    var bodyContent: some View {
        Form {
            if filteredBarcodes.isEmpty {
                Text(LocalizedStringKey("str.md.barcodes.empty"))
            } else {
                ForEach(filteredBarcodes, id:\.id) {productBarcode in
                    NavigationLink(
                        destination: MDBarcodeFormView(isNewBarcode: false, productID: productID, editBarcode: productBarcode),
                        label: {
                            MDBarcodeRowView(barcode: productBarcode)
                        })
                    .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                        Button(role: .destructive,
                               action: { deleteItem(itemToDelete: productBarcode) },
                               label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) }
                        )
                    })
                }
            }
        }
        .navigationTitle(LocalizedStringKey("str.md.barcodes"))
        .task {
            Task {
                await updateData()
            }
        }
        .refreshable {
            await updateData()
        }
        .animation(.default, value: filteredBarcodes.count)
        .toolbar(content: {
            ToolbarItem(placement: .automatic, content: {
                Button(action: {showAddBarcode.toggle()}, label: {
                    Label("str.md.barcode.new", systemImage: "plus")
                        .labelStyle(.titleAndIcon)
                })
            })
        })
        .sheet(isPresented: $showAddBarcode, content: {
            NavigationView{
                MDBarcodeFormView(isNewBarcode: true, productID: productID)
            }
        })
        .alert(LocalizedStringKey("str.md.barcode.delete.confirm"), isPresented: $showDeleteAlert, actions: {
            Button("Cancel", role: .cancel) { }
            Button(LocalizedStringKey("str.delete"), role: .destructive) {
                if let toDelID = productBarcodeToDelete?.id {
                    Task {
                        await deleteProductBarcode(toDelID: toDelID)
                    }
                }
            }
        }, message: { Text(productBarcodeToDelete?.barcode ?? "Name not found") })
    }
#endif
}

struct MDBarcodesView_Previews: PreviewProvider {
    @Environment(GrocyViewModel.self) private var grocyVM
    static var previews: some View {
        NavigationView{
            MDBarcodesView(productID: 27)
        }
    }
}
