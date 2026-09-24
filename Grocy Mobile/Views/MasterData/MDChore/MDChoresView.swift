//
//  MDChoresView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftData
import SwiftUI

struct MDChoresView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext

    @State private var searchString: String = ""
    @State private var showAddChore: Bool = false
    @State private var choreToDelete: MDChore? = nil
    @State private var showDeleteConfirmation: Bool = false

    var mdChores: MDChores {
        let sortDescriptor = SortDescriptor<MDChore>(\.name)
        let predicate = #Predicate<MDChore> { chore in
            searchString.isEmpty || chore.name.localizedStandardContains(searchString)
        }

        let descriptor = FetchDescriptor<MDChore>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var choresCount: Int {
        var descriptor = FetchDescriptor<MDChore>(
            sortBy: []
        )
        descriptor.fetchLimit = 0

        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private let dataToUpdate: [ObjectEntities] = [.chores]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func deleteItem(itemToDelete: MDChore) {
        choreToDelete = itemToDelete
        showDeleteConfirmation.toggle()
    }

    private func deleteChore(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .chores, id: toDelID)
            GrocyLogger.info("Deleting chore was successful.")
            await updateData()
        } catch {
            GrocyLogger.error("Deleting chore failed. \(error)")
        }
    }

    var body: some View {
        if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count == 0 {
            content
        } else {
            ServerProblemView()
        }
    }

    var content: some View {
        List {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            } else if choresCount == 0 {
                ContentUnavailableView("No chore defined. Please create one.", systemImage: MySymbols.chores)
            } else if mdChores.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(mdChores, id: \.id) { chore in
                NavigationLink(value: chore) {
                    MDChoreRowView(chore: chore)
                }
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: true,
                    content: {
                        Button(
                            role: .destructive,
                            action: { deleteItem(itemToDelete: chore) },
                            label: { Label("Delete", systemImage: MySymbols.delete) }
                        )
                    }
                )
            }
        }
        #if os(iOS)
            .sheet(
                isPresented: $showAddChore,
                content: {
                    NavigationStack {
                        MDChoreFormView(isPopup: true)
                    }
                }
            )
        #else
            .navigationDestination(isPresented: $showAddChore, destination: { NavigationStack { MDChoreFormView() } })
        #endif
        .navigationDestination(
            for: MDChore.self,
            destination: { chore in
                MDChoreFormView(existingChore: chore)
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
        .alert(
            "Are you sure you want to delete chore \"\(choreToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirmation,
            actions: {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let toDelID = choreToDelete?.id {
                        Task {
                            await deleteChore(toDelID: toDelID)
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
                            showAddChore.toggle()
                        },
                        label: {
                            Label("Create chore", systemImage: MySymbols.new)
                        }
                    )
                }
            )
        })
        .navigationTitle("Chores")
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        MDChoresView()
    }
}
