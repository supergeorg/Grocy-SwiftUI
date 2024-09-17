//
//  MDProductsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI
import SwiftData

struct MDProductsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        userSettingsList.first
    }
    
    @State private var searchString: String = ""
    @State private var showAddProduct: Bool = false
    @State private var productToDelete: MDProduct? = nil
    @State private var showDeleteConfirmation: Bool = false
    
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
            await grocyVM.postLog("Deleting product was successful.", type: .info)
            await grocyVM.requestData(objects: [.products, .product_barcodes])
        } catch {
            await grocyVM.postLog("Deleting product failed. \(error)", type: .error)
        }
    }
    
    private var filteredProducts: MDProducts {
        mdProducts
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
            .sorted(by: { $0.name < $1.name })
    }
    
    var body: some View {
        List{
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            } else if mdProducts.isEmpty {
                ContentUnavailableView("No products found.", systemImage: MySymbols.product)
            } else if filteredProducts.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(filteredProducts, id:\.id) { product in
                NavigationLink(value: product) {
                    MDProductRowView(product: product)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                    Button(role: .destructive,
                           action: { deleteItem(itemToDelete: product) },
                           label: { Label("Delete", systemImage: MySymbols.delete) }
                    )
                })
            }
        }
        .task {
            await updateData()
        }
        .searchable(text: $searchString, prompt: "Search")
        .refreshable {
            await updateData()
        }
        .animation(.default, value: filteredProducts.count)
        .confirmationDialog("Do you really want to delete this product?", isPresented: $showDeleteConfirmation, actions: {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let toDelID = productToDelete?.id {
                    Task {
                        await deleteProduct(toDelID: toDelID)
                    }
                }
            }
        }, message: { Text(productToDelete?.name ?? "Name not found") })
        .toolbar (content: {
            ToolbarItemGroup(placement: .primaryAction, content: {
#if os(macOS)
                RefreshButton(updateData: { Task { await updateData() } })
#endif
                Button(action: {
                    showAddProduct.toggle()
                }, label: {
                    Image(systemName: MySymbols.new)
                })
            })
        })
        .navigationTitle("Products")
        .navigationDestination(isPresented: $showAddProduct, destination: {
            MDProductFormView(userSettings: userSettings)
        })
        .navigationDestination(for: MDProduct.self, destination: { product in
            MDProductFormView(existingProduct: product, userSettings: userSettings)
        })
    }
}

#Preview {
    MDProductsView()
}
