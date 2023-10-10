//
//  MDStoresView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDStoreRowView: View {
    var store: MDStore
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(store.name)
                .font(.title)
                .foregroundStyle(store.active ? .primary : .secondary)
            if let description = store.mdStoreDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
            }
        }
        .multilineTextAlignment(.leading)
    }
}

struct MDStoresView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @State private var searchString: String = ""
    
    @State private var showAddStore: Bool = false
    @State private var storeToDelete: MDStore? = nil
    @State private var showDeleteAlert: Bool = false
    
    private let dataToUpdate: [ObjectEntities] = [.shopping_locations]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var filteredStores: MDStores {
        grocyVM.mdStores
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    private func deleteItem(itemToDelete: MDStore) {
        storeToDelete = itemToDelete
        showDeleteAlert.toggle()
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
        if grocyVM.failedToLoadObjects.filter( {dataToUpdate.contains($0) })
            .count == 0 {
#if os(macOS)
            NavigationView{
                bodyContent
                    .frame(minWidth: Constants.macOSNavWidth)
            }
#else
            bodyContent
#endif
        } else {
            ServerProblemView()
                .navigationTitle("Stores")
        }
    }
    
    var bodyContent: some View {
        content
            .toolbar(content: {
                ToolbarItemGroup(placement: .primaryAction, content: {
#if os(macOS)
                    RefreshButton(updateData: { Task { await updateData() } })
#endif
                    Button(action: {
                        showAddStore.toggle()
                    }, label: {
                        Image(systemName: MySymbols.new)
                    })
                })
            })
            .navigationTitle("Stores")
#if os(iOS)
            .sheet(isPresented: self.$showAddStore, content: {
                NavigationView {
                    MDStoreFormView(isNewStore: true, showAddStore: $showAddStore)
                }
            })
#endif
    }
    
    var content: some View {
        List{
            if grocyVM.mdStores.isEmpty {
                ContentUnavailableView("No stores found.", systemImage: MySymbols.store)
            } else if filteredStores.isEmpty {
                ContentUnavailableView.search
            }
#if os(macOS)
            if showAddStore {
                NavigationLink(destination: MDStoreFormView(isNewStore: true, showAddStore: $showAddStore), isActive: $showAddStore, label: {
                    NewMDRowLabel(title: "New store")
                })
            }
#endif
            ForEach(filteredStores, id:\.id) { store in
                NavigationLink(destination: MDStoreFormView(isNewStore: false, store: store, showAddStore: Binding.constant(false))) {
                    MDStoreRowView(store: store)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                    Button(role: .destructive,
                           action: { deleteItem(itemToDelete: store) },
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
        .animation(.default,
                   value: filteredStores.count)
        .alert("Do you really want to delete this store?", isPresented: $showDeleteAlert, actions: {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let toDelID = storeToDelete?.id {
                    Task {
                        await deleteStore(toDelID: toDelID)
                    }
                }
            }
        }, message: { Text(storeToDelete?.name ?? "Name not found") })
    }
}

struct MDStoresView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            List {
                MDStoreRowView(store: MDStore(id: 0, name: "Location", active: true, mdStoreDescription: "Description", rowCreatedTimestamp: ""))
            }
#if os(macOS)
            MDStoresView()
#else
            NavigationView() {
                MDStoresView()
            }
#endif
        }
    }
}
