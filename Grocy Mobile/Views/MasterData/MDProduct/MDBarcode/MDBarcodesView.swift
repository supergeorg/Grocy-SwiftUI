//
//  MDBarcodesView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 03.12.20.
//

import SwiftData
import SwiftUI

struct MDBarcodesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext

    @State private var searchString: String = ""

    var product: MDProduct

    @State private var productBarcodeToDelete: MDProductBarcode? = nil
    @State private var showDeleteConfirmation: Bool = false

    @State private var showAddBarcode: Bool = false

    // Fetch the data with a dynamic predicate
    var mdProductBarcodes: MDProductBarcodes {
        let sortDescriptor = SortDescriptor<MDProductBarcode>(\.barcode)
        let predicate =
            #Predicate<MDProductBarcode> { barcode in
                barcode.productID == product.id && (searchString.isEmpty ? true : barcode.barcode.contains(searchString))
            }

        let descriptor = FetchDescriptor<MDProductBarcode>(
            predicate: predicate,
            sortBy: [sortDescriptor],
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var mdProductBarcodesCount: Int {
        var descriptor = FetchDescriptor<MDProductBarcode>(
            predicate: #Predicate<MDProductBarcode> { barcode in
                barcode.productID == product.id
            },
            sortBy: []
        )
        descriptor.fetchLimit = 0
        descriptor.includePendingChanges = false

        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private let dataToUpdate: [ObjectEntities] = [.product_barcodes]

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func deleteItem(itemToDelete: MDProductBarcode) {
        productBarcodeToDelete = itemToDelete
        showDeleteConfirmation.toggle()
    }
    private func deleteProductBarcode(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .product_barcodes, id: toDelID)
            GrocyLogger.info("Deleting barcode was successful.")
            await updateData()
        } catch {
            GrocyLogger.error("Deleting barcode failed. \(error)")
        }
    }

    var body: some View {
        List {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            } else if mdProductBarcodesCount == 0 {
                ContentUnavailableView("No barcodes found.", systemImage: MySymbols.barcode)
            } else if mdProductBarcodes.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(mdProductBarcodes, id: \.id) { productBarcode in
                NavigationLink(
                    value: productBarcode,
                    label: {
                        MDBarcodeRowView(barcode: productBarcode)
                    }
                )
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: true,
                    content: {
                        Button(
                            role: .destructive,
                            action: { deleteItem(itemToDelete: productBarcode) },
                            label: { Label("Delete", systemImage: MySymbols.delete) }
                        )
                    }
                )
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
        .animation(.default, value: mdProductBarcodes.count)
        .toolbar(content: {
            ToolbarItem(
                placement: .automatic,
                content: {
                    Button(
                        action: {
                            showAddBarcode.toggle()
                        },
                        label: {
                            Image(systemName: MySymbols.new)
                        }
                    )
                }
            )
        })
        .alert(
            "Do you really want to delete this barcode?",
            isPresented: $showDeleteConfirmation,
            actions: {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let toDelID = productBarcodeToDelete?.id {
                        Task {
                            await deleteProductBarcode(toDelID: toDelID)
                        }
                    }
                }
            },
            message: { Text(productBarcodeToDelete?.barcode ?? "Name not found") }
        )
        .sheet(
            isPresented: $showAddBarcode,
            content: {
                NavigationStack {
                    MDBarcodeFormView(product: product)
                }
            }
        )
        .navigationDestination(
            for: MDProductBarcode.self,
            destination: { productBarcode in
                MDBarcodeFormView(product: product, existingBarcode: productBarcode)
            }
        )
    }
}
