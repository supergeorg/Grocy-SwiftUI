//
//  ChoreRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 09.12.25.
//

import SwiftUI

struct ChoreRowView: View {
    @Environment(\.grocyFeatures) private var features

    var chore: Chore
    var user: GrocyUser?

    @AppStorage("localizationKey") var localizationKey: String = "en"

    var body: some View {
        VStack(alignment: .leading) {
            Text(chore.choreName)
                .font(.headline)
            if let nextEstimatedExecutionTime = chore.nextEstimatedExecutionTime {
                HStack {
                    Text("\(Text("Next estimated tracking")):")
                    Spacer()
                    if chore.isRescheduled == true {
                        Image(systemName: MySymbols.choreRescheduled)
                    }
                    Text(formatDateTimeAsString(nextEstimatedExecutionTime, dateOnly: chore.trackDateOnly, localizationKey: localizationKey) ?? "")
                    Text(getRelativeDateAsText(nextEstimatedExecutionTime, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                }
            }
            if let lastTrackedTime = chore.lastTrackedTime {
                HStack {
                    Text("\(Text("Last tracked")):")
                    Spacer()
                    Text(formatDateTimeAsString(lastTrackedTime, dateOnly: chore.trackDateOnly, localizationKey: localizationKey) ?? "")
                    Text(getRelativeDateAsText(lastTrackedTime, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                }
            }
            if features.choreAssignments, let user, chore.nextExecutionAssignedToUserID == user.id {
                HStack {
                    Text("\(Text("Assigned to")):")
                    Spacer()
                    Text(user.displayName)
                }
            }

        }
        //        .listRowBackground(backgroundColor)
    }
}

#Preview(traits: .previewData) {
    List {
        ChoreRowView(chore: Chore(choreName: "Chore Past", nextEstimatedExecutionTime: Calendar.current.date(byAdding: .day, value: -1, to: Date())!))
        ChoreRowView(chore: Chore(choreName: "Chore Today", lastTrackedTime: Date(), nextEstimatedExecutionTime: Date(), isRescheduled: true))
        ChoreRowView(
            chore: Chore(
                choreName: "Chore in 3 days",
                lastTrackedTime: Date(),
                nextEstimatedExecutionTime: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
                isRescheduled: true
            )
        )
        ChoreRowView(
            chore: Chore(
                choreName: "Chore in 10 days",
                lastTrackedTime: Date(),
                nextEstimatedExecutionTime: Calendar.current.date(byAdding: .day, value: 10, to: Date())!,
                isRescheduled: true
            )
        )
        ChoreRowView(chore: Chore(choreName: "Chore for Me", nextExecutionAssignedToUserID: 1), user: GrocyUser(id: 1, displayName: "Test User"))
    }
}
