//
//  HouseholdView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 15.11.26.
//

import SwiftData
import SwiftUI

/// Chores and tasks in one tab (iPhone navigation prototype), switched with the navigation title menu
/// ("Chores overview ▾"). Each section is the existing screen, so filters, rows and forms stay the same.
/// A segmented control in the navigation bar collided with the screens' own toolbar buttons.
struct HouseholdView: View {
    enum Section: String, CaseIterable, Identifiable {
        case chores, tasks

        var id: Self { self }

        var title: LocalizedStringKey {
            switch self {
            case .chores: "Chores"
            case .tasks: "Tasks"
            }
        }
    }

    @Binding var section: Section

    @Query private var systemConfigList: [SystemConfig]
    private var systemConfig: SystemConfig? { systemConfigList.first }

    /// Sections whose feature is enabled on the server.
    private var availableSections: [Section] {
        Section.allCases.filter { section in
            switch section {
            case .chores: systemConfig?.featureFlagChores != false
            case .tasks: systemConfig?.featureFlagTasks != false
            }
        }
    }

    var body: some View {
        Group {
            switch section {
            case .chores:
                ChoresView()
            case .tasks:
                TasksView()
            }
        }
        // The title menu needs the inline title.
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbarTitleMenu {
            if availableSections.count > 1 {
                Picker("Household", selection: $section) {
                    ForEach(availableSections) { section in
                        Text(section.title).tag(section)
                    }
                }
            }
        }
        .onAppear {
            if let first = availableSections.first, !availableSections.contains(section) {
                section = first
            }
        }
    }
}

#Preview(traits: .previewData) {
    @Previewable @State var section: HouseholdView.Section = .chores
    NavigationStack {
        HouseholdView(section: $section)
    }
}
