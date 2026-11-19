//
//  ChoresFilterView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 11.12.25.
//

import SwiftData
import SwiftUI

struct ChoresFilterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.grocyFeatures) private var features

    @Query(sort: \GrocyUser.displayName, order: .forward) var users: GrocyUsers

    @Binding var filteredStatus: ChoreStatus
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
                    ForEach(ChoreStatus.allCases.filter { features.choreAssignments || $0 != .assignedToMe }, id: \.caseName) { status in
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
            if features.choreAssignments {
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
}

#Preview(traits: .previewData) {
    @Previewable @State var filteredStatus: ChoreStatus = .all
    @Previewable @State var filteredUserID: Int? = 1

    ChoresFilterView(filteredStatus: $filteredStatus, filteredUserID: $filteredUserID)
}
