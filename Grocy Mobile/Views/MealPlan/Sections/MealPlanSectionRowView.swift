//
//  MealPlanSectionRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import SwiftUI

struct MealPlanSectionRowView: View {
    var section: MDMealPlanSection

    var body: some View {
        VStack(alignment: .leading) {
            Text(section.name)
                .font(.headline)
            if !section.timeInfo.isEmpty {
                Text(section.timeInfo)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        MealPlanSectionRowView(section: MDMealPlanSection(id: 1, name: "Breakfast", sortNumber: 10))
        MealPlanSectionRowView(section: MDMealPlanSection(id: 2, name: "Lunch", sortNumber: 20, timeInfo: "12:30"))
    }
}
