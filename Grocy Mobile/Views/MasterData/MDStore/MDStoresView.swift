//
//  MDStoresView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftData
import SwiftUI

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
        let predicate =
            searchString.isEmpty
            ? nil
            : #Predicate<MDStore> { store in
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
            GrocyLogger.info("Deleting store was successful.")
            await updateData()
        } catch {
            GrocyLogger.error("Deleting store failed. \(error)")
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
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: true,
                    content: {
                        Button(
                            role: .destructive,
                            action: { deleteItem(itemToDelete: store) },
                            label: { Label("Delete", systemImage: MySymbols.delete) }
                        )
                    }
                )
            }
        }
        #if os(iOS)
            .sheet(
                isPresented: $showAddStore,
                content: {
                    NavigationStack {
                        MDStoreFormView()
                    }
                }
            )
        #else
            .navigationDestination(isPresented: $showAddStore, destination: { NavigationStack { MDStoreFormView() } })
        #endif
        .navigationDestination(
            for: MDStore.self,
            destination: { store in
                MDStoreFormView(existingStore: store)
            }
        )
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
        .alert(
            "Are you sure you want to delete store \"\(storeToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirmation,
            actions: {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let toDelID = storeToDelete?.id {
                        Task {
                            await deleteStore(toDelID: toDelID)
                        }
                    }
                }
            }
        )
        .toolbar(content: {
            ToolbarItemGroup(
                placement: .primaryAction,
                content: {
                    Button(
                        action: {
                            showAddStore.toggle()
                        },
                        label: {
                            Label("Create store", systemImage: MySymbols.new)
                        }
                    )
                }
            )
        })
        .navigationTitle("Stores")
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        MDStoresView()
    }
}
