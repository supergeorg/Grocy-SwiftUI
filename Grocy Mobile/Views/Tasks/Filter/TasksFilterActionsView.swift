//
//  TasksFilterActionsView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 20.12.25.
//

import SwiftData
import SwiftUI

struct TasksFilterActionsView: View {
    @Binding var filteredStatus: TaskStatus

    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        return userSettingsList.first
    }

    var numOverdue: Int?
    var numDueToday: Int?
    var numDueSoon: Int?
    var numAssignedToMe: Int?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TasksFilterCapsuleView(num: numOverdue, filteredStatus: $filteredStatus, ownFilteredStatus: TaskStatus.overdue, color: Color(.GrocyColors.grocyRed), backgroundColor: Color(.GrocyColors.grocyRedBackground), dueSoonDays: userSettings?.tasksDueSoonDays)
                TasksFilterCapsuleView(num: numDueToday, filteredStatus: $filteredStatus, ownFilteredStatus: TaskStatus.dueToday, color: Color(.GrocyColors.grocyBlue), backgroundColor: Color(.GrocyColors.grocyBlueBackground), dueSoonDays: userSettings?.tasksDueSoonDays)
                TasksFilterCapsuleView(num: numDueSoon, filteredStatus: $filteredStatus, ownFilteredStatus: TaskStatus.dueSoon, color: Color(.GrocyColors.grocyYellow), backgroundColor: Color(.GrocyColors.grocyYellowBackground), dueSoonDays: userSettings?.tasksDueSoonDays)
                TasksFilterCapsuleView(num: numAssignedToMe, filteredStatus: $filteredStatus, ownFilteredStatus: TaskStatus.assignedToMe, color: Color(.GrocyColors.grocyGray), backgroundColor: Color(.GrocyColors.grocyGrayBackground), dueSoonDays: userSettings?.tasksDueSoonDays)
            }
            .padding(.horizontal)
        }
        .scrollClipDisabled()
    }
}

#Preview {
    @Previewable @State var filteredStatus: ChoreStatus = .all

    ChoresFilterActionsView(filteredStatus: $filteredStatus, numOverdue: 1, numDueToday: 2, numDueSoon: 3, numAssignedToMe: 4)
}
