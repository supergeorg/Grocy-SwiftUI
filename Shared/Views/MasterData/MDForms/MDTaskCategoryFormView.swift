//
//  MDTaskCategoryForm.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 12.03.21.
//

import SwiftUI

struct MDTaskCategoryFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var name: String = ""
    @State private var mdTaskCategoryDescription: String = ""
    
    var isNewTaskCategory: Bool
    var taskCategory: MDTaskCategory?
    
    @Binding var showAddTaskCategory: Bool
    
    
    @State private var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundTaskCategory = grocyVM.mdTaskCategories.first(where: {$0.name == name})
        if isNewTaskCategory {
            return !(name.isEmpty || foundTaskCategory != nil)
        } else {
            if let taskCategory = taskCategory, let foundTaskCategory = foundTaskCategory {
                return !(name.isEmpty || (foundTaskCategory.id != taskCategory.id))
            } else { return false }
        }
    }
    
    private func resetForm() {
        self.name = taskCategory?.name ?? ""
        self.mdTaskCategoryDescription = taskCategory?.mdTaskCategoryDescription ?? ""
        isNameCorrect = checkNameCorrect()
    }
    
    private let dataToUpdate: [ObjectEntities] = [.task_categories]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private func finishForm() {
#if os(iOS)
        self.dismiss()
#elseif os(macOS)
        if isNewTaskCategory {
            showAddTaskCategory = false
        }
#endif
    }
    
    private func saveTaskCategory() async {
        let id = isNewTaskCategory ? grocyVM.findNextID(.task_categories) : taskCategory!.id
        let timeStamp = isNewTaskCategory ? Date().iso8601withFractionalSeconds : taskCategory!.rowCreatedTimestamp
        let taskCategoryPOST = MDTaskCategory(id: id, name: name, mdTaskCategoryDescription: mdTaskCategoryDescription, rowCreatedTimestamp: timeStamp)
        isProcessing = true
        if isNewTaskCategory {
            do {
                _ = try await grocyVM.postMDObject(object: .task_categories, content: taskCategoryPOST)
                grocyVM.postLog("Task category add successful.", type: .info)
                resetForm()
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Task category add failed. \(error)", type: .error)
            }
        } else {
            do {
                try await grocyVM.putMDObjectWithID(object: .task_categories, id: id, content: taskCategoryPOST)
                grocyVM.postLog("Task category edit successful.", type: .info)
                await updateData()
                finishForm()
            } catch {
                grocyVM.postLog("Task category edit failed. \(error)", type: .error)
            }
        }
        isProcessing = false
    }
    
    var body: some View {
        content
            .navigationTitle(isNewTaskCategory ? "Create task category" : "Edit task category")
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { Task { await saveTaskCategory() } }, label: {
                        Label("Save task category", systemImage: MySymbols.save)
                            .labelStyle(.titleAndIcon)
                    })
                    .disabled(!isNameCorrect || isProcessing)
                    .keyboardShortcut(.defaultAction)
                }
#if os(iOS)
                ToolbarItem(placement: .cancellationAction) {
                    if isNewTaskCategory {
                        Button("Cancel") {
                            finishForm()
                        }
                    }
                }
#endif
            })
    }
    
    var content: some View {
        Form {
#if os(macOS)
            Text(isNewTaskCategory ? "Create task category" : "Edit task category")
                .font(.title)
                .bold()
                .padding(.bottom, 20.0)
#endif
            Section(header: Text("Task category info")){
                MyTextField(textToEdit: $name, description: "Task category name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "A name is required", errorMessage: "Name already exists")
                    .onChange(of: name) {
                        isNameCorrect = checkNameCorrect()
                    }
                MyTextField(textToEdit: $mdTaskCategoryDescription, description: "Description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
            }
        }
        .task {
            if firstAppear {
                await updateData()
                resetForm()
                firstAppear = false
            }
        }
    }
}

//struct MDTaskCategoryFormView_Previews: PreviewProvider {
//    static var previews: some View {
//#if os(macOS)
//        Group {
//            MDTaskCategoryFormView(isNewTaskCategory: true, showAddTaskCategory: Binding.constant(true))
//            MDTaskCategoryFormView(isNewTaskCategory: false, taskCategory: MDTaskCategory(id: 0, name: "Name", mdTaskCategoryDescription: "Description", rowCreatedTimestamp: ""), showAddTaskCategory: Binding.constant(true))
//        }
//#else
//        Group {
//            NavigationView {
//                MDTaskCategoryFormView(isNewTaskCategory: true, showAddTaskCategory: Binding.constant(true))
//            }
//            NavigationView {
//                MDTaskCategoryFormView(isNewTaskCategory: false, taskCategory: MDTaskCategory(id: 0, name: "Name", mdTaskCategoryDescription: "Description", rowCreatedTimestamp: ""), showAddTaskCategory: Binding.constant(true))
//            }
//        }
//#endif
//    }
//}
