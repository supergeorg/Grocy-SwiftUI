//
//  MDStoresView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftData
import SwiftUI

import SwiftData
import SwiftUI

struct MDTaskCategoryFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query(sort: \MDTaskCategory.name, order: .forward) var mdTaskCategories: MDTaskCategories

    @Environment(\.dismiss) var dismiss

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var existingTaskCategory: MDTaskCategory?
    @State private var taskCategory: MDTaskCategory

    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundTaskCategory = mdTaskCategories.first(where: { $0.name == taskCategory.name })
        return !(taskCategory.name.isEmpty || (foundTaskCategory != nil && foundTaskCategory!.id != taskCategory.id))
    }

    init(existingTaskCategory: MDTaskCategory? = nil) {
        self.existingTaskCategory = existingTaskCategory
        self.taskCategory = existingTaskCategory ?? MDTaskCategory()
    }

    private let dataToUpdate: [ObjectEntities] = [.task_categories]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func finishForm() {
        self.dismiss()
    }

    private func saveTaskCategory() async {
        if taskCategory.id == -1 {
            do {
                taskCategory.id = try grocyVM.findNextID(.task_categories)
            } catch {
                GrocyLogger.error("Failed to get next ID: \(error)")
                return
            }
        }
        isProcessing = true
        isSuccessful = nil
        do {
            try taskCategory.modelContext?.save()
            if existingTaskCategory == nil {
                _ = try await grocyVM.postMDObject(object: .task_categories, content: taskCategory)
            } else {
                try await grocyVM.putMDObjectWithID(object: .task_categories, id: taskCategory.id, content: taskCategory)
            }
            GrocyLogger.info("Task category \(taskCategory.name) successful.")
            await updateData()
            isSuccessful = true
        } catch {
            GrocyLogger.error("Task category \(taskCategory.name) failed. \(error)")
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
            isSuccessful = false
        }
        isProcessing = false
    }

    var body: some View {
        Form {
            if isSuccessful == false, let errorMessage = errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            MyTextField(
                textToEdit: $taskCategory.name,
                description: "Name",
                isCorrect: $isNameCorrect,
                leadingIcon: MySymbols.name,
                emptyMessage: "A name is required",
                errorMessage: "Name already exists"
            )
            .onChange(of: taskCategory.name) {
                isNameCorrect = checkNameCorrect()
            }
            MyToggle(
                isOn: $taskCategory.active,
                description: "Active",
                icon: MySymbols.active
            )
            MyTextEditor(
                textToEdit: $taskCategory.mdTaskCategoryDescription,
                description: "Description",
                leadingIcon: MySymbols.description
            )
        }
        .formStyle(.grouped)
        .task {
            await updateData()
            self.isNameCorrect = checkNameCorrect()
        }
        .navigationTitle(existingTaskCategory == nil ? "Create task category" : "Edit task category")
        .toolbar(content: {
            if existingTaskCategory == nil {
                ToolbarItem(
                    placement: .cancellationAction,
                    content: {
                        Button(
                            role: .cancel,
                            action: {
                                finishForm()
                            }
                        )
                        .keyboardShortcut(.cancelAction)
                    }
                )
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(
                    role: .confirm,
                    action: {
                        Task {
                            await saveTaskCategory()
                        }
                    },
                    label: {
                        if !isProcessing {
                            // Label style is left to the system, so the confirm button gets the standard Liquid Glass look.
                            Label("Save", systemImage: MySymbols.save)
                        } else {
                            ProgressView().progressViewStyle(.circular)
                        }
                    }
                )
                .disabled(!isNameCorrect || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        })
        .onChange(of: isSuccessful) {
            if isSuccessful == true {
                finishForm()
            }
        }
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }
}

#Preview("Create", traits: .previewData) {
    NavigationStack {
        MDTaskCategoryFormView()
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        MDTaskCategoryFormView(existingTaskCategory: MDTaskCategory(name: "Task category"))
    }
}
