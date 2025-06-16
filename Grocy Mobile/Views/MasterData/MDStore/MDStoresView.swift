//
//  MDStoresView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI
import SwiftData
internal import os

struct MDStoresView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchString: String = ""
    @State private var showAddStore: Bool = false
    @State private var storeToDelete: MDStore? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    // Fetch the data with a dynamic predicate
    var mdStores: MDStores {
        let sortDescriptor = SortDescriptor<MDStore>(\.name)
        let predicate = searchString.isEmpty ? nil :
        #Predicate<MDStore> { store in
            searchString == "" ? true : store.name.localizedStandardContains(searchString)
        }
        
        let descriptor = FetchDescriptor<MDStore>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // Get the unfiltered count without fetching any data
    var mdStoresCount: Int {
        var descriptor = FetchDescriptor<MDStore>(
            sortBy: []
        )
        descriptor.fetchLimit = 0
        
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    private let dataToUpdate: [ObjectEntities] = [.shopping_locations]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private func deleteItem(itemToDelete: MDStore) {
        storeToDelete = itemToDelete
        showDeleteConfirmation.toggle()
    }
    
    private func deleteStore(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .shopping_locations, id: toDelID)
            grocyVM.grocyLog.info("Deleting store was successful.")
            await updateData()
        } catch {
            grocyVM.postLog("Deleting store failed. \(error)", type: .error)
        }
    }
    
    var body: some View {
        List {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            } else if mdStoresCount == 0 {
                ContentUnavailableView("No store defined. Please create one.", systemImage: MySymbols.store)
            } else if mdStores.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(mdStores, id: \.id) { store in
                NavigationLink(value: store) {
                    MDStoreRowView(store: store)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                    Button(role: .destructive,
                           action: { deleteItem(itemToDelete: store) },
                           label: { Label("Delete", systemImage: MySymbols.delete) })
                })
            }
        }
        .navigationDestination(isPresented: $showAddStore, destination: {
            MDStoreFormView()
        })
        .navigationDestination(for: MDStore.self, destination: { store in
            MDStoreFormView(existingStore: store)
        })
        .task {
            await updateData()
        }
        .refreshable {
            await updateData()
        }
        .searchable(
            text: $searchString,
            prompt: "Search"
        )
        .animation(
            .default,
            value: mdStores.count
        )
        .confirmationDialog("Do you really want to delete this store?", isPresented: $showDeleteConfirmation, titleVisibility: .visible, actions: {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let toDelID = storeToDelete?.id {
                    Task {
                        await deleteStore(toDelID: toDelID)
                    }
                }
            }
        }, message: { Text(storeToDelete?.name ?? "") })
        .toolbar(content: {
            ToolbarItemGroup(placement: .primaryAction, content: {
#if os(macOS)
                RefreshButton(updateData: { Task { await updateData() } })
#endif
                Button(action: {
                    showAddStore.toggle()
                }, label: {
                    Label("New store", systemImage: MySymbols.new)
                })
            })
        })
        .navigationTitle("Stores")
    }
}
