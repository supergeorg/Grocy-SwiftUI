//
//  BatteriesFilterActionsView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import SwiftUI

struct BatteriesFilterActionsView: View {
    @Binding var filteredStatus: BatteryStatus

    var numOverdue: Int?
    var numDueToday: Int?
    var numDueSoon: Int?
    /// 0 turns the "due soon" filter off, as in Grocy.
    var dueSoonDays: Int

    var body: some View {
        FilterCapsuleBar {
            BatteriesFilterCapsuleView(num: numOverdue, filteredStatus: $filteredStatus, ownFilteredStatus: .overdue, dueSoonDays: dueSoonDays)
            BatteriesFilterCapsuleView(num: numDueToday, filteredStatus: $filteredStatus, ownFilteredStatus: .dueToday, dueSoonDays: dueSoonDays)
            if dueSoonDays > 0 {
                BatteriesFilterCapsuleView(num: numDueSoon, filteredStatus: $filteredStatus, ownFilteredStatus: .dueSoon, dueSoonDays: dueSoonDays)
            }
        }
    }
}

#Preview {
    @Previewable @State var filteredStatus: BatteryStatus = .all

    BatteriesFilterActionsView(filteredStatus: $filteredStatus, numOverdue: 1, numDueToday: 2, numDueSoon: 3, dueSoonDays: 5)
}
