//
//  MDProductsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI
import URLImage

struct MDProductRowView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var product: MDProduct
    
    var body: some View {
        HStack{
            if let pictureFileName = product.pictureFileName {
                let utf8str = pictureFileName.data(using: .utf8)
                if let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
                    if let pictureURL = grocyVM.getPictureURL(groupName: "productpictures", fileName: base64Encoded) {
                        if let url = URL(string: pictureURL) {
                            URLImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .background(Color.white)
                            }
                            .frame(width: 75, height: 75)
                        }
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
                        Text(description).font(.caption).italic()
                    }
                }
            }
        }
    }
}

struct MDProductsView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isSearching: Bool = false
    @State private var searchString: String = ""
    @State private var showAddProduct: Bool = false
    
    @State private var reloadRotationDeg: Double = 0
    
    @State private var productToDelete: MDProduct? = nil
    @State private var showDeleteAlert: Bool = false
    
    @State private var toastType: MDToastType?
    
    private func updateData() {
        grocyVM.requestData(objects: [.products, .locations, .product_groups])
    }
    
    private func delete(at offsets: IndexSet) {
        for offset in offsets {
            productToDelete = filteredProducts[offset]
            showDeleteAlert.toggle()
        }
    }
    private func deleteProduct(toDelID: String) {
        grocyVM.deleteMDObject(object: .products, id: toDelID, completion: { result in
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
        NavigationView{
            content
                .toolbar (content: {
                    ToolbarItem(placement: .primaryAction) {
                        HStack{
                            if isSearching { SearchBarSwiftUI(text: $searchString, placeholder: "str.md.search") }
                            Button(action: {
                                isSearching.toggle()
                            }, label: {Image(systemName: MySymbols.search)})
                            Button(action: {
                                withAnimation {
                                    self.reloadRotationDeg += 360
                                }
                                updateData()
                            }, label: {
                                Image(systemName: MySymbols.reload)
                                    .rotationEffect(Angle.degrees(reloadRotationDeg))
                            })
                            Button(action: {
                                showAddProduct.toggle()
                            }, label: {Image(systemName: MySymbols.new)})
                            .popover(isPresented: self.$showAddProduct, content: {
                                MDProductFormView(isNewProduct: true, toastType: $toastType)
                                    .frame(width: 700, height: 700)
                            })
                        }
                    }
                })
                .frame(minWidth: Constants.macOSNavWidth)
        }
        .navigationTitle(LocalizedStringKey("str.md.products"))
        #elseif os(iOS)
        content
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack{
                        Button(action: {
                            isSearching.toggle()
                        }, label: {Image(systemName: MySymbols.search)})
                        Button(action: {
                            withAnimation {
                                self.reloadRotationDeg += 360
                            }
                            updateData()
                        }, label: {
                            Image(systemName: MySymbols.reload)
                                .rotationEffect(Angle.degrees(reloadRotationDeg))
                        })
                        Button(action: {
                            showAddProduct.toggle()
                        }, label: {Image(systemName: MySymbols.new)})
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("str.md.products"))
            .sheet(isPresented: $showAddProduct, content: {
                NavigationView {
                    MDProductFormView(isNewProduct: true, toastType: $toastType)
                }
            })
        #endif
    }
    
    var content: some View {
        List(){
            #if os(iOS)
            if isSearching { SearchBar(text: $searchString, placeholder: "str.md.search") }
            #endif
            if grocyVM.mdProducts.isEmpty {
                Text(LocalizedStringKey("str.md.products.empty"))
            } else if filteredProducts.isEmpty {
                Text(LocalizedStringKey("str.noSearchResult"))
            }
            ForEach(filteredProducts, id:\.id) { product in
                NavigationLink(destination: MDProductFormView(isNewProduct: false, product: product, toastType: $toastType)) {
                    MDProductRowView(product: product)
                }
            }
            .onDelete(perform: delete)
        }
        .onAppear(perform: {
            grocyVM.requestData(objects: [.products, .locations, .product_groups], ignoreCached: false)
        })
        .animation(.default)
        .toast(item: $toastType, isSuccess: Binding.constant(toastType == .successAdd || toastType == .successEdit), content: { item in
            switch item {
            case .successAdd:
                Label(LocalizedStringKey("str.md.new.success"), systemImage: MySymbols.success)
            case .failAdd:
                Label(LocalizedStringKey("str.md.new.fail"), systemImage: MySymbols.failure)
            case .successEdit:
                Label(LocalizedStringKey("str.md.edit.success"), systemImage: MySymbols.success)
            case .failEdit:
                Label(LocalizedStringKey("str.md.edit.fail"), systemImage: MySymbols.failure)
            case .failDelete:
                Label(LocalizedStringKey("str.md.delete.fail"), systemImage: MySymbols.failure)
            }
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
