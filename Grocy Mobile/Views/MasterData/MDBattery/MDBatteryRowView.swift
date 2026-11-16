//
//  MDBatteryRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import SwiftUI

struct MDBatteryRowView: View {
    var battery: MDBattery

    var body: some View {
        VStack(alignment: .leading) {
            Text(battery.name)
                .font(.headline)
                .foregroundStyle(battery.active ? .primary : .secondary)
            // Disabled is spelled out, not only shown by the dimmed color ("Disabled" matches the Grocy web app).
            if !battery.active {
                Text("Disabled")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !battery.usedIn.isEmpty {
                Text("\(Text("Used in")): \(battery.usedIn)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !battery.mdBatteryDescription.isEmpty {
                Text(battery.mdBatteryDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if battery.chargeIntervalDays > 0 {
                Text("\(Text("Charge cycle interval")): \(Text("\(battery.chargeIntervalDays) days"))")
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
        MDBatteryRowView(battery: MDBattery(name: "Battery", mdBatteryDescription: "Warranty ends 2028", usedIn: "TV remote control", chargeIntervalDays: 180))
        MDBatteryRowView(battery: MDBattery(name: "Disabled battery", active: false))
    }
}
