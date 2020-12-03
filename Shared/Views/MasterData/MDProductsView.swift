//
//  MDProductsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDProductRowView: View {
    var product: MDProduct
    
    var body: some View {
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
        .padding(10)
        .multilineTextAlignment(.leading)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary, lineWidth: 1)
        )
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
            #else
            ForEach(filteredProducts, id:\.id) { product in
                NavigationLink(destination: MDProductFormView(isNewProduct: false, product: product)) {
                    MDProductRowView(product: product)
                }
            }
            #endif
        }
        .animation(.default)
        .navigationTitle("str.md.products".localized)
        .onAppear(perform: {
            updateData()
        })
        .toolbar {
//            ToolbarSearch(
            ToolbarItem(placement: .primaryAction) {
                HStack{
                    #if os(macOS)
                    if isSearching { SearchBar(text: $searchString, placeholder: "str.md.search".localized) }
                    #endif
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
                    #if os(macOS)
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
                    #else
                    Button(action: {
                        showAddProduct.toggle()
                    }, label: {Image(systemName: "plus")})
                    .sheet(isPresented: self.$showAddProduct, content: {
                            NavigationView {
                                MDProductFormView(isNewProduct: true)
                            } })
                    #endif
                }
            }
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
