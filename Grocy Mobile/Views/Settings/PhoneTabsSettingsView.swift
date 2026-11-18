//
//  PhoneTabsSettingsView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftData
import SwiftUI

/// Chooses and orders the tabs of the "own tabs" iPhone navigation: up to four, plus the search tab.
/// Places that aren't tabs open from the settings button.
struct PhoneTabsSettingsView: View {
    @AppStorage(PhonePlace.tabsStorageKey) private var storedTabs: String = PhonePlace.defaultOwnTabsValue

    @Query private var systemConfigList: [SystemConfig]

    private var tabs: [PhonePlace] { PhonePlace.decode(storedTabs) }

    private var otherPlaces: [PhonePlace] {
        PhonePlace.allCases.filter { !tabs.contains($0) && $0.isEnabled(in: systemConfigList.first) }
    }

    private func setTabs(_ newTabs: [PhonePlace]) {
        storedTabs = PhonePlace.encode(newTabs)
    }

    var body: some View {
        List {
            Section {
                // Each section has its own row identity: with the same one, a place added from "More" would keep
                // the "More" row (no delete or move controls) until the screen is opened again.
                ForEach(tabs, id: \.tabRowID) { place in
                    Label(place.title, systemImage: place.icon)
                }
                .onMove { source, destination in
                    var newTabs = tabs
                    newTabs.move(fromOffsets: source, toOffset: destination)
                    setTabs(newTabs)
                }
                .onDelete { offsets in
                    var newTabs = tabs
                    newTabs.remove(atOffsets: offsets)
                    setTabs(newTabs)
                }
                .deleteDisabled(tabs.count <= 1)
            } header: {
                Text("Tabs")
            } footer: {
                Text("Up to \(PhonePlace.maxTabs) tabs, plus search. Everything else opens from the settings button.")
            }

            if !otherPlaces.isEmpty {
                Section("More") {
                    ForEach(otherPlaces, id: \.otherRowID) { place in
                        Button {
                            setTabs(tabs + [place])
                        } label: {
                            Label(place.title, systemImage: place.icon)
                                .foregroundStyle(.primary)
                        }
                        .disabled(tabs.count >= PhonePlace.maxTabs)
                        .accessibilityHint("Adds this place as a tab")
                    }
                }
            }
        }
        #if os(iOS)
            // Always reorderable and deletable, without an extra Edit button.
            .environment(\.editMode, .constant(.active))
        #endif
        .navigationTitle("Tabs")
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        PhoneTabsSettingsView()
    }
}

extension PhonePlace {
    fileprivate var tabRowID: String { "tab-\(rawValue)" }
    fileprivate var otherRowID: String { "other-\(rawValue)" }
}
