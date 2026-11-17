//
//  BatteriesFilterView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftUI

/// The filter sheet of the batteries overview, like the other overviews, next to the quick filter capsules.
struct BatteriesFilterView: View {
    @Binding var filteredStatus: BatteryStatus
    /// 0 turns the "due soon" filter off, as in Grocy.
    var dueSoonDays: Int = 5

    private var statuses: [BatteryStatus] {
        BatteryStatus.allCases.filter { $0 != .dueSoon || dueSoonDays > 0 }
    }

    var body: some View {
        List {
            Picker(
                selection: $filteredStatus,
                content: {
                    ForEach(statuses) { status in
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
                .listRowBackground(filteredStatus.backgroundColor)
            #endif
        }
    }
}

#Preview {
    @Previewable @State var filteredStatus: BatteryStatus = .all

    BatteriesFilterView(filteredStatus: $filteredStatus)
}
