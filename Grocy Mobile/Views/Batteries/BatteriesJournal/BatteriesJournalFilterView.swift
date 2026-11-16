//
//  BatteriesJournalFilterView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import SwiftData
import SwiftUI

struct BatteriesJournalFilterView: View {
    @AppStorage("localizationKey") var localizationKey: String = "en"

    @Query(sort: \MDBattery.name, order: .forward) var mdBatteries: MDBatteries

    @Binding var filteredBatteryID: Int?
    @Binding var filteredDateRangeMonths: Int?

    var body: some View {
        List {
            Picker(selection: $filteredBatteryID) {
                Text("All").tag(nil as Int?)
                ForEach(mdBatteries, id: \.id) { battery in
                    Text(battery.name).tag(battery.id as Int?)
                }
            } label: {
                Label("Battery", systemImage: MySymbols.batteries)
                    .foregroundStyle(.primary)
            }
            Picker(selection: $filteredDateRangeMonths) {
                Text(formatDuration(value: 1, unit: .month, localizationKey: localizationKey) ?? "").tag(1 as Int?)
                Text(formatDuration(value: 6, unit: .month, localizationKey: localizationKey) ?? "").tag(6 as Int?)
                Text(formatDuration(value: 1, unit: .year, localizationKey: localizationKey) ?? "").tag(12 as Int?)
                Text(formatDuration(value: 2, unit: .year, localizationKey: localizationKey) ?? "").tag(24 as Int?)
                Text("All").tag(nil as Int?)
            } label: {
                Label("Date range", systemImage: MySymbols.date)
                    .foregroundStyle(.primary)
            }
        }
    }
}

#Preview(traits: .previewData) {
    @Previewable @State var filteredBatteryID: Int? = nil
    @Previewable @State var filteredDateRangeMonths: Int? = 12

    NavigationStack {
        BatteriesJournalFilterView(filteredBatteryID: $filteredBatteryID, filteredDateRangeMonths: $filteredDateRangeMonths)
    }
}
