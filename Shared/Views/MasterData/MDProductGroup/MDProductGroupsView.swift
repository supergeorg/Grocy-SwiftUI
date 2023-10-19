//
//  MDProductGroupsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI
import SwiftData

struct MDProductGroupsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDProductGroup.id, order: .forward) var mdProductGroups: MDProductGroups
    
    @State private var searchString: String = ""
    @State private var showAddProductGroup: Bool = false
    
    @State private var productGroupToDelete: MDProductGroup? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    private let dataToUpdate: [ObjectEntities] = [.product_groups]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var filteredProductGroups: MDProductGroups {
        mdProductGroups
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    private func deleteItem(itemToDelete: MDProductGroup) {
        productGroupToDelete = itemToDelete
        showDeleteConfirmation.toggle()
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
        List {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            } else if mdProductGroups.isEmpty {
                ContentUnavailableView("No product groups found.", systemImage: MySymbols.productGroup)
            } else if filteredProductGroups.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(filteredProductGroups, id:\.id) { productGroup in
                NavigationLink(value: productGroup, label: {
                    MDProductGroupRowView(productGroup: productGroup)
                })
                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                    Button(role: .destructive,
                           action: { deleteItem(itemToDelete: productGroup) },
                           label: { Label("Delete", systemImage: MySymbols.delete) }
                    )
                })
            }
        }
        .navigationDestination(isPresented: $showAddProductGroup, destination: {
            MDProductGroupFormView()
        })
        .navigationDestination(for: MDProductGroup.self, destination: { productGroup in
            MDProductGroupFormView(existingProductGroup: productGroup)
        })
        .navigationTitle("Product groups")
        .task {
            await updateData()
        }
        .refreshable {
            await updateData()
        }
        .searchable(text: $searchString, prompt: "Search")

        .animation(.default, value: filteredProductGroups.count)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
#if os(macOS)
                RefreshButton(updateData: { Task { await updateData() } })
#endif
                Button(action: {
                    showAddProductGroup.toggle()
                }, label: {
                    Label("New product group", systemImage: MySymbols.new)
                })
            }
        }

        .confirmationDialog("Do you really want to delete this product group?", isPresented: $showDeleteConfirmation, actions: {
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

#Preview {
    MDProductGroupsView()
}
