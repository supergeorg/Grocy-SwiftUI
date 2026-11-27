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
        DueKind.allCases.filter { kind in
            // Due products need due date tracking; products below min. stock don't.
            kind.place.isEnabled(in: systemConfigList.first) && !(kind == .product && systemConfigList.first?.featureFlagStockBestBeforeDateTracking == false)
        }
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
            // The shared toggle, so the icon has the text color like in every other settings row (a plain Label takes the tint).
            MyToggle(isOn: binding(for: kind), description: kind.title, icon: kind.icon)
        }
    }
}

#Preview(traits: .previewData) {
    Form {
        DueKindToggles()
    }
}
