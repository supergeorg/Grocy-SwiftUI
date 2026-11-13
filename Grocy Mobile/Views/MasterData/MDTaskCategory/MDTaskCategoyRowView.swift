//
//  MDTaskCategoyRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 12.12.25.
//
import SwiftUI

struct MDTaskCategoryRowView: View {
    var taskCategory: MDTaskCategory

    var body: some View {
        VStack(alignment: .leading) {
            Text(taskCategory.name)
                .font(.headline)
                .foregroundStyle(taskCategory.active ? .primary : .secondary)
            // Disabled is spelled out, not only shown by the dimmed color ("Disabled" matches the Grocy web app).
            if !taskCategory.active {
                Text("Disabled")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !taskCategory.mdTaskCategoryDescription.isEmpty {
                Text(taskCategory.mdTaskCategoryDescription)
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
        MDTaskCategoryRowView(taskCategory: MDTaskCategory(name: "Task category"))
        MDTaskCategoryRowView(taskCategory: MDTaskCategory(name: "Task category with Desc", mdTaskCategoryDescription: "Description"))
        MDTaskCategoryRowView(taskCategory: MDTaskCategory(name: "Inactive", active: false))
    }
}
