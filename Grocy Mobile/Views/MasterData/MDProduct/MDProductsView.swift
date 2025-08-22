//
//  MDProductsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftData
import SwiftUI

struct MDProductsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext

    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        userSettingsList.first
    }

    @State private var searchString: String = ""
    @State private var showAddProduct: Bool = false
    @State private var productToDelete: MDProduct? = nil
    @State private var showDeleteConfirmation: Bool = false

    // Fetch the data with a dynamic predicate
    var mdProducts: MDProducts {
        let sortDescriptor = SortDescriptor<MDProduct>(\.name)
        let predicate =
            searchString.isEmpty
            ? nil
            : #Predicate<MDProduct> { store in
                searchString == "" ? true : store.name.localizedStandardContains(searchString)
            }

        let descriptor = FetchDescriptor<MDProduct>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // Get the unfiltered count without fetching any data
    var mdProductsCount: Int {
        var descriptor = FetchDescriptor<MDProduct>(
            sortBy: []
        )
        descriptor.fetchLimit = 0

        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private let dataToUpdate: [ObjectEntities] = [.products, .locations, .product_groups]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func deleteItem(itemToDelete: MDProduct) {
        productToDelete = itemToDelete
        showDeleteConfirmation.toggle()
    }
    private func deleteProduct(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .products, id: toDelID)
            GrocyLogger.info("Deleting product was successful.")
            await grocyVM.requestData(objects: [.products, .product_barcodes])
        } catch {
            GrocyLogger.error("Deleting product failed. \(error)")
        }
    }

    var body: some View {
        List {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            } else if mdProductsCount == 0 {
                ContentUnavailableView("No products found.", systemImage: MySymbols.product)
            } else if mdProducts.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(mdProducts, id: \.id) { product in
                NavigationLink(value: product) {
                    MDProductRowView(product: product)
                }
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: true,
                    content: {
                        Button(
                            role: .destructive,
                            action: { deleteItem(itemToDelete: product) },
                            label: { Label("Delete", systemImage: MySymbols.delete) }
                        )
                    }
                )
            }
        }
        .task {
            await updateData()
        }
        .searchable(text: $searchString, prompt: "Search")
        .refreshable {
            await updateData()
        }
        .animation(
            .default,
            value: mdProducts.count
        )
        .confirmationDialog(
            "Do you really want to delete this product?",
            isPresented: $showDeleteConfirmation,
            actions: {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let toDelID = productToDelete?.id {
                        Task {
                            await deleteProduct(toDelID: toDelID)
                        }
                    }
                }
            },
            message: { Text(productToDelete?.name ?? "Name not found") }
        )
        .toolbar(content: {
            ToolbarItemGroup(
                placement: .primaryAction,
                content: {
                    #if os(macOS)
                        RefreshButton(updateData: { Task { await updateData() } })
                    #endif
                    Button(
                        action: {
                            showAddProduct.toggle()
                        },
                        label: {
                            Image(systemName: MySymbols.new)
                        }
                    )
                }
            )
        })
        .navigationTitle("Products")
        .navigationDestination(
            isPresented: $showAddProduct,
            destination: {
                MDProductFormView(userSettings: userSettings)
            }
        )
        .navigationDestination(
            for: MDProduct.self,
            destination: { product in
                MDProductFormView(existingProduct: product, userSettings: userSettings)
            }
        )
    }
}

#Preview {
    MDProductsView()
}
