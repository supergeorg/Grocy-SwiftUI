//
//  EquipmentRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import SwiftUI

struct EquipmentRowView: View {
    var equipment: MDEquipment

    var body: some View {
        VStack(alignment: .leading) {
            Text(equipment.name)
                .font(.headline)
            if equipment.instructionManualFileName != nil {
                Label("Instruction manual", systemImage: MySymbols.instructionManual)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        EquipmentRowView(equipment: MDEquipment(name: "Coffee machine", instructionManualFileName: "manual.pdf"))
        EquipmentRowView(equipment: MDEquipment(name: "Dishwasher"))
    }
}
