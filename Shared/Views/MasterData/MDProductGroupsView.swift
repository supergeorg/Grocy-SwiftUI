//
//  MDProductGroupsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDProductGroupRowView: View {
    var productGroup: MDProductGroup
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(productGroup.name)
                .font(.largeTitle)
            if productGroup.mdProductGroupDescription != nil {
                if !productGroup.mdProductGroupDescription!.isEmpty {
                    Text(productGroup.mdProductGroupDescription!)
                        .font(.caption)
                }
            }
        }
        .padding(10)
        .multilineTextAlignment(.leading)
    }
}

struct MDProductGroupsView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isSearching: Bool = false
    @State private var searchString: String = ""
    @State private var showAddProductGroup: Bool = false
    
    @State private var shownEditPopover: MDProductGroup? = nil
    
    @State private var reloadRotationDeg: Double = 0
    
    func makeIsPresented(productGroup: MDProductGroup) -> Binding<Bool> {
        return .init(get: {
            return self.shownEditPopover?.id == productGroup.id
        }, set: { _ in    })
    }
    
    private var filteredProductGroups: MDProductGroups {
        grocyVM.mdProductGroups
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
            if grocyVM.mdProductGroups.isEmpty {
                Text("str.md.empty \("str.md.productGroups".localized)")
            } else if filteredProductGroups.isEmpty {
                Text("str.noSearchResult")
            }
            #if os(macOS)
            ForEach(filteredProductGroups, id:\.id) { productGroup in
                MDProductGroupRowView(productGroup: productGroup)
                    .onTapGesture {
                        shownEditPopover = productGroup
                    }
                    .popover(isPresented: makeIsPresented(productGroup: productGroup), arrowEdge: .trailing, content: {
                        MDProductGroupFormView(isNewProductGroup: false, productGroup: productGroup)
                            .padding()
                            .frame(maxWidth: 300, maxHeight: 250)
                    })
            }
            #else
            ForEach(filteredProductGroups, id:\.id) { productGroup in
                NavigationLink(destination: MDProductGroupFormView(isNewProductGroup: false, productGroup: productGroup)) {
                    MDProductGroupRowView(productGroup: productGroup)
                }
            }
            #endif
        }
        .animation(.default)
        .navigationTitle(LocalizedStringKey("str.md.productGroups"))
        .onAppear(perform: {
            grocyVM.getMDProductGroups()
        })
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack{
                    #if os(macOS)
                    if isSearching { SearchBar(text: $searchString, placeholder: "str.md.search") }
                    #endif
                    Button(action: {
                        isSearching.toggle()
                    }, label: {Image(systemName: "magnifyingglass")})
                    Button(action: {
                        withAnimation {
                            self.reloadRotationDeg += 360
                        }
                        grocyVM.getMDProductGroups()
                    }, label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .rotationEffect(Angle.degrees(reloadRotationDeg))
                    })
                    #if os(macOS)
                    Button(action: {
                        showAddProductGroup.toggle()
                    }, label: {Image(systemName: "plus")})
                    .popover(isPresented: self.$showAddProductGroup, content: {
                        MDProductGroupFormView(isNewProductGroup: true)
                            .padding()
                            .frame(maxWidth: 300, maxHeight: 250)
                    })
                    #else
                    Button(action: {
                        showAddProductGroup.toggle()
                    }, label: {Image(systemName: "plus")})
                    .sheet(isPresented: self.$showAddProductGroup, content: {
                            NavigationView {
                                MDProductGroupFormView(isNewProductGroup: true)
                            } })
                    #endif
                }
            }
        }
    }
}

struct MDProductGroupsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MDProductGroupRowView(productGroup: MDProductGroup(id: "0", name: "Name", mdProductGroupDescription: "Description", rowCreatedTimestamp: "", userfields: nil))
            #if os(macOS)
            MDProductGroupsView()
            #else
            NavigationView() {
                MDProductGroupsView()
            }
            #endif
        }
    }
}
