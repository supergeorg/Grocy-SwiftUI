//
//  ChoreLogView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 11.12.25.
//

import SwiftData
import SwiftUI

enum ChoreLogSortOption: Hashable, Sendable {
    case byChore
    case byTrackedTime
    case byScheduledTrackingTime
    case byUser
}

struct ChoreLogView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @Query var chores: Chores
    @Query var users: GrocyUsers

    @State private var searchString: String = ""

    @State private var filteredChoreID: Int?
    @State private var filteredDateRangeMonths: Int? = 12
    @State private var filteredUserID: Int?
    @State private var showingFilterSheet = false
    @State private var isFirstShown: Bool = true
    @State private var sortOption: ChoreLogSortOption = .byTrackedTime
    @State private var sortOrder: SortOrder = .reverse

    var choreID: Int? = nil
    var isPopup: Bool = false

    var sortDescriptor: SortDescriptor<ChoreLogEntry>? {
        switch sortOption {
        case .byChore:
            return nil
        case .byTrackedTime:
            return SortDescriptor(\.trackedTime, order: sortOrder)
        case .byScheduledTrackingTime:
            return SortDescriptor(\.scheduledExecutionTime, order: sortOrder)
        case .byUser:
            return nil

        }
    }

    // Fetch the data with a dynamic predicate
    var choreLog: ChoreLog {
        var predicates: [Predicate<ChoreLogEntry>] = []

        // Date range predicate
        if let filteredDateRangeMonths = filteredDateRangeMonths {
            let cutoffDate = Calendar.current.date(
                byAdding: .month,
                value: -filteredDateRangeMonths,
                to: Date.now
            )!
            let choreLogPredicate = #Predicate<ChoreLogEntry> { entry in
                if let trackedTime = entry.trackedTime {
                    return trackedTime >= cutoffDate
                } else {
                    return false
                }
            }
            predicates.append(choreLogPredicate)
        }

        // Find matching product IDs for search string
        var matchingChoreIDs: [Int]? {
            let chorePredicate =
                searchString.isEmpty
                ? nil
                : #Predicate<Chore> { chore in
                    chore.choreName.localizedStandardContains(searchString)
                }
            let choreDescriptor = FetchDescriptor<Chore>(predicate: chorePredicate)
            let matchingChores = try? modelContext.fetch(choreDescriptor)
            return matchingChores?.map(\.id) ?? []
        }

        // Chore search predicate
        if !searchString.isEmpty, let matchingChoreIDs {
            let searchPredicate = #Predicate<ChoreLogEntry> { entry in
                matchingChoreIDs.contains(entry.choreID)
            }
            predicates.append(searchPredicate)
        }

        // Filtered chore predicate
        if let filteredChoreID = filteredChoreID {
            let choreLogPredicate = #Predicate<ChoreLogEntry> { entry in
                entry.choreID == filteredChoreID
            }
            predicates.append(choreLogPredicate)
        }

        // Filtered user predicate
        if let filteredUserID = filteredUserID {
            let choreLogPredicate = #Predicate<ChoreLogEntry> { entry in
                entry.doneByUserID == filteredUserID
            }
            predicates.append(choreLogPredicate)
        }

        // Combine predicates
        let finalPredicate = predicates.reduce(nil as Predicate<ChoreLogEntry>?) { (result: Predicate<ChoreLogEntry>?, predicate: Predicate<ChoreLogEntry>) in
            if let existing = result {
                return #Predicate<ChoreLogEntry> {
                    existing.evaluate($0) && predicate.evaluate($0)
                }
            }
            return predicate
        }

        let descriptor = FetchDescriptor<ChoreLogEntry>(
            predicate: finalPredicate,
            sortBy: sortDescriptor != nil ? [sortDescriptor!] : []
        )

        let fetchedResults = (try? modelContext.fetch(descriptor)) ?? []

        // Apply user name sorting in-memory
        if sortOption == .byChore {
            // Fetch all users once
            let choreDescriptor = FetchDescriptor<MDChore>()
            let chores = (try? modelContext.fetch(choreDescriptor)) ?? []
            let choreDict = Dictionary(uniqueKeysWithValues: chores.map { ($0.id, $0.name) })

            return fetchedResults.sorted { a, b in
                let aName = choreDict[a.choreID] ?? ""
                let bName = choreDict[b.choreID] ?? ""
                let comparison = aName.localizedCaseInsensitiveCompare(bName)
                return sortOrder == .forward
                    ? comparison == .orderedAscending
                    : comparison == .orderedDescending
            }
        }

        // Apply user name sorting in-memory
        if sortOption == .byUser {
            // Fetch all users once
            let userDescriptor = FetchDescriptor<GrocyUser>()
            let users = (try? modelContext.fetch(userDescriptor)) ?? []
            let userDict = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0.displayName) })

            return fetchedResults.sorted { a, b in
                let aName = userDict[a.doneByUserID ?? 0] ?? ""
                let bName = userDict[b.doneByUserID ?? 0] ?? ""
                let comparison = aName.localizedCaseInsensitiveCompare(bName)
                return sortOrder == .forward
                    ? comparison == .orderedAscending
                    : comparison == .orderedDescending
            }
        }

        return fetchedResults
    }

    // Get the unfiltered count without fetching any data
    var choreLogCount: Int {
        var descriptor = FetchDescriptor<ChoreLogEntry>(
            sortBy: []
        )
        descriptor.fetchLimit = 0

        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private let dataToUpdate: [ObjectEntities] = [.chores, .chores_log]
    private let additionalDataToUpdate: [AdditionalEntities] = [.users]

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    private func undoExecution(choreLogEntry: ChoreLogEntry) async {
        do {
            try await grocyVM.undoChoreWithID(id: choreLogEntry.id)
            GrocyLogger.info("Undo chore execution \(choreLogEntry.id) successful.")
            await grocyVM.requestData(objects: [.chores_log])
        } catch {
            GrocyLogger.error("Undo chore execution failed. \(error)")
        }
    }

    var body: some View {
        List {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            }
            ForEach(choreLog, id: \.id) { (choreLogEntry: ChoreLogEntry) in
                ChoreLogRowView(
                    choreLogEntry: choreLogEntry,
                    chore: chores.first(where: { $0.id == choreLogEntry.choreID }),
                    user: users.first(where: { $0.id == choreLogEntry.doneByUserID })
                )
                .swipeActions(
                    edge: .leading,
                    allowsFullSwipe: true,
                    content: {
                        if !choreLogEntry.undone {
                            Button(
                                action: {
                                    Task {
                                        await undoExecution(choreLogEntry: choreLogEntry)
                                    }
                                },
                                label: {
                                    Label("Undo chore execution", systemImage: MySymbols.undo)
                                }
                            )
                        }
                    }
                )
            }
        }
        .overlay {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count == 0 {
                if choreLogCount == 0 {
                    ContentUnavailableView("No chore log entries found.", systemImage: MySymbols.chores)
                } else if choreLog.isEmpty {
                    ContentUnavailableView.search
                }
            }
        }
        .navigationTitle("Chores journal")
        .toolbar {
            if isPopup {
                ToolbarItem(
                    placement: .cancellationAction,
                    content: {
                        Button(
                            role: .cancel,
                            action: {
                                dismiss()
                            }
                        )
                        .keyboardShortcut(.cancelAction)
                    }
                )
            }
            ToolbarItemGroup(placement: .automatic) {
                sortGroupMenu
                Button(action: { showingFilterSheet = true }) {
                    Label("Filter", systemImage: MySymbols.filter)
                }
            }
            #if os(iOS)
                ToolbarSpacer(.flexible, placement: .bottomBar)
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
            #endif
        }
        .searchable(
            text: $searchString,
            placement: .toolbar,
        )
        .sheet(isPresented: $showingFilterSheet) {
            NavigationStack {
                ChoreLogFilterView(
                    filteredChoreID: $filteredChoreID,
                    filteredDateRangeMonths: $filteredDateRangeMonths,
                    filteredUserID: $filteredUserID,
                )
                .navigationTitle("Filter")
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(
                        placement: .confirmationAction,
                        content: {
                            Button(
                                role: .confirm,
                                action: {
                                    showingFilterSheet = false
                                }
                            )
                        }
                    )
                    ToolbarItem(
                        placement: .cancellationAction,
                        content: {
                            Button(
                                role: .destructive,
                                action: {
                                    filteredChoreID = nil
                                    filteredUserID = nil
                                    showingFilterSheet = false
                                }
                            )
                        }
                    )
                }
            }
            .presentationDetents([.medium])
        }
        .refreshable {
            await updateData()
        }
        .task {
            await updateData()
            if isFirstShown {
                filteredChoreID = choreID
                isFirstShown = false
            }
        }
    }

    var sortGroupMenu: some View {
        Menu(
            content: {
                Picker(
                    "Sort category",
                    systemImage: MySymbols.sortCategory,
                    selection: $sortOption,
                    content: {
                        Label("Chore", systemImage: MySymbols.chores)
                            .labelStyle(.titleAndIcon)
                            .tag(ChoreLogSortOption.byChore)

                        Label("Tracked time", systemImage: MySymbols.date)
                            .labelStyle(.titleAndIcon)
                            .tag(ChoreLogSortOption.byTrackedTime)

                        Label("Scheduled tracking time", systemImage: MySymbols.date)
                            .labelStyle(.titleAndIcon)
                            .tag(ChoreLogSortOption.byScheduledTrackingTime)

                        Label("Done by", systemImage: MySymbols.user)
                            .labelStyle(.titleAndIcon)
                            .tag(ChoreLogSortOption.byUser)
                    }
                )
                #if os(iOS)
                    .pickerStyle(.menu)
                #else
                    .pickerStyle(.inline)
                #endif
                Picker(
                    "Sort order",
                    systemImage: MySymbols.sortOrder,
                    selection: $sortOrder,
                    content: {
                        Label("Ascending", systemImage: MySymbols.sortForward)
                            .labelStyle(.titleAndIcon)
                            .tag(SortOrder.forward)

                        Label("Descending", systemImage: MySymbols.sortReverse)
                            .labelStyle(.titleAndIcon)
                            .tag(SortOrder.reverse)
                    }
                )
                #if os(iOS)
                    .pickerStyle(.menu)
                #else
                    .pickerStyle(.inline)
                #endif
            },
            label: {
                Label("Sort", systemImage: MySymbols.sort)
            }
        )
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        ChoreLogView()
    }
}
