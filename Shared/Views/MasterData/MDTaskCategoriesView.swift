//
//  MDTaskCategoriesView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDTaskCategoryRowView: View {
    var taskCategory: MDTaskCategory
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(taskCategory.name)
                .font(.title)
            if let description = taskCategory.mdTaskCategoryDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
            }
        }
        .multilineTextAlignment(.leading)
    }
}

struct MDTaskCategoriesView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @State private var searchString: String = ""
    @State private var showAddTaskCategory: Bool = false
    
    @State private var shownEditPopover: MDTaskCategory? = nil
    
    @State private var taskCategoryToDelete: MDTaskCategory? = nil
    @State private var showDeleteAlert: Bool = false
    
    @State private var toastType: ToastType?
    
    private let dataToUpdate: [ObjectEntities] = [.task_categories]
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private var filteredTaskCategories: MDTaskCategories {
        grocyVM.mdTaskCategories
            .filter {
                searchString.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchString)
            }
    }
    
    private func deleteItem(itemToDelete: MDTaskCategory) {
        taskCategoryToDelete = itemToDelete
        showDeleteAlert.toggle()
    }
    private func deleteTaskCategory(toDelID: Int) {
        //        grocyVM.deleteMDObject(object: .task_categories, id: toDelID, completion: { result in
        //            switch result {
        //            case let .success(message):
        //                grocyVM.postLog("Deleting task category was successful. \(message)", type: .info)
        //                updateData()
        //            case let .failure(error):
        //                grocyVM.postLog("Deleting task category failed. \(error)", type: .error)
        //                toastType = .failDelete
        //            }
        //        })
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.filter({dataToUpdate.contains($0)}).count == 0 {
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
                .navigationTitle(LocalizedStringKey("str.md.taskCategories"))
        }
    }
    
    var bodyContent: some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
#if os(macOS)
                    //                    RefreshButton(updateData: { updateData() })
#endif
                    Button(action: {
                        showAddTaskCategory.toggle()
                    }, label: {Image(systemName: MySymbols.new)})
                }
            }
            .navigationTitle(LocalizedStringKey("str.md.taskCategories"))
#if os(iOS)
            .sheet(isPresented: self.$showAddTaskCategory, content: {
                NavigationView {
                    MDTaskCategoryFormView(isNewTaskCategory: true, showAddTaskCategory: $showAddTaskCategory, toastType: $toastType)
                }
            })
#endif
    }
    
    var content: some View {
        List{
            if grocyVM.mdTaskCategories.isEmpty {
                Text(LocalizedStringKey("str.md.taskCategories.empty"))
            } else if filteredTaskCategories.isEmpty {
                Text(LocalizedStringKey("str.noSearchResult"))
            }
#if os(macOS)
            if showAddTaskCategory {
                NavigationLink(destination: MDTaskCategoryFormView(isNewTaskCategory: true, showAddTaskCategory: $showAddTaskCategory, toastType: $toastType), isActive: $showAddTaskCategory, label: {
                    NewMDRowLabel(title: "str.md.taskCategory.new")
                })
            }
#endif
            ForEach(filteredTaskCategories, id:\.id) { taskCategory in
                NavigationLink(destination: MDTaskCategoryFormView(isNewTaskCategory: false, taskCategory: taskCategory, showAddTaskCategory: $showAddTaskCategory, toastType: $toastType)) {
                    MDTaskCategoryRowView(taskCategory: taskCategory)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                    Button(role: .destructive,
                           action: { deleteItem(itemToDelete: taskCategory) },
                           label: { Label(LocalizedStringKey("str.delete"), systemImage: MySymbols.delete) }
                    )
                })
            }
        }
        .task {
            await updateData()
        }
        .searchable(text: $searchString, prompt: LocalizedStringKey("str.search"))
        .refreshable {
            await updateData()
        }
        .animation(.default, value: filteredTaskCategories.count)
        .toast(
            item: $toastType,
            isSuccess: Binding.constant(toastType == .successAdd || toastType == .successEdit),
            isShown: [.successAdd, .failAdd, .successEdit, .failEdit, .failDelete].contains(toastType),
            text: { item in
                switch item {
                case .successAdd:
                    return LocalizedStringKey("str.md.new.success")
                case .failAdd:
                    return LocalizedStringKey("str.md.new.fail")
                case .successEdit:
                    return LocalizedStringKey("str.md.edit.success")
                case .failEdit:
                    return LocalizedStringKey("str.md.edit.fail")
                case .failDelete:
                    return LocalizedStringKey("str.md.delete.fail")
                default:
                    return LocalizedStringKey("str.error")
                }
            })
        .alert(LocalizedStringKey("str.md.taskCategory.delete.confirm"), isPresented: $showDeleteAlert, actions: {
            Button(LocalizedStringKey("str.cancel"), role: .cancel) { }
            Button(LocalizedStringKey("str.delete"), role: .destructive) {
                if let toDelID = taskCategoryToDelete?.id {
                    deleteTaskCategory(toDelID: toDelID)
                }
            }
        }, message: { Text(taskCategoryToDelete?.name ?? "Name not found") })
    }
}

struct MDTaskCategoriesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            //            MDTaskCategoryRowView(taskCategory: MDTaskCategory(id: "0", name: "Name", mdTaskCategoryDescription: "Description", rowCreatedTimestamp: "", userfields: nil))
#if os(macOS)
            MDTaskCategoriesView()
#else
            NavigationView() {
                MDTaskCategoriesView()
            }
#endif
        }
    }
}
