//
//  TasksFilterView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 20.12.25.
//

import SwiftData
import SwiftUI

struct TasksFilterView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \MDTaskCategory.name, order: .forward) var mdTaskCategories: MDTaskCategories
    @Query(sort: \GrocyUser.displayName, order: .forward) var users: GrocyUsers

    @Binding var filteredStatus: TaskStatus
    @Binding var filteredTaskCategoryID: Int?
    @Binding var filteredUserID: Int?

    private var rowBackground: Color? {
        switch filteredStatus {
        case .all: return nil
        case .overdue: return Color(.GrocyColors.grocyRedBackground)
        case .dueToday: return Color(.GrocyColors.grocyBlueBackground)
        case .dueSoon: return Color(.GrocyColors.grocyYellowBackground)
        case .assignedToMe: return Color(.GrocyColors.grocyGrayBackground)
        }
    }

    var body: some View {
        List {
            Picker(
                selection: $filteredStatus,
                content: {
                    ForEach(TaskStatus.allCases, id: \.caseName) { status in
                        Text(status.title)
                            .tag(status)
                    }
                },
                label: {
                    Label("Status", systemImage: MySymbols.filter)
                        .foregroundStyle(.primary)
                }
            )
            #if os(iOS)
                .id(filteredStatus)
                .listRowBackground(rowBackground)
            #endif
            Picker(
                selection: $filteredTaskCategoryID,
                content: {
                    Text("All")
                        .tag(-1 as Int?)
                    ForEach(mdTaskCategories, id: \.id) { taskCategory in
                        Text(taskCategory.name)
                            .tag(taskCategory.id)
                    }
                    Text("Uncategorized")
                        .tag(nil as Int?)
                },
                label: {
                    Label("Category", systemImage: MySymbols.tasks)
                        .foregroundStyle(.primary)
                }
            )
            Picker(
                selection: $filteredUserID,
                content: {
                    Text("All")
                        .tag(nil as Int?)
                    ForEach(users) { user in
                        Text(user.displayName)
                            .tag(user.id)
                    }
                },
                label: {
                    Label("Assignment", systemImage: MySymbols.user)
                        .foregroundStyle(.primary)
                }
            )
        }
    }
}

#Preview(traits: .previewData) {
    @Previewable @State var filteredStatus: TaskStatus = .all
    @Previewable @State var filteredTaskCategoryID: Int? = nil
    @Previewable @State var filteredUserID: Int? = nil

    TasksFilterView(filteredStatus: $filteredStatus, filteredTaskCategoryID: $filteredTaskCategoryID, filteredUserID: $filteredUserID)
}
