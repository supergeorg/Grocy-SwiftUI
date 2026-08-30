//
//  ChoresView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 09.12.25.
//

import SwiftData
import SwiftUI

enum ChoresSortOption: Hashable, Sendable {
    case byName
    case byNextEstimatedTracking
    case byLastTracked
    case byUser
}

enum ChoreInteraction: Hashable, Identifiable {
    case choreLog(choreID: Int?)
    case choreOverview(choreID: Int)
    case editChore(mdChore: MDChore)

    var id: Self { self }
}

@Observable
class ChoreInteractionNavigationRouter {
    var presentedInteraction: ChoreInteraction?

    func present(_ interaction: ChoreInteraction) {
        presentedInteraction = interaction
    }

    func dismiss() {
        presentedInteraction = nil
    }
}

struct ChoresView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext

    @State private var searchString: String = ""
    @State private var showingFilterSheet = false
    @State private var filteredStatus: ChoreStatus = .all
    @State private var filteredUserID: Int? = nil
    @State private var sortOption: ChoresSortOption = .byName
    @State private var sortOrder: SortOrder = .forward

    @State private var choreInteractionRouter = ChoreInteractionNavigationRouter()

    @Query var mdChores: MDChores
    @Query var grocyUsers: GrocyUsers
    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        return userSettingsList.first
    }

    var chores: Chores {
        let sortDescriptor = SortDescriptor<Chore>(\.id)
        let predicate = #Predicate<Chore> { chore in
            searchString.isEmpty || chore.choreName.localizedStandardContains(searchString)
        }

        let descriptor = FetchDescriptor<Chore>(
            predicate: predicate,
            sortBy: [sortDescriptor]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var choresCount: Int {
        var descriptor = FetchDescriptor<Chore>(
            sortBy: []
        )
        descriptor.fetchLimit = 0

        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    private var numFilters: Int {
        var filterCount = 0
        if filteredStatus != .all { filterCount += 1 }
        if filteredUserID != nil { filterCount += 1 }
        return filterCount
    }

    private let dataToUpdate: [ObjectEntities] = [.chores]
    private let additionalDataToUpdate: [AdditionalEntities] = [.chores, .current_user, .users]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    var filteredChores: [Chore] {
        chores
            .filter { filteredUserID == nil || $0.nextExecutionAssignedToUserID == filteredUserID }
            .filter { matchesFilter($0) }
    }

    var choreCounts: [ChoreStatus: Int] {
        Dictionary(
            uniqueKeysWithValues: ChoreStatus.allCases.map { status in
                (status, chores.count(where: { matchesFilter($0, for: status) }))
            }
        )
    }

    func matchesFilter(_ chore: Chore, for status: ChoreStatus? = nil) -> Bool {
        let targetStatus = status ?? filteredStatus

        switch targetStatus {
        case .all:
            return true

        case .assignedToMe:
            return chore.nextExecutionAssignedToUserID != nil && chore.nextExecutionAssignedToUserID == grocyVM.currentUser?.id

        case .overdue:
            return daysDifference(for: chore.nextEstimatedExecutionTime) ?? 0 < 0

        case .dueToday:
            return daysDifference(for: chore.nextEstimatedExecutionTime) == 0

        case .dueSoon:
            guard let diff = daysDifference(for: chore.nextEstimatedExecutionTime) else { return false }
            return (0...(userSettings?.choresDueSoonDays ?? 5)).contains(diff)
        }
    }

    private func backgroundColorForChore(_ chore: Chore) -> Color? {
        guard let diff = daysDifference(for: chore.nextEstimatedExecutionTime) else { return nil }

        switch diff {
        case ..<0:
            return Color(.GrocyColors.grocyRedBackground)
        case 0:
            return Color(.GrocyColors.grocyBlueBackground)
        case 0...(userSettings?.choresDueSoonDays ?? 5):
            return Color(.GrocyColors.grocyYellowBackground)
        default:
            return nil
        }
    }

    var sortComparator: (Chore, Chore) -> Bool {
        switch sortOption {
        case .byName:
            return { a, b in
                let aName = a.choreName
                let bName = b.choreName
                let comparison = aName.localizedCaseInsensitiveCompare(bName)
                return self.sortOrder == .forward
                    ? comparison == .orderedAscending
                    : comparison == .orderedDescending
            }
        case .byNextEstimatedTracking:
            return { a, b in
                let aAmount = a.nextEstimatedExecutionTime ?? .now
                let bAmount = b.nextEstimatedExecutionTime ?? .now
                return self.sortOrder == .forward
                    ? aAmount < bAmount
                    : aAmount > bAmount
            }
        case .byLastTracked:
            return { a, b in
                let aAmount = a.lastTrackedTime ?? .distantFuture
                let bAmount = b.lastTrackedTime ?? .distantFuture
                return self.sortOrder == .forward
                    ? aAmount < bAmount
                    : aAmount > bAmount
            }
        case .byUser:
            return { a, b in
                let aAmount = a.nextExecutionAssignedToUserID ?? 0
                let bAmount = b.nextExecutionAssignedToUserID ?? 0
                return self.sortOrder == .forward
                    ? aAmount < bAmount
                    : aAmount > bAmount
            }
        }
    }

    private func trackChore(choreID: Int, skipped: Bool = false) async {
        let executeInfo = ChoreExecuteModel(trackedTime: Date().iso8601withFractionalSeconds, doneBy: nil, skipped: skipped)
        do {
            _ = try await grocyVM.executeChore(id: choreID, content: executeInfo)
            GrocyLogger.info("Tracking chore successful.")
            await self.updateData()
        } catch {
            GrocyLogger.error("Tracking chore failed: \(error)")
        }
    }

    var body: some View {
        List {
            Section {
                ChoresFilterActionsView(
                    filteredStatus: $filteredStatus,
                    numOverdue: choreCounts[ChoreStatus.overdue],
                    numDueToday: choreCounts[ChoreStatus.dueToday],
                    numDueSoon: choreCounts[ChoreStatus.dueSoon],
                    numAssignedToMe: choreCounts[ChoreStatus.assignedToMe]
                )
                .listRowInsets(EdgeInsets())
            }

            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            } else if choresCount == 0 {
                ContentUnavailableView("No chore defined. Please create one.", systemImage: MySymbols.chores)
            } else if chores.isEmpty {
                ContentUnavailableView.search
            }
            ForEach(filteredChores.sorted(by: sortComparator), id: \.id) { chore in
                ChoreRowView(
                    chore: chore,
                    user: grocyUsers.first(where: { $0.id == chore.nextExecutionAssignedToUserID }),
                )
                .listRowBackground(backgroundColorForChore(chore))
                .contextMenu(menuItems: {
                    Button(
                        action: {
                            Task {
                                await trackChore(choreID: chore.id)
                            }
                        },
                        label: {
                            Label("Track chore execution now", systemImage: MySymbols.choreTrackNext)
                        }
                    )
                    Button(
                        action: {
                            Task {
                                await trackChore(choreID: chore.id, skipped: true)
                            }
                        },
                        label: {
                            Label("Reschedule next execution", systemImage: MySymbols.choreSkipNext)
                        }
                    )
                    Button(
                        action: {
                            choreInteractionRouter.present(.choreOverview(choreID: chore.choreID))
                        },
                        label: {
                            Label("Chore overview", systemImage: MySymbols.info)
                        }
                    )
                    Button(
                        action: {
                            choreInteractionRouter.present(.choreLog(choreID: chore.choreID))
                        },
                        label: {
                            Label("Chore journal", systemImage: MySymbols.stockJournal)
                        }
                    )
                    Button(
                        action: {
                            if let mdChore = mdChores.first(where: { $0.id == chore.choreID }) {
                                choreInteractionRouter.present(.editChore(mdChore: mdChore))
                            }
                        },
                        label: {
                            Label("Edit chore", systemImage: MySymbols.edit)
                        }
                    )
                })
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: true
                ) {
                    Button(
                        action: {
                            Task {
                                await trackChore(choreID: chore.id, skipped: true)
                            }
                        },
                        label: { Label("Skip", systemImage: MySymbols.choreSkipNext) }
                    )
                    .tint(.gray)
                    .accessibilityHint("Skip next chore schedule")
                }
                .swipeActions(
                    edge: .leading,
                    allowsFullSwipe: true
                ) {
                    Button(
                        action: {
                            Task {
                                await trackChore(choreID: chore.id)
                            }
                        },
                        label: { Label("OK", systemImage: MySymbols.choreTrackNext) }
                    )
                    .tint(.green)
                    .accessibilityHint("Track next chore schedule")
                }
            }
        }
        .task {
            await updateData()
        }
        .refreshable {
            await updateData()
        }
        .searchable(
            text: $searchString,
            prompt: "Search"
        )
        .navigationTitle("Chores overview")
        .sheet(item: $choreInteractionRouter.presentedInteraction) { interaction in
            NavigationStack {
                switch interaction {
                case .choreLog(let choreID):
                    ChoreLogView(choreID: choreID, isPopup: true)
                case .choreOverview(let choreID):
                    ChoreDetailsView(choreID: choreID, isPopup: true)
                case .editChore(let mdChore):
                    MDChoreFormView(existingChore: mdChore, isPopup: true)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(
                    action: { showingFilterSheet = true },
                    label: {
                        Label("Filter", systemImage: MySymbols.filter)
                    }
                )
                .badge(numFilters)
                sortGroupMenu
            }
            ToolbarItem(placement: .primaryAction) {
                Button(
                    action: {
                        choreInteractionRouter.present(.choreLog(choreID: nil))
                    },
                    label: {
                        Label("Chores journal", systemImage: MySymbols.stockJournal)
                    }
                )
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            NavigationStack {
                ChoresFilterView(filteredStatus: $filteredStatus, filteredUserID: $filteredUserID)
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
                                        filteredStatus = .all
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
        .environment(choreInteractionRouter)
    }

    var sortGroupMenu: some View {
        Menu(
            content: {
                Picker(
                    "Sort category",
                    systemImage: MySymbols.sortCategory,
                    selection: $sortOption,
                    content: {
                        Label("Name", systemImage: MySymbols.name)
                            .labelStyle(.titleAndIcon)
                            .tag(ChoresSortOption.byName)
                        Label("Next estimated tracking", systemImage: MySymbols.date)
                            .labelStyle(.titleAndIcon)
                            .tag(ChoresSortOption.byNextEstimatedTracking)
                        Label("Last tracked", systemImage: MySymbols.date)
                            .labelStyle(.titleAndIcon)
                            .tag(ChoresSortOption.byLastTracked)
                        Label("Assign to", systemImage: MySymbols.user)
                            .labelStyle(.titleAndIcon)
                            .tag(ChoresSortOption.byUser)
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
        ChoresView()
    }
}
