//
//  BatteryRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import SwiftUI

struct BatteryRowView: View {
    var battery: Battery
    /// The due state, shown as text too, so it isn't conveyed by the row color alone.
    var status: BatteryStatus?

    @AppStorage("localizationKey") var localizationKey: String = "en"

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text(battery.batteryName)
                    .font(.headline)
                if let status {
                    Spacer()
                    Label(status.title, systemImage: status.icon)
                        .font(.caption)
                        .foregroundStyle(status.color)
                }
            }
            if !battery.usedIn.isEmpty {
                HStack {
                    Text("\(Text("Used in")):")
                    Spacer()
                    Text(battery.usedIn)
                }
            }
            HStack {
                Text("\(Text("Last charged")):")
                Spacer()
                if let lastTrackedTime = battery.lastTrackedTime {
                    Text(formatDateTimeAsString(lastTrackedTime, localizationKey: localizationKey) ?? "")
                    Text(getRelativeDateAsText(lastTrackedTime, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                } else {
                    Text("Never")
                        .foregroundStyle(.secondary)
                }
            }
            if let nextEstimatedChargeTime = battery.nextEstimatedChargeTime {
                HStack {
                    Text("\(Text("Next planned charge cycle")):")
                    Spacer()
                    Text(formatDateTimeAsString(nextEstimatedChargeTime, localizationKey: localizationKey) ?? "")
                    Text(getRelativeDateAsText(nextEstimatedChargeTime, localizationKey: localizationKey) ?? "")
                        .font(.caption)
                        .italic()
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview(traits: .previewData) {
    List {
        BatteryRowView(battery: Battery(batteryName: "Never charged", usedIn: "Remote control", chargeIntervalDays: 0))
        BatteryRowView(
            battery: Battery(
                batteryName: "Overdue",
                usedIn: "Alarm clock",
                chargeIntervalDays: 30,
                lastTrackedTime: Calendar.current.date(byAdding: .day, value: -40, to: Date()),
                nextEstimatedChargeTime: Calendar.current.date(byAdding: .day, value: -10, to: Date())
            ),
            status: .overdue
        )
        .listRowBackground(BatteryStatus.overdue.backgroundColor)
        BatteryRowView(
            battery: Battery(
                batteryName: "Due soon",
                chargeIntervalDays: 30,
                lastTrackedTime: Calendar.current.date(byAdding: .day, value: -27, to: Date()),
                nextEstimatedChargeTime: Calendar.current.date(byAdding: .day, value: 3, to: Date())
            ),
            status: .dueSoon
        )
        .listRowBackground(BatteryStatus.dueSoon.backgroundColor)
    }
}
