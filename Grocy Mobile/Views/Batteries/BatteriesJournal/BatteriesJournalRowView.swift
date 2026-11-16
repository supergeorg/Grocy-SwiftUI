//
//  BatteriesJournalRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import SwiftUI

struct BatteriesJournalRowView: View {
    var chargeCycle: BatteryChargeCycle
    var batteryName: String?

    @AppStorage("localizationKey") var localizationKey: String = "en"

    var body: some View {
        VStack(alignment: .leading) {
            Text(batteryName ?? "")
                .font(.headline)
                .foregroundStyle(!chargeCycle.undone ? .primary : .secondary)
                .strikethrough(chargeCycle.undone, color: .secondary)
            if let trackedTime = chargeCycle.trackedTime {
                HStack {
                    Text("\(Text("Tracked time")):")
                    Spacer()
                    Text(formatDateAsString(trackedTime, showTime: true, localizationKey: localizationKey) ?? "")
                    Text(getRelativeDateAsText(trackedTime, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                }
            }
            if chargeCycle.undone {
                HStack {
                    Text("\(Text("Undone on")):")
                    Spacer()
                    Text(formatDateAsString(chargeCycle.undoneTimestamp, showTime: true, localizationKey: localizationKey) ?? "")
                    Text(getRelativeDateAsText(chargeCycle.undoneTimestamp, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                }
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        BatteriesJournalRowView(chargeCycle: BatteryChargeCycle(trackedTime: Date()), batteryName: "Battery")
        BatteriesJournalRowView(chargeCycle: BatteryChargeCycle(trackedTime: Date(), undone: true, undoneTimestamp: Date()), batteryName: "Undone battery")
    }
}
