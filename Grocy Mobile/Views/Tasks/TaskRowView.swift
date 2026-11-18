//
//  TaskRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 20.12.25.
//

import SwiftUI

struct TaskRowView: View {
    var grocyTask: GrocyTask
    var taskCategory: MDTaskCategory?
    var user: GrocyUser?

    @AppStorage("localizationKey") var localizationKey: String = "en"

    var body: some View {
        VStack(alignment: .leading) {
            Text(grocyTask.name)
                .font(.headline)
                .foregroundStyle(grocyTask.done ? .secondary : .primary)
                .strikethrough(grocyTask.done, color: .secondary)
            if !grocyTask.taskDescription.isEmpty {
                Text(grocyTask.taskDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let dueDate = grocyTask.dueDate {
                HStack {
                    Text("\(Text("Due")):")
                    Spacer()
                    Text(formatDateAsString(dueDate, showTime: dueDate.hasTimeComponent ? true : false, localizationKey: localizationKey) ?? "")
                    Text(getRelativeDateAsText(dueDate, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                }

            }
            if let categoryName = taskCategory?.name {
                HStack {
                    Text("\(Text("Category")):")
                    Spacer()
                    Text(categoryName)
                }
            }

            if let user, grocyTask.assignedToUserID == user.id {
                HStack {
                    Text("\(Text("Assigned to")):")
                    Spacer()
                    Text(user.displayName)
                }
            }

        }
        // Done is announced, not only shown by the strikethrough and the dimmed color.
        .accessibilityElement(children: .combine)
        .accessibilityValue(grocyTask.done ? Text("Done") : Text(""))
    }
}

#Preview(traits: .previewData) {
    List {
        TaskRowView(grocyTask: GrocyTask(name: "Task Past", dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!))
        TaskRowView(grocyTask: GrocyTask(name: "Task Today", dueDate: Date()))
        TaskRowView(grocyTask: GrocyTask(name: "Task in 3 days", dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!))
        TaskRowView(grocyTask: GrocyTask(name: "Task in 10 days", dueDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!))
        TaskRowView(grocyTask: GrocyTask(name: "Task for Me", dueDate: Date()), user: GrocyUser(id: 1, displayName: "Test User"))
    }
}
