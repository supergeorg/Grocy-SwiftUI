//
//  BatteriesJournalView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import SwiftData
import SwiftUI

enum BatteriesJournalSortOption: Hashable, Sendable {
    case byBattery
    case byTrackedTime
}

/// All tracked charge cycles, newest first. A charge cycle can be undone with a swipe.
struct BatteriesJournalView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @Query var mdBatteries: MDBatteries

    @State private var searchString: String = ""
    @State private var filteredBatteryID: Int?
    @State private var filteredDateRangeMonths: Int? = 24
    @State private var showingFilterSheet = false
    @State private var isFirstShown: Bool = true
    @State private var sortOption: BatteriesJournalSortOption = .byTrackedTime
    @State private var sortOrder: SortOrder = .reverse
    @State private var errorMessage: String?

    var batteryID: Int? = nil
    var isPopup: Bool = false

    private var batteryNames: [Int: String] {
        Dictionary(mdBatteries.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
    }

    private var numFilters: Int {
        (filteredBatteryID != nil ? 1 : 0) + (filteredDateRangeMonths != nil ? 1 : 0)
    }

    var chargeCycles: BatteryChargeCycles {
        var predicates: [Predicate<BatteryChargeCycle>] = []

        if let filteredDateRangeMonths, let cutoffDate = Calendar.current.date(byAdding: .month, value: -filteredDateRangeMonths, to: .now) {
            predicates.append(
                #Predicate<BatteryChargeCycle> { entry in
                    if let trackedTime = entry.trackedTime {
                        return trackedTime >= cutoffDate
                    } else {
                        return false
                    }
                }
            )
        }

        if !searchString.isEmpty {
            let matchingIDs = mdBatteries.filter { $0.name.localizedStandardContains(searchString) }.map(\.id)
            predicates.append(#Predicate<BatteryChargeCycle> { matchingIDs.contains($0.batteryID) })
        }

        if let filteredBatteryID {
            predicates.append(#Predicate<BatteryChargeCycle> { $0.batteryID == filteredBatteryID })
        }

        let finalPredicate = predicates.reduce(nil as Predicate<BatteryChargeCycle>?) { result, predicate in
            if let result {
                return #Predicate<BatteryChargeCycle> { result.evaluate($0) && predicate.evaluate($0) }
            }
            return predicate
        }

        let sortBy: [SortDescriptor<BatteryChargeCycle>] = sortOption == .byTrackedTime ? [SortDescriptor(\.trackedTime, order: sortOrder)] : []
        let results = (try? modelContext.fetch(FetchDescriptor<BatteryChargeCycle>(predicate: finalPredicate, sortBy: sortBy))) ?? []

        if sortOption == .byBattery {
            let names = batteryNames
            return results.sorted { a, b in
                let comparison = (names[a.batteryID] ?? "").localizedCaseInsensitiveCompare(names[b.batteryID] ?? "")
                return sortOrder == .forward ? comparison == .orderedAscending : comparison == .orderedDescending
            }
        }
        return results
    }

    var chargeCyclesCount: Int {
        var descriptor = FetchDescriptor<BatteryChargeCycle>(sortBy: [])
        descriptor.fetchLimit = 0
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private let dataToUpdate: [ObjectEntities] = [.batteries, .battery_charge_cycles]

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private func undoChargeCycle(_ chargeCycle: BatteryChargeCycle) async {
        do {
            try await grocyVM.undoBatteryChargeCycle(id: chargeCycle.id)
            GrocyLogger.info("Undoing charge cycle \(chargeCycle.id) was successful.")
            await grocyVM.requestData(objects: [.battery_charge_cycles], additionalObjects: [.batteries])
        } catch {
            GrocyLogger.error("Undoing charge cycle failed. \(error)")
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    var body: some View {
        List {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            } else if chargeCyclesCount == 0 {
                ContentUnavailableView {
                    Label("No charge cycles", systemImage: MySymbols.batteries)
                } description: {
                    Text("Tracked charge cycles are listed here.")
                }
            } else if chargeCycles.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(chargeCycles, id: \.id) { chargeCycle in
                BatteriesJournalRowView(chargeCycle: chargeCycle, batteryName: batteryNames[chargeCycle.batteryID])
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        if !chargeCycle.undone {
                            Button {
                                Task {
                                    await undoChargeCycle(chargeCycle)
                                }
                            } label: {
                                Label("Undo charge cycle", systemImage: MySymbols.undo)
                            }
                        }
                    }
                    .contextMenu {
                        if !chargeCycle.undone {
                            Button {
                                Task {
                                    await undoChargeCycle(chargeCycle)
                                }
                            } label: {
                                Label("Undo charge cycle", systemImage: MySymbols.undo)
                            }
                        }
                    }
            }
        }
        .navigationTitle("Batteries journal")
        .toolbar {
            if isPopup {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            ToolbarItemGroup(placement: .automatic) {
                sortGroupMenu
                Button {
                    showingFilterSheet = true
                } label: {
                    Label("Filter", systemImage: MySymbols.filter)
                }
                .badge(numFilters)
            }
            #if os(iOS)
                ToolbarSpacer(.flexible, placement: .bottomBar)
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
            #endif
        }
        .searchable(text: $searchString, placement: .toolbar)
        .sheet(isPresented: $showingFilterSheet) {
            NavigationStack {
                BatteriesJournalFilterView(filteredBatteryID: $filteredBatteryID, filteredDateRangeMonths: $filteredDateRangeMonths)
                    .navigationTitle("Filter")
                    #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(role: .confirm) {
                                showingFilterSheet = false
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Clear filter", role: .destructive) {
                                filteredBatteryID = nil
                                filteredDateRangeMonths = nil
                                showingFilterSheet = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium])
        }
        .alert(
            "Couldn't undo the charge cycle",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            ),
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text(errorMessage ?? "")
            }
        )
        .refreshable {
            await updateData()
        }
        .task {
            if isFirstShown {
                filteredBatteryID = batteryID
                isFirstShown = false
            }
            await updateData()
        }
    }

    var sortGroupMenu: some View {
        Menu {
            Picker("Sort category", systemImage: MySymbols.sortCategory, selection: $sortOption) {
                Label("Battery", systemImage: MySymbols.batteries)
                    .labelStyle(.titleAndIcon)
                    .tag(BatteriesJournalSortOption.byBattery)
                Label("Tracked time", systemImage: MySymbols.date)
                    .labelStyle(.titleAndIcon)
                    .tag(BatteriesJournalSortOption.byTrackedTime)
            }
            #if os(iOS)
                .pickerStyle(.menu)
            #else
                .pickerStyle(.inline)
            #endif
            Picker("Sort order", systemImage: MySymbols.sortOrder, selection: $sortOrder) {
                Label("Ascending", systemImage: MySymbols.sortForward)
                    .labelStyle(.titleAndIcon)
                    .tag(SortOrder.forward)
                Label("Descending", systemImage: MySymbols.sortReverse)
                    .labelStyle(.titleAndIcon)
                    .tag(SortOrder.reverse)
            }
            #if os(iOS)
                .pickerStyle(.menu)
            #else
                .pickerStyle(.inline)
            #endif
        } label: {
            Label("Sort", systemImage: MySymbols.sort)
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        BatteriesJournalView()
    }
}
