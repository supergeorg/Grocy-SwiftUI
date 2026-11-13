//
//  MDTaskCategoriesView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftData
import SwiftUI

struct MDTaskCategoriesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext

    @State private var searchString: String = ""
    @State private var showAddTaskCategory: Bool = false

    @State private var taskCategoryToDelete: MDTaskCategory? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var deleteErrorMessage: String? = nil

    private let dataToUpdate: [ObjectEntities] = [.task_categories]

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    // Fetch the data with a dynamic predicate
    var mdTaskCategories: MDTaskCategories {
        let sortDescriptor = SortDescriptor<MDTaskCategory>(\.name)
        let predicate =
            searchString.isEmpty
            ? nil
            : #Predicate<MDTaskCategory> { category in
                searchString == "" ? true : category.name.localizedStandardContains(searchString)
            }

        let descriptor = FetchDescriptor<MDTaskCategory>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // Get the unfiltered count without fetching any data
    var mdTaskCategoriesCount: Int {
        var descriptor = FetchDescriptor<MDTaskCategory>(
            sortBy: []
        )
        descriptor.fetchLimit = 0

        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private func deleteItem(itemToDelete: MDTaskCategory) {
        taskCategoryToDelete = itemToDelete
        showDeleteConfirmation.toggle()
    }
    private func deleteTaskCategory(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .task_categories, id: toDelID)
            GrocyLogger.info("Deleting task category was successful.")
            await updateData()
        } catch {
            GrocyLogger.error("Deleting task category failed. \(error)")
            if let apiError = error as? APIError {
                deleteErrorMessage = apiError.displayMessage
            } else {
                deleteErrorMessage = error.localizedDescription
            }
        }
    }

    var body: some View {
        List {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            } else if mdTaskCategoriesCount == 0 {
                ContentUnavailableView {
                    Label("No task categories", systemImage: MySymbols.tasks)
                } description: {
                    Text("No task category defined. Please create one.")
                } actions: {
                    Button("Create task category") {
                        showAddTaskCategory = true
                    }
                }
            } else if mdTaskCategories.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(mdTaskCategories, id: \.id) { taskCategory in
                NavigationLink(value: taskCategory) {
                    MDTaskCategoryRowView(taskCategory: taskCategory)
                }
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: true,
                    content: {
                        Button(
                            role: .destructive,
                            action: { deleteItem(itemToDelete: taskCategory) },
                            label: { Label("Delete", systemImage: MySymbols.delete) }
                        )
                    }
                )
            }
        }
        #if os(iOS)
            .sheet(
                isPresented: $showAddTaskCategory,
                content: {
                    NavigationStack {
                        MDTaskCategoryFormView()
                    }
                }
            )
        #else
            .navigationDestination(isPresented: $showAddTaskCategory, destination: { MDTaskCategoryFormView() })
        #endif
        .navigationTitle("Task categories")
        .navigationDestination(
            for: MDTaskCategory.self,
            destination: { taskCategory in
                MDTaskCategoryFormView(existingTaskCategory: taskCategory)
            }
        )
        .task {
            await updateData()
        }
        .refreshable {
            await updateData()
        }
        .searchable(text: $searchString, prompt: "Search")
        .toolbar(content: {
            ToolbarItemGroup(
                placement: .primaryAction,
                content: {
                    Button(
                        action: {
                            showAddTaskCategory.toggle()
                        },
                        label: {
                            Label("Create task category", systemImage: MySymbols.new)
                        }
                    )
                }
            )
        })
        .alert(
            "Are you sure you want to delete task category \"\(taskCategoryToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirmation,
            actions: {
                Button("Cancel", role: .cancel) {}
                // No destructive role: the person chose to delete, this button carries out their intent (HIG).
                Button("Delete") {
                    if let toDelID = taskCategoryToDelete?.id {
                        Task {
                            await deleteTaskCategory(toDelID: toDelID)
                        }
                    }
                }
            },
            message: {
                Text("This can't be undone.")
            }
        )
        .alert(
            "Couldn't delete \"\(taskCategoryToDelete?.name ?? "")\"",
            isPresented: Binding(
                get: { deleteErrorMessage != nil },
                set: { if !$0 { deleteErrorMessage = nil } }
            ),
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text(deleteErrorMessage ?? "")
            }
        )
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        MDTaskCategoriesView()
    }
}
