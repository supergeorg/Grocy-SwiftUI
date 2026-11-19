//
//  ChoreLogRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 11.12.25.
//

import SwiftUI

struct ChoreLogRowView: View {
    var choreLogEntry: ChoreLogEntry
    var chore: Chore?
    var user: GrocyUser?

    @AppStorage("localizationKey") var localizationKey: String = "en"

    var body: some View {
        VStack(alignment: .leading) {
            Text(chore?.choreName ?? "")
                .font(.headline)
                .italic(choreLogEntry.skipped)
                .foregroundStyle(!choreLogEntry.undone ? .primary : .secondary)
                .strikethrough(choreLogEntry.undone, color: .secondary)
            if choreLogEntry.undone {
                HStack {
                    Text("\(Text("Undone on")):")
                    Spacer()
                    Text(formatDateTimeAsString(choreLogEntry.undoneTimestamp, localizationKey: localizationKey) ?? "")
                    Text(getRelativeDateAsText(choreLogEntry.undoneTimestamp, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                }
            }
            if let trackedTime = choreLogEntry.trackedTime {
                HStack {
                    Text("\(Text("Tracked time")):")
                    Spacer()
                    Text(formatDateTimeAsString(trackedTime, dateOnly: chore?.trackDateOnly ?? false, localizationKey: localizationKey) ?? "")
                    Text(getRelativeDateAsText(trackedTime, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                    if choreLogEntry.skipped {
                        Text("Skipped")
                            .italic()
                    }
                }
            }
            if let scheduledExecutionTime = choreLogEntry.scheduledExecutionTime {
                HStack {
                    Text("\(Text("Scheduled tracking time")):")
                    Spacer()
                    Text(formatDateTimeAsString(scheduledExecutionTime, dateOnly: chore?.trackDateOnly ?? false, localizationKey: localizationKey) ?? "")
                    Text(getRelativeDateAsText(scheduledExecutionTime, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                }
            }
            if let user {
                HStack {
                    Text("\(Text("Done by")):")
                    Spacer()
                    Text(user.displayName)
                }
            }
        }
        .listRowBackground(isTrackedLate ? Color(.GrocyColors.grocyRedBackground) : nil)
    }

    /// Like Grocy's journal: a chore that wasn't skipped and was tracked after its scheduled time.
    private var isTrackedLate: Bool {
        guard !choreLogEntry.skipped, let trackedTime = choreLogEntry.trackedTime, let scheduledExecutionTime = choreLogEntry.scheduledExecutionTime else {
            return false
        }
        return trackedTime > scheduledExecutionTime
    }
}

#Preview {
    List {
        ChoreLogRowView(
            choreLogEntry: ChoreLogEntry(trackedTime: Date(), scheduledExecutionTime: Date()),
            chore: Chore(choreName: "Chore"),
            user: GrocyUser(displayName: "User")
        )
    }
}
