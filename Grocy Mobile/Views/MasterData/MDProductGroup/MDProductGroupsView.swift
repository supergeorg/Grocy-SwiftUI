//
//  MDProductGroupsView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftData
import SwiftUI

struct MDProductGroupsView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext

    @State private var searchString: String = ""
    @State private var showAddProductGroup: Bool = false
    @State private var productGroupToDelete: MDProductGroup? = nil
    @State private var showDeleteConfirmation: Bool = false

    // Fetch the data with a dynamic predicate
    var mdProductGroups: MDProductGroups {
        let sortDescriptor = SortDescriptor<MDProductGroup>(\.name)
        let predicate =
            searchString.isEmpty
            ? nil
            : #Predicate<MDProductGroup> { store in
                searchString == "" ? true : store.name.localizedStandardContains(searchString)
            }

        let descriptor = FetchDescriptor<MDProductGroup>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // Get the unfiltered count without fetching any data
    var mdProductGroupsCount: Int {
        var descriptor = FetchDescriptor<MDProductGroup>(
            sortBy: []
        )
        descriptor.fetchLimit = 0

        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private let dataToUpdate: [ObjectEntities] = [.product_groups]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func deleteItem(itemToDelete: MDProductGroup) {
        productGroupToDelete = itemToDelete
        showDeleteConfirmation.toggle()
    }
    private func deleteProductGroup(toDelID: Int?) async {
        if let toDelID = toDelID {
            do {
                try await grocyVM.deleteMDObject(object: .product_groups, id: toDelID)
                GrocyLogger.info("Deleting product group was successful.")
                await updateData()
            } catch {
                GrocyLogger.error("Deleting product group failed. \(error)")
            }
        }
    }

    var body: some View {
        List {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            } else if mdProductGroupsCount == 0 {
                ContentUnavailableView("No product group defined. Please create one.", systemImage: MySymbols.productGroup)
            } else if mdProductGroups.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(mdProductGroups, id: \.id) { productGroup in
                NavigationLink(
                    value: productGroup,
                    label: {
                        MDProductGroupRowView(productGroup: productGroup)
                    }
                )
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: true,
                    content: {
                        Button(
                            role: .destructive,
                            action: { deleteItem(itemToDelete: productGroup) },
                            label: { Label("Delete", systemImage: MySymbols.delete) }
                        )
                    }
                )
            }
        }
        .sheet(
            isPresented: $showAddProductGroup,
            content: {
                NavigationStack {
                    MDProductGroupFormView()
                }
            }
        )
        .navigationDestination(
            for: MDProductGroup.self,
            destination: { productGroup in
                MDProductGroupFormView(existingProductGroup: productGroup)
            }
        )
        .navigationTitle("Product groups")
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
            value: mdProductGroups.count
        )
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                #if os(macOS)
                    RefreshButton(updateData: { Task { await updateData() } })
                #endif
                Button(
                    action: {
                        showAddProductGroup.toggle()
                    },
                    label: {
                        Label("New product group", systemImage: MySymbols.new)
                    }
                )
            }
        }
        .confirmationDialog(
            "Do you really want to delete this product group?",
            isPresented: $showDeleteConfirmation,
            actions: {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let toDelID = productGroupToDelete?.id {
                        Task {
                            await deleteProductGroup(toDelID: toDelID)
                        }
                    }
                }
            },
            message: { Text(productGroupToDelete?.name ?? "Name not found") }
        )
    }
}

#Preview {
    MDProductGroupsView()
}
