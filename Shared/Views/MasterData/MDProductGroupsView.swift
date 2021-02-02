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
    
    @State private var productGroupToDelete: MDProductGroup? = nil
    @State private var showDeleteAlert: Bool = false
    
    @State private var toastType: MDToastType?
    
    private func updateData() {
        grocyVM.getMDProductGroups()
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
    
    private func delete(at offsets: IndexSet) {
        for offset in offsets {
            productGroupToDelete = filteredProductGroups[offset]
            showDeleteAlert.toggle()
        }
    }
    private func deleteProductGroup(toDelID: String) {
        grocyVM.deleteMDObject(object: .product_groups, id: toDelID)
        updateData()
    }
    
    var body: some View {
        #if os(macOS)
        NavigationView {
            content
                .toolbar(content: {
                    ToolbarItem(placement: .primaryAction) {
                        HStack{
                            if isSearching { SearchBarSwiftUI(text: $searchString, placeholder: "str.md.search") }
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
                            Button(action: {
                                showAddProductGroup.toggle()
                            }, label: {Image(systemName: "plus")})
                            .popover(isPresented: self.$showAddProductGroup, content: {
                                MDProductGroupFormView(isNewProductGroup: true, toastType: $toastType)
                                    .padding()
                                    .frame(maxWidth: 300, maxHeight: 250)
                            })
                        }
                    }
                })
                .frame(minWidth: Constants.macOSNavWidth)
        }
        .navigationTitle(LocalizedStringKey("str.md.productGroups"))
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
                            grocyVM.getMDProductGroups()
                        }, label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .rotationEffect(Angle.degrees(reloadRotationDeg))
                        })
                        Button(action: {
                            showAddProductGroup.toggle()
                        }, label: {Image(systemName: "plus")})
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("str.md.productGroups"))
            .sheet(isPresented: self.$showAddProductGroup, content: {
                    NavigationView {
                        MDProductGroupFormView(isNewProductGroup: true, toastType: $toastType)
                    } })
        #endif
    }
    
    var content: some View {
        List(){
            #if os(iOS)
            if isSearching { SearchBar(text: $searchString, placeholder: "str.md.search") }
            #endif
            if grocyVM.mdProductGroups.isEmpty {
                Text(LocalizedStringKey("str.md.productGroups.empty"))
            } else if filteredProductGroups.isEmpty {
                Text(LocalizedStringKey("str.noSearchResult"))
            }
            ForEach(filteredProductGroups, id:\.id) { productGroup in
                NavigationLink(destination: MDProductGroupFormView(isNewProductGroup: false, productGroup: productGroup, toastType: $toastType)) {
                    MDProductGroupRowView(productGroup: productGroup)
                }
            }
            .onDelete(perform: delete)
        }
        .onAppear(perform: { grocyVM.requestDataIfUnavailable(objects: [.product_groups]) })
        .animation(.default)
        .alert(isPresented: $showDeleteAlert) {
            Alert(title: Text(LocalizedStringKey("str.md.productGroup.delete.confirm")),
                  message: Text(productGroupToDelete?.name ?? "error"),
                  primaryButton: .destructive(Text(LocalizedStringKey("str.delete")))
                    {
                        deleteProductGroup(toDelID: productGroupToDelete?.id ?? "")
                    },
                  secondaryButton: .cancel())
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
