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
    
    var body: some View {
        HStack{
            if let pictureFileName = product.pictureFileName {
                let utf8str = pictureFileName.data(using: .utf8)
                if let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
                    if let pictureURL = grocyVM.getPictureURL(groupName: "productpictures", fileName: base64Encoded) {
                        RemoteImageView(withURL: pictureURL)
                            .frame(width: 100, height: 100)
                    }
                }
            }
            VStack(alignment: .leading) {
                Text(product.name).font(.largeTitle)
                HStack{
                    if let loc = GrocyViewModel.shared.mdLocations.firstIndex { $0.id == product.locationID } {
                        Text("Standort: ").font(.caption)
                            +
                            Text(GrocyViewModel.shared.mdLocations[loc].name).font(.caption)
                    }
                    if let pg = GrocyViewModel.shared.mdProductGroups.firstIndex { $0.id == product.productGroupID } {
                        Text("Kategorie: ").font(.caption)
                            +
                            Text(GrocyViewModel.shared.mdProductGroups[pg].name).font(.caption)
                    }
                }
                if let description = product.mdProductDescription {
                    if !description.isEmpty{
                        Text(description).font(.caption)
                    }
                }
            }
            //        .padding(10)
            //        .multilineTextAlignment(.leading)
            //        .overlay(
            //            RoundedRectangle(cornerRadius: 12, style: .continuous)
            //                .stroke(Color.primary, lineWidth: 1)
            //        )
        }
    }
}

struct MDProductsView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isSearching: Bool = false
    @State private var searchString: String = ""
    @State private var showAddProduct: Bool = false
    
    @State private var shownEditPopover: MDProduct? = nil
    
    @State private var reloadRotationDeg: Double = 0
    
    @State private var productToDelete: MDProduct? = nil
    @State private var showDeleteAlert: Bool = false
    
    func makeIsPresented(product: MDProduct) -> Binding<Bool> {
        return .init(get: {
            return self.shownEditPopover?.id == product.id
        }, set: { _ in    })
    }
    
    private func updateData() {
        grocyVM.getMDProducts()
        grocyVM.getMDLocations()
        grocyVM.getMDProductGroups()
    }
    
    private func delete(at offsets: IndexSet) {
        for offset in offsets {
            productToDelete = filteredProducts[offset]
            showDeleteAlert.toggle()
        }
    }
    private func deleteProduct(toDelID: String) {
        grocyVM.deleteMDObject(object: .products, id: toDelID)
        updateData()
    }
    
    private var filteredProducts: MDProducts {
        grocyVM.mdProducts
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
            .sorted {
                $0.name < $1.name
            }
    }
    
    var body: some View {
        #if os(macOS)
        content
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack{
                        if isSearching { SearchBar(text: $searchString, placeholder: "str.md.search".localized) }
                        Button(action: {
                            isSearching.toggle()
                        }, label: {Image(systemName: "magnifyingglass")})
                        Button(action: {
                            withAnimation {
                                self.reloadRotationDeg += 360
                            }
                            updateData()
                        }, label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .rotationEffect(Angle.degrees(reloadRotationDeg))
                        })
                        Button(action: {
                            showAddProduct.toggle()
                        }, label: {Image(systemName: "plus")})
                        .popover(isPresented: self.$showAddProduct, content: {
                            ScrollView{
                                MDProductFormView(isNewProduct: true)
                                    .padding()
                            }
                            .frame(maxWidth: 500, maxHeight: 500)
                        })
                    }
                }
            }
        #elseif os(iOS)
        content
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack{
                        Button(action: {
                            isSearching.toggle()
                        }, label: {Image(systemName: "magnifyingglass")})
                        Button(action: {
                            withAnimation {
                                self.reloadRotationDeg += 360
                            }
                            updateData()
                        }, label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .rotationEffect(Angle.degrees(reloadRotationDeg))
                        })
                        Button(action: {
                            showAddProduct.toggle()
                        }, label: {Image(systemName: "plus")})
                        .sheet(isPresented: self.$showAddProduct, content: {
                                NavigationView {
                                    MDProductFormView(isNewProduct: true)
                                } })
                    }
                }
            }
        #endif
    }
    
    var content: some View {
        List(){
            #if os(iOS)
            if isSearching { SearchBar(text: $searchString, placeholder: "str.md.search") }
            #endif
            if grocyVM.mdProducts.isEmpty {
                Text("str.md.empty \("str.md.products".localized)")
            } else if filteredProducts.isEmpty {
                Text("str.noSearchResult")
            }
            #if os(macOS)
            ForEach(filteredProducts, id:\.id) { product in
                MDProductRowView(product: product)
                    .onTapGesture {
                        shownEditPopover = product
                    }
                    .popover(isPresented: makeIsPresented(product: product), arrowEdge: .trailing, content: {
                        ScrollView{
                            MDProductFormView(isNewProduct: false, product: product)
                                .padding()
                        }
                        .frame(width: 400, height: 400)
                    })
            }
            .onDelete(perform: delete)
            #else
            ForEach(filteredProducts, id:\.id) { product in
                NavigationLink(destination: MDProductFormView(isNewProduct: false, product: product)) {
                    MDProductRowView(product: product)
                }
            }
            .onDelete(perform: delete)
            #endif
        }
        .animation(.default)
        .navigationTitle("str.md.products".localized)
        .onAppear(perform: {
            updateData()
        })
        .alert(isPresented: $showDeleteAlert) {
            Alert(title: Text("str.md.product.delete.confirm"), message: Text(productToDelete?.name ?? "error"), primaryButton: .destructive(Text("str.delete")) {
                deleteProduct(toDelID: productToDelete?.id ?? "")
            }, secondaryButton: .cancel())
        }
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
