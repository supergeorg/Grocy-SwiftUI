//
//  MDStoresView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI
import SwiftData

struct MDStoreRowView: View {
    var store: MDStore
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(store.name)
                .font(.title)
                .foregroundStyle(store.active ? .primary : .secondary)
            if !store.mdStoreDescription.isEmpty {
                Text(store.mdStoreDescription)
                    .font(.caption)
            }
        }
        .multilineTextAlignment(.leading)
    }
}

struct MDStoresView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \MDStore.name, order: .forward) var mdStores: MDStores
    
    @State private var firstAppear: Bool = true
    @State private var searchString: String = ""

    @State private var storeToDelete: MDStore? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    private let dataToUpdate: [ObjectEntities] = [.shopping_locations]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var filteredStores: MDStores {
        mdStores
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    private func deleteItem(itemToDelete: MDStore) {
        storeToDelete = itemToDelete
        showDeleteConfirmation.toggle()
    }
    
    private func deleteStore(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .shopping_locations, id: toDelID)
            grocyVM.postLog("Deleting store was successful.", type: .info)
            await updateData()
        } catch {
            grocyVM.postLog("Deleting store failed. \(error)", type: .error)
        }
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) })
            .count == 0
        {
            content
        } else {
            ServerProblemView()
                .navigationTitle("Stores")
        }
    }
    
    var content: some View {
        List {
            if mdStores.isEmpty {
                ContentUnavailableView("No stores found.", systemImage: MySymbols.store)
            } else if filteredStores.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(filteredStores, id: \.id) { store in
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
        .navigationDestination(for: String.self, destination: { _ in
            MDStoreFormView()
        })
        .navigationDestination(for: MDStore.self, destination: { store in
            MDStoreFormView(existingStore: store)
        })
        .task {
            if firstAppear {
                await updateData()
                firstAppear = false
            }
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
            value: filteredStores.count
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
//                    showAddStore.toggle()
                }, label: {
                    Image(systemName: MySymbols.new)
                })
            })
        })
        .navigationTitle("Stores")
    }
}
