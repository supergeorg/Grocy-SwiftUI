//
//  MDBarcodesView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 03.12.20.
//

import SwiftUI
import SwiftData

struct MDBarcodesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDProductBarcode.id, order: .forward) var mdProductBarcodes: MDProductBarcodes
    
    @State private var searchString: String = ""
    
    var product: MDProduct
    
    @State private var productBarcodeToDelete: MDProductBarcode? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    @State private var showAddBarcode: Bool = false
    
    private let dataToUpdate: [ObjectEntities] = [.product_barcodes]
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    var productBarcodes: MDProductBarcodes {
        mdProductBarcodes
            .filter {
                $0.productID == product.id
            }
            .sorted(by: { $0.id < $1.id })
    }
    var filteredBarcodes: MDProductBarcodes {
        productBarcodes
            .filter {
                searchString == "" || $0.barcode.contains(searchString)
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
        List {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            } else if productBarcodes.isEmpty {
                ContentUnavailableView("No barcodes found.", systemImage: MySymbols.barcode)
            } else if filteredBarcodes.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(filteredBarcodes, id:\.id) { productBarcode in
                NavigationLink(value: productBarcode, label: {
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
        .navigationTitle("Barcodes")
        .task {
            await updateData()
        }
        .refreshable {
            await updateData()
        }
        .searchable(text: $searchString, prompt: "Search")
        .animation(.default, value: filteredBarcodes.count)
        .toolbar(content: {
            ToolbarItem(placement: .automatic, content: {
                Button(action: {
                    showAddBarcode.toggle()
                }, label: {
                    Label("Add barcode", systemImage: "plus")
                        .labelStyle(.titleAndIcon)
                })
            })
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
        .navigationDestination(isPresented: $showAddBarcode, destination: {
            MDBarcodeFormView(product: product)
        })
        .navigationDestination(for: MDProductBarcode.self, destination: { productBarcode in
            MDBarcodeFormView(product: product, existingBarcode: productBarcode)
        })
    }
}
