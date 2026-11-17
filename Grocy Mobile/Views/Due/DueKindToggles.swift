//
//  DueKindToggles.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftData
import SwiftUI

/// One switch per kind of the due agenda (products, chores, tasks, batteries), all on by default.
/// Used in the app settings and in the due tab's menu. Kinds the server disabled aren't listed.
struct DueKindToggles: View {
    @AppStorage(DueKind.hiddenKindsStorageKey) private var hiddenKindsValue: String = ""
    @Query private var systemConfigList: [SystemConfig]

    private var kinds: [DueKind] {
        DueKind.allCases.filter { $0.place.isEnabled(in: systemConfigList.first) }
    }

    private func binding(for kind: DueKind) -> Binding<Bool> {
        Binding(
            get: { !DueKind.hiddenKinds(from: hiddenKindsValue).contains(kind) },
            set: { isShown in
                var hidden = DueKind.hiddenKinds(from: hiddenKindsValue)
                if isShown { hidden.remove(kind) } else { hidden.insert(kind) }
                hiddenKindsValue = DueKind.encode(hiddenKinds: hidden)
            }
        )
    }

    var body: some View {
        ForEach(kinds) { kind in
            Toggle(isOn: binding(for: kind)) {
                Label(kind.title, systemImage: kind.icon)
            }
        }
    }
}

#Preview(traits: .previewData) {
    Form {
        DueKindToggles()
    }
}
