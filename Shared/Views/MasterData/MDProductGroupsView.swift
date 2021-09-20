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
            if let description = productGroup.mdProductGroupDescription, !description.isEmpty {
                Text(productGroup.mdProductGroupDescription!)
                    .font(.caption)
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
    
    private let dataToUpdate: [ObjectEntities] = [.product_groups]
    
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var filteredProductGroups: MDProductGroups {
        grocyVM.mdProductGroups
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    private func delete(at offsets: IndexSet) {
        for offset in offsets {
            productGroupToDelete = filteredProductGroups[offset]
            showDeleteAlert.toggle()
        }
    }
    private func deleteProductGroup(toDelID: Int?) {
        if let toDelID = toDelID {
            grocyVM.deleteMDObject(object: .product_groups, id: toDelID, completion: { result in
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
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count == 0 {
            bodyContent
        } else {
            ServerOfflineView()
                .navigationTitle(LocalizedStringKey("str.md.productGroups"))
        }
    }
    
    #if os(macOS)
    var bodyContent: some View {
        NavigationView {
            content
                .toolbar(content: {
                    ToolbarItem(placement: .primaryAction, content: {
                        HStack{
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
                                showAddProductGroup.toggle()
                            }, label: {Image(systemName: MySymbols.new)})
                        }
                    })
                    ToolbarItem(placement: .automatic, content: {
                        ToolbarSearchField(searchTerm: $searchString)
                    })
                })
                .frame(minWidth: Constants.macOSNavWidth)
        }
        .navigationTitle(LocalizedStringKey("str.md.productGroups"))
    }
    #elseif os(iOS)
    var bodyContent: some View {
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
                            showAddProductGroup.toggle()
                        }, label: {Image(systemName: MySymbols.new)})
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("str.md.productGroups"))
            .sheet(isPresented: self.$showAddProductGroup, content: {
                    NavigationView {
                        MDProductGroupFormView(isNewProductGroup: true, showAddProductGroup: $showAddProductGroup, toastType: $toastType)
                    } })
    }
    #endif
    
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
            #if os(macOS)
            if showAddProductGroup {
                NavigationLink(destination: MDProductGroupFormView(isNewProductGroup: true, showAddProductGroup: $showAddProductGroup, toastType: $toastType), isActive: $showAddProductGroup, label: {
                    NewMDRowLabel(title: "str.md.productGroup.new")
                })
            }
            #endif
            ForEach(filteredProductGroups, id:\.id) { productGroup in
                NavigationLink(destination: MDProductGroupFormView(isNewProductGroup: false, productGroup: productGroup, showAddProductGroup: Binding.constant(false), toastType: $toastType)) {
                    MDProductGroupRowView(productGroup: productGroup)
                }
            }
            .onDelete(perform: delete)
        }
        .onAppear(perform: { grocyVM.requestData(objects: dataToUpdate, ignoreCached: false) })
        .animation(.default, value: filteredProductGroups.count)
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
            Alert(title: Text(LocalizedStringKey("str.md.productGroup.delete.confirm")),
                  message: Text(productGroupToDelete?.name ?? "error"),
                  primaryButton: .destructive(Text(LocalizedStringKey("str.delete")))
                  {
                    deleteProductGroup(toDelID: productGroupToDelete?.id)
                  },
                  secondaryButton: .cancel())
        }
    }
}

struct MDProductGroupsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MDProductGroupRowView(productGroup: MDProductGroup(id: 0, name: "Name", mdProductGroupDescription: "Description", rowCreatedTimestamp: ""))
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
