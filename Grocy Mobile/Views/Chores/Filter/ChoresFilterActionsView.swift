//
//  ChoresFilterActionsView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 11.12.25.
//

import SwiftData
import SwiftUI

struct ChoresFilterActionsView: View {
    @Binding var filteredStatus: ChoreStatus

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
                ChoresFilterCapsuleView(num: numOverdue, filteredStatus: $filteredStatus, ownFilteredStatus: ChoreStatus.overdue, color: Color(.GrocyColors.grocyRed), backgroundColor: Color(.GrocyColors.grocyRedBackground), dueSoonDays: userSettings?.choresDueSoonDays)
                ChoresFilterCapsuleView(num: numDueToday, filteredStatus: $filteredStatus, ownFilteredStatus: ChoreStatus.dueToday, color: Color(.GrocyColors.grocyBlue), backgroundColor: Color(.GrocyColors.grocyBlueBackground), dueSoonDays: userSettings?.choresDueSoonDays)
                ChoresFilterCapsuleView(num: numDueSoon, filteredStatus: $filteredStatus, ownFilteredStatus: ChoreStatus.dueSoon, color: Color(.GrocyColors.grocyYellow), backgroundColor: Color(.GrocyColors.grocyYellowBackground), dueSoonDays: userSettings?.choresDueSoonDays)
                ChoresFilterCapsuleView(num: numAssignedToMe, filteredStatus: $filteredStatus, ownFilteredStatus: ChoreStatus.assignedToMe, color: Color(.GrocyColors.grocyGray), backgroundColor: Color(.GrocyColors.grocyGrayBackground), dueSoonDays: userSettings?.choresDueSoonDays)
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
