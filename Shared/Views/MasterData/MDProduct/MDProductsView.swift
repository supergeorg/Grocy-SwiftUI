//
//  MDProductsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI
import SwiftData

struct MDProductRowView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDLocation.id, order: .forward) var mdLocations: MDLocations
    @Query(sort: \MDProductGroup.id, order: .forward) var mdProductGroups: MDProductGroups
    
    var product: MDProduct
    
    @State private var productDescription: AttributedString? = nil
    
    var body: some View {
        HStack{
            if let pictureFileName = product.pictureFileName {
                PictureView(pictureFileName: pictureFileName, pictureType: .productPictures, maxWidth: 75.0, maxHeight: 75.0)
            }
            VStack(alignment: .leading) {
                Text(product.name)
                    .font(.title)
                    .foregroundStyle(product.active ? .primary : .secondary)
                HStack(alignment: .top){
                    if let locationID = mdLocations.firstIndex(where: { $0.id == product.locationID }) {
                        Text("Location: \(mdLocations[locationID].name)")
                            .font(.caption)
                    }
                    if let productGroup = mdProductGroups.firstIndex(where: { $0.id == product.productGroupID }) {
                        Text("Product group: \(mdProductGroups[productGroup].name)")
                            .font(.caption)
                    }
                }
                if let description = productDescription, !description.description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .italic()
                }
            }
            .task {
                productDescription = await grocyVM.getAttributedStringFromHTML(htmlString: product.mdProductDescription)
            }
        }
    }
}

struct MDProductsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDProduct.id, order: .forward) var mdProducts: MDProducts
    
    @State private var firstAppear: Bool = true
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
            grocyVM.postLog("Deleting product was successful.", type: .info)
            await grocyVM.requestData(objects: [.products, .product_barcodes])
        } catch {
            grocyVM.postLog("Deleting product failed. \(error)", type: .error)
        }
    }
    
    private var filteredProducts: MDProducts {
        mdProducts
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter( {dataToUpdate.contains($0) }).count == 0 {
#if os(macOS)
            NavigationView{
                bodyContent
                    .frame(minWidth: Constants.macOSNavWidth)
            }
#else
            bodyContent
#endif
        } else {
            ServerProblemView()
                .navigationTitle("Products")
        }
    }
    
    var bodyContent: some View {
        content
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
#if os(iOS)
            .sheet(isPresented: $showAddProduct, content: {
                NavigationView {
                    MDProductFormView(isNewProduct: true, showAddProduct: $showAddProduct)
                }
            })
#endif
    }
    
    var content: some View {
        List{
            if mdProducts.isEmpty {
                ContentUnavailableView("No products found.", systemImage: MySymbols.product)
            } else if filteredProducts.isEmpty {
                ContentUnavailableView.search
            }
#if os(macOS)
            if showAddProduct {
                NavigationLink(destination: MDProductFormView(isNewProduct: true, showAddProduct: $showAddProduct), isActive: $showAddProduct, label: {
                    NewMDRowLabel(title: "Create product")
                })
            }
#endif
            ForEach(filteredProducts, id:\.id) { product in
                NavigationLink(destination: MDProductFormView(isNewProduct: false, product: product, showAddProduct: Binding.constant(false))) {
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
            if firstAppear {
                await updateData()
                firstAppear = false
            }
        }
        .searchable(text: $searchString, prompt: "Search")
        .refreshable {
            await updateData()
        }
        .animation(.default, value: filteredProducts.count)
        .alert("Do you really want to delete this product?", isPresented: $showDeleteConfirmation, actions: {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let toDelID = productToDelete?.id {
                    Task {
                        await deleteProduct(toDelID: toDelID)
                    }
                }
            }
        }, message: { Text(productToDelete?.name ?? "Name not found") })
    }
}

struct MDProductsView_Previews: PreviewProvider {
    static var previews: some View {
#if os(macOS)
        MDProductsView()
#else
        NavigationView() {
            MDProductsView()
        }
#endif
    }
}