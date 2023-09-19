//
//  MDProductsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDProductRowView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
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
                    .foregroundColor(product.active ? .primary : .gray)
                HStack(alignment: .top){
                    if let locationID = GrocyViewModel.shared.mdLocations.firstIndex(where: { $0.id == product.locationID }) {
                        Text(LocalizedStringKey("str.md.product.rowLocation \(grocyVM.mdLocations[locationID].name)"))
                            .font(.caption)
                    }
                    if let productGroup = GrocyViewModel.shared.mdProductGroups.firstIndex(where: { $0.id == product.productGroupID }) {
                        Text(LocalizedStringKey("str.md.product.rowProductGroup \(grocyVM.mdProductGroups[productGroup].name)"))
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
                if let mdProductDescription = product.mdProductDescription {
                    productDescription = await grocyVM.getAttributedStringFromHTML(htmlString: mdProductDescription)
                }
            }
        }
    }
}

struct MDProductsView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var searchString: String = ""
    
    @State private var showAddProduct: Bool = false
    @State private var productToDelete: MDProduct? = nil
    @State private var showDeleteAlert: Bool = false
    @State private var toastType: ToastType?
    
    private let dataToUpdate: [ObjectEntities] = [.products, .locations, .product_groups]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private func deleteItem(itemToDelete: MDProduct) {
        productToDelete = itemToDelete
        showDeleteAlert.toggle()
    }
    private func deleteProduct(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .products, id: toDelID)
            grocyVM.postLog("Deleting product was successful.", type: .info)
            await grocyVM.requestData(objects: [.products, .product_barcodes])
        } catch {
            grocyVM.postLog("Deleting product failed. \(error)", type: .error)
            toastType = .failDelete
        }
    }
    
    private var filteredProducts: MDProducts {
        grocyVM.mdProducts
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
                .navigationTitle(LocalizedStringKey("str.md.products"))
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
            .navigationTitle(LocalizedStringKey("str.md.products"))
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
            if grocyVM.mdProducts.isEmpty {
                ContentUnavailableView("str.md.products.empty", systemImage: MySymbols.product)
            } else if filteredProducts.isEmpty {
                ContentUnavailableView.search
            }
#if os(macOS)
            if showAddProduct {
                NavigationLink(destination: MDProductFormView(isNewProduct: true, showAddProduct: $showAddProduct), isActive: $showAddProduct, label: {
                    NewMDRowLabel(title: "str.md.product.new")
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
                           label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) }
                    )
                })
            }
        }
        .task {
            Task {
                await updateData()
            }
        }
        .searchable(text: $searchString, prompt: LocalizedStringKey("str.search"))
        .refreshable {
            await updateData()
        }
        .animation(.default, value: filteredProducts.count)
        .toast(
            item: $toastType,
            isSuccess: Binding.constant(toastType == .successAdd || toastType == .successEdit),
            isShown: [.successAdd, .failAdd, .successEdit, .failEdit, .failDelete].contains(toastType),
            text: { item in
                switch item {
                case .successAdd:
                    return LocalizedStringKey("str.md.new.success")
                case .failAdd:
                    return LocalizedStringKey("str.md.new.fail")
                case .successEdit:
                    return LocalizedStringKey("str.md.edit.success")
                case .failEdit:
                    return LocalizedStringKey("str.md.edit.fail")
                case .failDelete:
                    return LocalizedStringKey("str.md.delete.fail")
                default:
                    return LocalizedStringKey("str.error")
                }
            })
        .alert(LocalizedStringKey("str.md.product.delete.confirm"), isPresented: $showDeleteAlert, actions: {
            Button(LocalizedStringKey("str.cancel"), role: .cancel) { }
            Button(LocalizedStringKey("str.delete"), role: .destructive) {
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
