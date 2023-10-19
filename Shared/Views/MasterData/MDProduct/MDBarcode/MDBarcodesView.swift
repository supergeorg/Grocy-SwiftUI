//
//  MDBarcodesView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 03.12.20.
//

import SwiftUI
import SwiftData

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
                    Text("Amount: \(amount.formattedAmount) \(quIDName ?? String(barcode.quID ?? 0))")
                }
                if let storeName = storeName {
                    Text("Store: \(storeName)")
                }
            }.font(.caption)
        }
    }
}

struct MDBarcodesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDProductBarcode.id, order: .forward) var mdProductBarcodes: MDProductBarcodes
    
    var productID: Int
    
    @State private var productBarcodeToDelete: MDProductBarcode? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    @State private var showAddBarcode: Bool = false
    
    
    
    private let dataToUpdate: [ObjectEntities] = [.product_barcodes]
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    var filteredBarcodes: MDProductBarcodes {
        mdProductBarcodes
            .filter{
                $0.productID == productID
            }
    }
    
    private func deleteItem(itemToDelete: MDProductBarcode) {
        productBarcodeToDelete = itemToDelete
        showDeleteConfirmation.toggle()
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
                .navigationTitle("Barcodes")
        }
    }
    
#if os(macOS)
    var bodyContent: some View {
        Section(header: Text("Barcodes").font(.headline)) {
            
            Button(action: {showAddBarcode.toggle()}, label: {Image(systemName: MySymbols.new)})
                .popover(isPresented: $showAddBarcode, content: {
                    ScrollView {
                        MDBarcodeFormView(isNewBarcode: true, productID: productID)
                    }
                    .padding()
                })
            if filteredBarcodes.isEmpty {
                Text("No Barcodes added.")
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
                                   label: { Label("Delete", systemImage: MySymbols.delete) }
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
        .alert("Do you really want to delete this barcode?", isPresented: $showDeleteConfirmation, actions: {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
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
                Text("No Barcodes added.")
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
                               label: { Label("Delete", systemImage: MySymbols.delete) }
                        )
                    })
                }
            }
        }
        .navigationTitle("Barcodes")
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
                    Label("Add barcode", systemImage: "plus")
                        .labelStyle(.titleAndIcon)
                })
            })
        })
        .sheet(isPresented: $showAddBarcode, content: {
            NavigationView{
                MDBarcodeFormView(isNewBarcode: true, productID: productID)
            }
        })
        .alert("Do you really want to delete this barcode?", isPresented: $showDeleteConfirmation, actions: {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
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
