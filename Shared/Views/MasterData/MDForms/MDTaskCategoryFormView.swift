//
//  MDTaskCategoryForm.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 12.03.21.
//

import SwiftUI

struct MDTaskCategoryFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var name: String = ""
    @State private var mdTaskCategoryDescription: String = ""
    
    var isNewTaskCategory: Bool
    var taskCategory: MDTaskCategory?
    
    @Binding var showAddTaskCategory: Bool
    @Binding var toastType: ToastType?
    
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
    private func updateData() {
        grocyVM.requestData(objects: dataToUpdate)
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
    
    private func saveTaskCategory() {
        let id = isNewTaskCategory ? grocyVM.findNextID(.task_categories) : taskCategory!.id
        let timeStamp = isNewTaskCategory ? Date().iso8601withFractionalSeconds : taskCategory!.rowCreatedTimestamp
        let taskCategoryPOST = MDTaskCategory(id: id, name: name, mdTaskCategoryDescription: mdTaskCategoryDescription, rowCreatedTimestamp: timeStamp)
        isProcessing = true
        if isNewTaskCategory {
            grocyVM.postMDObject(object: .task_categories, content: taskCategoryPOST, completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog("Task category add successful. \(message)", type: .info)
                    toastType = .successAdd
                    resetForm()
                    updateData()
                    finishForm()
                case let .failure(error):
                    grocyVM.postLog("Task category add failed. \(error)", type: .error)
                    toastType = .failAdd
                }
                isProcessing = false
            })
        } else {
            grocyVM.putMDObjectWithID(object: .task_categories, id: id, content: taskCategoryPOST, completion: { result in
                switch result {
                case let .success(message):
                    grocyVM.postLog("Task category edit successful. \(message)", type: .info)
                    toastType = .successEdit
                    updateData()
                    finishForm()
                case let .failure(error):
                    grocyVM.postLog("Task category edit failed. \(error)", type: .error)
                    toastType = .failEdit
                }
                isProcessing = false
            })
        }
    }
    
    var body: some View {
        content
            .navigationTitle(isNewTaskCategory ? LocalizedStringKey("str.md.taskCategory.new") : LocalizedStringKey("str.md.taskCategory.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    if isNewTaskCategory {
                        Button(LocalizedStringKey("str.cancel")) {
                            finishForm()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveTaskCategory, label: {
                        Label(LocalizedStringKey("str.md.taskCategory.save"), systemImage: MySymbols.save)
                            .labelStyle(.titleAndIcon)
                    })
                        .disabled(!isNameCorrect || isProcessing)
                        .keyboardShortcut(.defaultAction)
                }
            })
    }
    
    var content: some View {
        Form {
#if os(macOS)
            Text(isNewTaskCategory ? LocalizedStringKey("str.md.taskCategory.new") : LocalizedStringKey("str.md.taskCategory.edit"))
                .font(.title)
                .bold()
                .padding(.bottom, 20.0)
#endif
            Section(header: Text(LocalizedStringKey("str.md.taskCategory.info"))){
                MyTextField(textToEdit: $name, description: "str.md.taskCategory.name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "str.md.productGroup.name.required", errorMessage: "str.md.taskCategory.name.exists")
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
                MyTextField(textToEdit: $mdTaskCategoryDescription, description: "str.md.description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
            }
        }
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestData(objects: dataToUpdate)
                resetForm()
                firstAppear = false
            }
        })
    }
}

struct MDTaskCategoryFormView_Previews: PreviewProvider {
    static var previews: some View {
#if os(macOS)
        Group {
            MDTaskCategoryFormView(isNewTaskCategory: true, showAddTaskCategory: Binding.constant(true), toastType: Binding.constant(nil))
            MDTaskCategoryFormView(isNewTaskCategory: false, taskCategory: MDTaskCategory(id: 0, name: "Name", mdTaskCategoryDescription: "Description", rowCreatedTimestamp: ""), showAddTaskCategory: Binding.constant(true), toastType: Binding.constant(nil))
        }
#else
        Group {
            NavigationView {
                MDTaskCategoryFormView(isNewTaskCategory: true, showAddTaskCategory: Binding.constant(true), toastType: Binding.constant(nil))
            }
            NavigationView {
                MDTaskCategoryFormView(isNewTaskCategory: false, taskCategory: MDTaskCategory(id: 0, name: "Name", mdTaskCategoryDescription: "Description", rowCreatedTimestamp: ""), showAddTaskCategory: Binding.constant(true), toastType: Binding.constant(nil))
            }
        }
#endif
    }
}
