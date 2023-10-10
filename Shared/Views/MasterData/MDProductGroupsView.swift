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
                .font(.title)
                .foregroundColor(productGroup.active ? .primary : .gray)
            if let description = productGroup.mdProductGroupDescription, !description.isEmpty {
                Text(productGroup.mdProductGroupDescription!)
                    .font(.caption)
            }
        }
        .multilineTextAlignment(.leading)
    }
}

struct MDProductGroupsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Environment(\.dismiss) var dismiss
    
    @State private var searchString: String = ""
    @State private var showAddProductGroup: Bool = false
    
    @State private var shownEditPopover: MDProductGroup? = nil
    
    @State private var productGroupToDelete: MDProductGroup? = nil
    @State private var showDeleteAlert: Bool = false
    
    private let dataToUpdate: [ObjectEntities] = [.product_groups]
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var filteredProductGroups: MDProductGroups {
        grocyVM.mdProductGroups
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    private func deleteItem(itemToDelete: MDProductGroup) {
        productGroupToDelete = itemToDelete
        showDeleteAlert.toggle()
    }
    private func deleteProductGroup(toDelID: Int?) async {
        if let toDelID = toDelID {
            do {
                try await grocyVM.deleteMDObject(object: .product_groups, id: toDelID)
                grocyVM.postLog("Deleting product group was successful.", type: .info)
                await updateData()
            } catch {
                grocyVM.postLog("Deleting product group failed. \(error)", type: .error)
            }
        }
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count == 0 {
#if os(macOS)
            NavigationView {
                bodyContent
                    .frame(minWidth: Constants.macOSNavWidth)
            }
#else
            bodyContent
#endif
        } else {
            ServerProblemView()
                .navigationTitle("Product groups")
        }
    }
    
    var bodyContent: some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
#if os(macOS)
                    RefreshButton(updateData: { Task { await updateData() } })
#endif
                    Button(action: {
                        showAddProductGroup.toggle()
                    }, label: {Image(systemName: MySymbols.new)})
                }
            }
            .navigationTitle("Product groups")
#if os(iOS)
            .sheet(isPresented: self.$showAddProductGroup, content: {
                NavigationView {
                    MDProductGroupFormView(isNewProductGroup: true, showAddProductGroup: $showAddProductGroup)
                }
            })
#endif
    }
    
    var content: some View {
        List {
            if grocyVM.mdProductGroups.isEmpty {
                ContentUnavailableView("No product groups found.", systemImage: MySymbols.productGroup)
            } else if filteredProductGroups.isEmpty {
                ContentUnavailableView.search
            }
#if os(macOS)
            if showAddProductGroup {
                NavigationLink(destination: MDProductGroupFormView(isNewProductGroup: true, showAddProductGroup: $showAddProductGroup), isActive: $showAddProductGroup, label: {
                    NewMDRowLabel(title: "Create product group")
                })
            }
#endif
            ForEach(filteredProductGroups, id:\.id) { productGroup in
                NavigationLink(destination: MDProductGroupFormView(isNewProductGroup: false, productGroup: productGroup, showAddProductGroup: $showAddProductGroup)) {
                    MDProductGroupRowView(productGroup: productGroup)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                    Button(role: .destructive,
                           action: { deleteItem(itemToDelete: productGroup) },
                           label: { Label("Delete", systemImage: MySymbols.delete) }
                    )
                })
            }
        }
        .task {
            Task {
                await updateData()
            }
        }
        .searchable(text: $searchString, prompt: "Search")
        .refreshable {
            await updateData()
        }
        .animation(.default, value: filteredProductGroups.count)
        .alert("Do you really want to delete this product group?", isPresented: $showDeleteAlert, actions: {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let toDelID = productGroupToDelete?.id {
                    Task {
                        await deleteProductGroup(toDelID: toDelID)
                    }
                }
            }
        }, message: { Text(productGroupToDelete?.name ?? "Name not found") })
    }
}

struct MDProductGroupsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MDProductGroupRowView(productGroup: MDProductGroup(id: 0, name: "Name", active: true, mdProductGroupDescription: "Description", rowCreatedTimestamp: ""))
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
