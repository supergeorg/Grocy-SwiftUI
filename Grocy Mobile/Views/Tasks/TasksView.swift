//
//  TasksView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 20.12.25.
//

import SwiftData
import SwiftUI

enum TasksSortOption: Hashable, Sendable {
    case byName
    case byDueDate
    case byCategory
    case byUser
}

struct TasksView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext
    @Environment(DeepLinkManager.self) private var deepLinkManager: DeepLinkManager?

    @State private var searchString: String = ""
    @State private var showingFilterSheet = false
    @State private var filteredStatus: TaskStatus = .all
    @State private var filteredTaskCategoryID: Int? = -1
    @State private var filteredUserID: Int? = nil
    @State private var sortOption: TasksSortOption = .byDueDate
    @State private var sortOrder: SortOrder = .reverse
    @State private var showDoneTasks: Bool = false

    @State private var showCreateTask: Bool = false
    /// The form for a new object zooms out of the create button.
    @Namespace private var addTransition
    @State private var taskToDelete: GrocyTask? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var deleteErrorMessage: String? = nil

    @Query var mdTaskCategories: MDTaskCategories
    @Query var grocyUsers: GrocyUsers
    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        return userSettingsList.first
    }

    var grocyTasks: GrocyTasks {
        let sortDescriptor = SortDescriptor<GrocyTask>(\.id)
        let predicate = #Predicate<GrocyTask> { task in
            searchString.isEmpty || task.name.localizedStandardContains(searchString)
        }

        let descriptor = FetchDescriptor<GrocyTask>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var tasksCount: Int {
        var descriptor = FetchDescriptor<GrocyTask>(
            sortBy: []
        )
        descriptor.fetchLimit = 0

        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private var numFilters: Int {
        var filterCount = 0
        if filteredStatus != .all { filterCount += 1 }
        if filteredTaskCategoryID != -1 { filterCount += 1 }
        if filteredUserID != nil { filterCount += 1 }
        return filterCount
    }

    private let dataToUpdate: [ObjectEntities] = [.tasks, .task_categories]
    private let additionalDataToUpdate: [AdditionalEntities] = [.current_user, .users]
    /// Applies the filter a widget link asked for.
    private func applyPendingFilter() {
        guard let deepLinkManager, let filter = deepLinkManager.pendingTaskFilter else { return }
        filteredStatus = filter
        deepLinkManager.pendingTaskFilter = nil
    }

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    var filteredTasks: [GrocyTask] {
        grocyTasks
            .filter { showDoneTasks || $0.done == false }
            .filter { filteredUserID == nil || $0.assignedToUserID == filteredUserID }
            .filter { filteredTaskCategoryID == -1 || $0.categoryID == filteredTaskCategoryID }
            .filter { matchesFilter($0) }
    }

    var taskCounts: [TaskStatus: Int] {
        Dictionary(
            uniqueKeysWithValues: TaskStatus.allCases.map { status in
                (status, grocyTasks.count(where: { matchesFilter($0, for: status) }))
            }
        )
    }

    func matchesFilter(_ grocyTask: GrocyTask, for status: TaskStatus? = nil) -> Bool {
        let targetStatus = status ?? filteredStatus

        // Don't show done items in this filter
        guard !(grocyTask.done && ![TaskStatus.all, TaskStatus.assignedToMe].contains(targetStatus)) else { return false }

        switch targetStatus {
        case .all:
            return true

        case .assignedToMe:
            return grocyTask.assignedToUserID != nil && grocyTask.assignedToUserID == grocyVM.currentUser?.id

        case .overdue:
            return daysDifference(for: grocyTask.dueDate) ?? 0 < 0

        case .dueToday:
            return daysDifference(for: grocyTask.dueDate) == 0

        case .dueSoon:
            guard let diff = daysDifference(for: grocyTask.dueDate) else { return false }
            return (0...(userSettings?.tasksDueSoonDays ?? 5)).contains(diff)
        }
    }

    private func backgroundColorForTask(_ task: GrocyTask) -> Color? {
        guard let diff = daysDifference(for: task.dueDate) else { return nil }

        switch diff {
        case ..<0:
            return Color(.GrocyColors.grocyRedBackground)
        case 0:
            return Color(.GrocyColors.grocyBlueBackground)
        case 0...(userSettings?.tasksDueSoonDays ?? 5):
            return Color(.GrocyColors.grocyYellowBackground)
        default:
            return nil
        }
    }

    var sortComparator: (GrocyTask, GrocyTask) -> Bool {
        switch sortOption {
        case .byName:
            return { a, b in
                let aName = a.name
                let bName = b.name
                let comparison = aName.localizedCaseInsensitiveCompare(bName)
                return self.sortOrder == .forward
                    ? comparison == .orderedAscending
                    : comparison == .orderedDescending
            }
        case .byDueDate:
            return { a, b in
                let aDate = a.dueDate ?? .now
                let bDate = b.dueDate ?? .now
                return self.sortOrder == .forward
                    ? aDate < bDate
                    : aDate > bDate
            }
        case .byCategory:
            return { a, b in
                let aCategoryName = self.mdTaskCategories.first(where: { $0.id == a.categoryID })?.name ?? ""
                let bCategoryName = self.mdTaskCategories.first(where: { $0.id == b.categoryID })?.name ?? ""

                // Empty strings always come last
                if aCategoryName.isEmpty && !bCategoryName.isEmpty {
                    return false
                }
                if !aCategoryName.isEmpty && bCategoryName.isEmpty {
                    return true
                }

                let comparison = aCategoryName.localizedCaseInsensitiveCompare(bCategoryName)
                return self.sortOrder == .forward
                    ? comparison == .orderedAscending
                    : comparison == .orderedDescending
            }
        case .byUser:
            return { a, b in
                let aUserName = self.grocyUsers.first(where: { $0.id == a.assignedToUserID })?.displayName ?? ""
                let bUserName = self.grocyUsers.first(where: { $0.id == b.assignedToUserID })?.displayName ?? ""

                // Empty strings always come last
                if aUserName.isEmpty && !bUserName.isEmpty {
                    return false
                }
                if !aUserName.isEmpty && bUserName.isEmpty {
                    return true
                }

                let comparison = aUserName.localizedCaseInsensitiveCompare(bUserName)
                return self.sortOrder == .forward
                    ? comparison == .orderedAscending
                    : comparison == .orderedDescending
            }
        }
    }

    private func deleteItem(itemToDelete: GrocyTask) {
        taskToDelete = itemToDelete
        showDeleteConfirmation.toggle()
    }
    private func deleteTask(toDelID: Int) async {
        do {
            try await grocyVM.deleteMDObject(object: .tasks, id: toDelID)
            GrocyLogger.info("Deleting task was successful.")
            await updateData()
        } catch {
            GrocyLogger.error("Deleting task failed. \(error)")
            if let apiError = error as? APIError {
                deleteErrorMessage = apiError.displayMessage
            } else {
                deleteErrorMessage = error.localizedDescription
            }
        }
    }

    private func trackTask(taskID: Int) async {
        do {
            let executeInfo = TaskExecuteModel(doneTime: Date().grocyDateTimeString)
            try await grocyVM.executeTask(taskID: taskID, content: executeInfo)
            GrocyLogger.info("Tracking task successful.")
            await self.updateData()
        } catch {
            GrocyLogger.error("Tracking task failed: \(error)")
        }
    }

    private func undoTask(taskID: Int) async {
        do {
            try await grocyVM.undoTask(taskID: taskID)
            GrocyLogger.info("Undo task successful.")
            await self.updateData()
        } catch {
            GrocyLogger.error("Undo task failed: \(error)")
        }
    }

    // The capsules float in a bar above the list (the navigation layer), so their glass isn't drawn inside a list row
    private var filterCapsules: some View {
        TasksFilterActionsView(
            filteredStatus: $filteredStatus,
            numOverdue: taskCounts[TaskStatus.overdue],
            numDueToday: taskCounts[TaskStatus.dueToday],
            numDueSoon: taskCounts[TaskStatus.dueSoon],
            numAssignedToMe: taskCounts[TaskStatus.assignedToMe]
        )
    }

    var body: some View {
        List {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            }
            ForEach(filteredTasks.sorted(by: sortComparator), id: \.id) { grocyTask in
                NavigationLink(value: grocyTask) {
                    TaskRowView(
                        grocyTask: grocyTask,
                        taskCategory: mdTaskCategories.first(where: { $0.id == grocyTask.categoryID }),
                        user: grocyUsers.first(where: { $0.id == grocyTask.assignedToUserID })
                    )
                }
                .listRowBackground(backgroundColorForTask(grocyTask))
                .contextMenu(menuItems: {
                    if grocyTask.done == false {
                        Button(
                            action: {
                                Task {
                                    await trackTask(taskID: grocyTask.id)
                                }
                            },
                            label: {
                                Label("Mark task as completed", systemImage: MySymbols.done)
                            }
                        )
                    } else {
                        Button(
                            action: {
                                Task {
                                    await undoTask(taskID: grocyTask.id)
                                }
                            },
                            label: {
                                Label("Undo task", systemImage: MySymbols.undo)
                            }
                        )
                    }
                    Divider()
                    Button(
                        role: .destructive,
                        action: {
                            Task {
                                deleteItem(itemToDelete: grocyTask)
                            }
                        },
                        label: {
                            Label("Delete this item", systemImage: MySymbols.delete)
                        }
                    )
                })
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: true,
                    content: {
                        Button(
                            role: .destructive,
                            action: { deleteItem(itemToDelete: grocyTask) },
                            label: { Label("Delete", systemImage: MySymbols.delete) }
                        )
                    }
                )
                .swipeActions(
                    edge: .leading,
                    allowsFullSwipe: true
                ) {
                    if grocyTask.done == false {
                        Button(
                            action: {
                                Task {
                                    await trackTask(taskID: grocyTask.id)
                                }
                            },
                            label: {
                                Label("Done", systemImage: MySymbols.done)
                            }
                        )
                        .tint(.green)
                        .accessibilityHint("Mark task as completed")
                    } else {
                        Button(
                            action: {
                                Task {
                                    await undoTask(taskID: grocyTask.id)
                                }
                            },
                            label: {
                                Label("Undo", systemImage: MySymbols.undo)
                            }
                        )
                        .tint(.gray)
                    }
                }
            }
        }
        .overlay {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count == 0 {
                if tasksCount == 0 {
                    ContentUnavailableView {
                        Label("No tasks", systemImage: MySymbols.tasks)
                    } description: {
                        Text("No task defined. Please create one.")
                    } actions: {
                        Button("Create task") {
                            showCreateTask = true
                        }
                    }
                } else if grocyTasks.isEmpty {
                    ContentUnavailableView.search
                }
            }
        }
        .refreshable {
            await updateData()
        }
        .floatingTopBar {
            filterCapsules
                .padding(.vertical, Spacing.small)
        }
        .navigationTitle("Tasks")
        .task {
            applyPendingFilter()
            await updateData()
        }
        .onChange(of: deepLinkManager?.pendingTaskFilter) { _, _ in
            applyPendingFilter()
        }
        .searchable(
            text: $searchString,
            prompt: "Search"
        )
        .animation(
            .default,
            value: grocyTasks.count
        )
        .animation(.default, value: filteredStatus)
        .sheet(isPresented: $showCreateTask) {
            NavigationStack {
                TaskFormView(isPopup: true)
            }
            #if os(iOS)
                .navigationTransition(.zoom(sourceID: ZoomTransitionID.add, in: addTransition))
            #endif
        }
        .navigationDestination(
            for: GrocyTask.self,
            destination: { grocyTask in
                TaskFormView(existingTask: grocyTask)
            }
        )
        .alert(
            "Are you sure you want to delete task \"\(taskToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirmation,
            actions: {
                Button("Cancel", role: .cancel) {}
                // No destructive role: the person chose to delete, this button carries out their intent (HIG).
                Button("Delete") {
                    if let toDelID = taskToDelete?.id {
                        Task {
                            await deleteTask(toDelID: toDelID)
                        }
                    }
                }
            },
            message: {
                Text("This can't be undone.")
            }
        )
        .alert(
            "Couldn't delete \"\(taskToDelete?.name ?? "")\"",
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
        .toolbar {
            ToolbarItem(
                placement: .primaryAction,
                content: {
                    Button(
                        action: {
                            showCreateTask.toggle()
                        },
                        label: {
                            Label("Create task", systemImage: MySymbols.new)
                        }
                    )
                }
            )
            #if os(iOS)
                .matchedTransitionSource(id: ZoomTransitionID.add, in: addTransition)
            #endif
            ToolbarItemGroup(placement: .navigation) {
                Button(
                    action: { showingFilterSheet = true },
                    label: {
                        Label("Filter", systemImage: MySymbols.filter)
                    }
                )
                .badge(numFilters)
                sortGroupMenu
                Button(
                    action: { showDoneTasks.toggle() },
                    label: {
                        Label("Show done tasks", systemImage: MySymbols.show)
                            .symbolVariant(showDoneTasks ? .fill : .none)
                    }
                )
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            NavigationStack {
                TasksFilterView(filteredStatus: $filteredStatus, filteredTaskCategoryID: $filteredTaskCategoryID, filteredUserID: $filteredUserID)
                    .navigationTitle("Filter")
                    #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(
                            placement: .confirmationAction,
                            content: {
                                Button(
                                    role: .confirm,
                                    action: {
                                        showingFilterSheet = false
                                    }
                                )
                            }
                        )
                        ToolbarItem(
                            placement: .cancellationAction,
                            content: {
                                Button(
                                    role: .destructive,
                                    action: {
                                        filteredStatus = .all
                                        filteredUserID = nil
                                        showingFilterSheet = false
                                    }
                                )
                            }
                        )
                    }
            }
            .presentationDetents([.medium])
        }
    }

    var sortGroupMenu: some View {
        Menu(
            content: {
                Picker(
                    "Sort category",
                    systemImage: MySymbols.sortCategory,
                    selection: $sortOption,
                    content: {
                        Label("Name", systemImage: MySymbols.name)
                            .labelStyle(.titleAndIcon)
                            .tag(TasksSortOption.byName)
                        Label("Due", systemImage: MySymbols.date)
                            .labelStyle(.titleAndIcon)
                            .tag(TasksSortOption.byDueDate)
                        Label("Category", systemImage: MySymbols.tasks)
                            .labelStyle(.titleAndIcon)
                            .tag(TasksSortOption.byCategory)
                        Label("Assigned to", systemImage: MySymbols.user)
                            .labelStyle(.titleAndIcon)
                            .tag(TasksSortOption.byUser)
                    }
                )
                #if os(iOS)
                    .pickerStyle(.menu)
                #else
                    .pickerStyle(.inline)
                #endif
                Picker(
                    "Sort order",
                    systemImage: MySymbols.sortOrder,
                    selection: $sortOrder,
                    content: {
                        Label("Ascending", systemImage: MySymbols.sortForward)
                            .labelStyle(.titleAndIcon)
                            .tag(SortOrder.forward)
                        Label("Descending", systemImage: MySymbols.sortReverse)
                            .labelStyle(.titleAndIcon)
                            .tag(SortOrder.reverse)
                    }
                )
                #if os(iOS)
                    .pickerStyle(.menu)
                #else
                    .pickerStyle(.inline)
                #endif
            },
            label: {
                Label("Sort", systemImage: MySymbols.sort)
            }
        )
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        TasksView()
    }
}
