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
                    Text(formatDateAsString(choreLogEntry.undoneTimestamp, showTime: false, localizationKey: localizationKey) ?? "")
                    Text(getRelativeDateAsText(choreLogEntry.undoneTimestamp, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                }
            }
            if let trackedTime = choreLogEntry.trackedTime {
                HStack {
                    Text("\(Text("Tracked time")):")
                    Spacer()
                    Text(formatDateAsString(trackedTime, showTime: false, localizationKey: localizationKey) ?? "")
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
                    Text(formatDateAsString(scheduledExecutionTime, showTime: false, localizationKey: localizationKey) ?? "")
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
        .listRowBackground(
            (choreLogEntry.trackedTime ?? Date() > choreLogEntry.scheduledExecutionTime ?? Date()) ? Color(.GrocyColors.grocyRedBackground) : nil
        )
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
