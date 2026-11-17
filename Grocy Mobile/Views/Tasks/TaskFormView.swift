//
//  TaskFormView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 20.12.25.
//

import SwiftData
import SwiftUI

struct TaskFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @AppStorage("localizationKey") var localizationKey: String = "en"

    @Query var grocyTasks: GrocyTasks
    @Query(sort: \MDTaskCategory.name, order: .forward) var mdTaskCategories: MDTaskCategories
    @Query(sort: \GrocyUser.displayName, order: .forward) var grocyUsers: GrocyUsers

    @Environment(\.dismiss) var dismiss

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var existingTask: GrocyTask? = nil
    var isPopup: Bool

    @State private var grocyTask: GrocyTask

    init(existingTask: GrocyTask? = nil, isPopup: Bool = false) {
        self.existingTask = existingTask
        self.grocyTask = existingTask ?? GrocyTask()
        self.isPopup = isPopup
    }

    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundTask = grocyTasks.first(where: { $0.name == grocyTask.name })
        return !(grocyTask.name.isEmpty || (foundTask != nil && foundTask!.id != grocyTask.id))
    }

    private let dataToUpdate: [ObjectEntities] = [.tasks, .task_categories]
    private let additionalDataToUpdate: [AdditionalEntities] = [.users]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    private var isFormValid: Bool {
        guard isNameCorrect else { return false }
        return true
    }

    private func finishForm() {
        self.dismiss()
    }

    private func saveTask() async {
        if grocyTask.id == -1 {
            do {
                grocyTask.id = try grocyVM.findNextID(.tasks)
            } catch {
                GrocyLogger.error("Failed to get next ID: \(error)")
                return
            }
        }
        isProcessing = true
        isSuccessful = nil
        do {
            try grocyTask.modelContext?.save()
            if existingTask == nil {
                _ = try await grocyVM.postMDObject(object: .tasks, content: grocyTask)
            } else {
                try await grocyVM.putMDObjectWithID(object: .tasks, id: grocyTask.id, content: grocyTask)
            }
            GrocyLogger.info("Task \(grocyTask.name) successful.")
            await updateData()
            isSuccessful = true
        } catch {
            GrocyLogger.error("Task \(grocyTask.name) failed. \(error)")
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
                textToEdit: $grocyTask.name,
                description: "Name",
                isCorrect: $isNameCorrect,
                leadingIcon: MySymbols.name,
                emptyMessage: "A name is required",
                errorMessage: "Name already exists"
            )
            .onChange(of: grocyTask.name) {
                isNameCorrect = checkNameCorrect()
            }

            MyTextEditor(
                textToEdit: $grocyTask.taskDescription,
                description: "Description",
                leadingIcon: MySymbols.description
            )

            // The switch and the date picker each get their own row, so neither is squeezed into the label's row.
            Toggle(
                isOn: Binding(
                    get: { grocyTask.dueDate != nil },
                    set: { isOn in
                        grocyTask.dueDate = isOn ? Date() : nil
                    }
                )
            ) {
                Label {
                    Text("Due")
                    if grocyTask.dueDate != nil {
                        Text(getRelativeDateAsText(grocyTask.dueDate, localizationKey: localizationKey) ?? "")
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                } icon: {
                    Image(systemName: MySymbols.date)
                        .foregroundStyle(.primary)
                }
            }

            if let dueDate = grocyTask.dueDate {
                DatePicker(
                    "Due date",
                    selection: Binding(
                        get: { dueDate },
                        set: { grocyTask.dueDate = $0 }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
            }

            Picker(
                selection: $grocyTask.categoryID,
                label: Label("Category", systemImage: MySymbols.tasks),
                content: {
                    Text("")
                        .tag(nil as Int?)
                    ForEach(mdTaskCategories, id: \.id) { taskCategory in
                        Text(taskCategory.name)
                            .tag(taskCategory.id)
                    }
                }
            )
            .foregroundStyle(.primary)

            Picker(
                selection: $grocyTask.assignedToUserID,
                label: Label("Assigned to", systemImage: MySymbols.user),
                content: {
                    Text("")
                        .tag(nil as Int?)
                    ForEach(grocyUsers, id: \.id) { user in
                        Text(user.displayName)
                            .tag(user.id)
                    }
                }
            )
            .foregroundStyle(.primary)
        }
        .formStyle(.grouped)
        .task {
            await updateData()
            self.isNameCorrect = checkNameCorrect()
        }
        .navigationTitle(existingTask == nil ? "Create task" : "Edit task")
        .toolbar(content: {
            if isPopup {
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
                            await saveTask()
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
                .disabled(!isFormValid || isProcessing)
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
        TaskFormView()
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        TaskFormView(existingTask: GrocyTask(name: "Example task"))
    }
}
