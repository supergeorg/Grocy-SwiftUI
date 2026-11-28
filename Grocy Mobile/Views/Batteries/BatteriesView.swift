//
//  BatteriesView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 16.11.26.
//

import SwiftData
import SwiftUI

enum BatteriesSortOption: Hashable, Sendable {
    case byName
    case byUsedIn
    case byLastCharged
    case byNextChargeCycle
}

enum BatteryInteraction: Hashable, Identifiable {
    case batteryJournal(batteryID: Int?)
    case batteryOverview(batteryID: Int)
    case trackChargeCycle(batteryID: Int?)
    case editBattery(mdBattery: MDBattery)

    var id: Self { self }
}

@Observable
class BatteryInteractionNavigationRouter {
    var presentedInteraction: BatteryInteraction?

    func present(_ interaction: BatteryInteraction) {
        presentedInteraction = interaction
    }

    func dismiss() {
        presentedInteraction = nil
    }
}

/// The batteries overview of the Grocy web app: active batteries with their last and next charge cycle.
struct BatteriesView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext

    @State private var searchString: String = ""
    @State private var filteredStatus: BatteryStatus = .all
    @State private var showingFilterSheet = false
    @State private var showAddBattery = false
    @State private var sortOption: BatteriesSortOption = .byName
    @State private var sortOrder: SortOrder = .forward
    @State private var trackedCount: Int = 0
    @State private var errorMessage: String? = nil

    @State private var batteryInteractionRouter = BatteryInteractionNavigationRouter()

    @Query var mdBatteries: MDBatteries
    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        userSettingsList.first
    }

    private var dueSoonDays: Int {
        userSettings?.batteriesDueSoonDays ?? 5
    }

    var batteries: Batteries {
        let predicate = #Predicate<Battery> { battery in
            searchString.isEmpty || battery.batteryName.localizedStandardContains(searchString) || battery.usedIn.localizedStandardContains(searchString)
        }
        let descriptor = FetchDescriptor<Battery>(predicate: predicate, sortBy: [SortDescriptor(\.id)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var batteriesCount: Int {
        var descriptor = FetchDescriptor<Battery>(sortBy: [])
        descriptor.fetchLimit = 0
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private let dataToUpdate: [ObjectEntities] = [.batteries]
    private let additionalDataToUpdate: [AdditionalEntities] = [.batteries, .user_settings]

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    private var numFilters: Int {
        filteredStatus != .all ? 1 : 0
    }

    var filteredBatteries: Batteries {
        batteries.filter { filteredStatus.matches($0, dueSoonDays: dueSoonDays) }
    }

    func count(for status: BatteryStatus) -> Int {
        batteries.count(where: { status.matches($0, dueSoonDays: dueSoonDays) })
    }

    var sortComparator: (Battery, Battery) -> Bool {
        let ascending = sortOrder == .forward
        switch sortOption {
        case .byName:
            return { a, b in
                let comparison = a.batteryName.localizedCaseInsensitiveCompare(b.batteryName)
                return ascending ? comparison == .orderedAscending : comparison == .orderedDescending
            }
        case .byUsedIn:
            return { a, b in
                let comparison = a.usedIn.localizedCaseInsensitiveCompare(b.usedIn)
                return ascending ? comparison == .orderedAscending : comparison == .orderedDescending
            }
        case .byLastCharged:
            return { a, b in
                let aDate = a.lastTrackedTime ?? .distantPast
                let bDate = b.lastTrackedTime ?? .distantPast
                return ascending ? aDate < bDate : aDate > bDate
            }
        case .byNextChargeCycle:
            // Batteries without a planned charge cycle go last.
            return { a, b in
                let aDate = a.nextEstimatedChargeTime ?? .distantFuture
                let bDate = b.nextEstimatedChargeTime ?? .distantFuture
                return ascending ? aDate < bDate : aDate > bDate
            }
        }
    }

    private func trackChargeCycle(batteryID: Int) async {
        do {
            try await grocyVM.chargeBattery(id: batteryID, content: BatteryChargeModel(trackedTime: Date().grocyDateTimeString))
            GrocyLogger.info("Tracking charge cycle was successful.")
            trackedCount += 1
            await grocyVM.requestData(objects: [.battery_charge_cycles], additionalObjects: [.batteries])
        } catch {
            GrocyLogger.error("Tracking charge cycle failed. \(error)")
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    // The capsules float in a bar above the list (the navigation layer), so their glass isn't drawn inside a list row
    private var filterCapsules: some View {
        BatteriesFilterActionsView(
            filteredStatus: $filteredStatus,
            numOverdue: count(for: .overdue),
            numDueToday: count(for: .dueToday),
            numDueSoon: count(for: .dueSoon),
            dueSoonDays: dueSoonDays
        )
    }

    var body: some View {
        List {
            if grocyVM.failedToLoadAdditionalObjects.filter({ additionalDataToUpdate.contains($0) }).count > 0 {
                ServerProblemView()
            }
            ForEach(filteredBatteries.sorted(by: sortComparator), id: \.id) { battery in
                let status = BatteryStatus.status(of: battery, dueSoonDays: dueSoonDays)
                BatteryRowView(battery: battery, status: status)
                    .listRowBackground(status?.backgroundColor)
                    .contentShape(.rect)
                    .onTapGesture {
                        batteryInteractionRouter.present(.batteryOverview(batteryID: battery.batteryID))
                    }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint("Shows the battery overview")
                    .contextMenu {
                        Button {
                            Task { await trackChargeCycle(batteryID: battery.batteryID) }
                        } label: {
                            Label("Track charge cycle", systemImage: MySymbols.batteryCharge)
                        }
                        Button {
                            batteryInteractionRouter.present(.trackChargeCycle(batteryID: battery.batteryID))
                        } label: {
                            Label("Track charge cycle at…", systemImage: MySymbols.date)
                        }
                        Divider()
                        Button {
                            batteryInteractionRouter.present(.batteryOverview(batteryID: battery.batteryID))
                        } label: {
                            Label("Battery overview", systemImage: MySymbols.info)
                        }
                        Button {
                            batteryInteractionRouter.present(.batteryJournal(batteryID: battery.batteryID))
                        } label: {
                            Label("Battery journal", systemImage: MySymbols.stockJournal)
                        }
                        Button {
                            if let mdBattery = mdBatteries.first(where: { $0.id == battery.batteryID }) {
                                batteryInteractionRouter.present(.editBattery(mdBattery: mdBattery))
                            }
                        } label: {
                            Label("Edit battery", systemImage: MySymbols.edit)
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        // Can be undone in the journal, so it needs no confirmation.
                        Button {
                            Task { await trackChargeCycle(batteryID: battery.batteryID) }
                        } label: {
                            Label("Charge", systemImage: MySymbols.batteryCharge)
                        }
                        .tint(.green)
                        .accessibilityHint("Track charge cycle")
                    }
            }
        }
        .overlay {
            if grocyVM.failedToLoadAdditionalObjects.filter({ additionalDataToUpdate.contains($0) }).count == 0 {
                if batteriesCount == 0 {
                    ContentUnavailableView {
                        Label("No batteries", systemImage: MySymbols.batteries)
                    } description: {
                        Text("No battery defined. Please create one.")
                    } actions: {
                        Button("Create battery") {
                            showAddBattery = true
                        }
                    }
                } else if batteries.isEmpty {
                    ContentUnavailableView.search
                } else if filteredBatteries.isEmpty {
                    ContentUnavailableView {
                        Label("No batteries", systemImage: MySymbols.batteries)
                    } description: {
                        Text("No battery matches this filter.")
                    }
                }
            }
        }
        // The master data form, as in the master data batteries
        .sheet(isPresented: $showAddBattery, onDismiss: { Task { await updateData() } }) {
            NavigationStack {
                MDBatteryFormView(isPopup: true)
            }
            #if os(macOS)
                .presentationSizing(.form)
            #endif
        }
        .refreshable {
            await updateData()
        }
        .floatingTopBar {
            filterCapsules
                .padding(.vertical, Spacing.small)
        }
        .task {
            await updateData()
        }
        .searchable(text: $searchString, prompt: "Search")
        .animation(.default, value: filteredStatus)
        .navigationTitle("Batteries overview")
        .sheet(item: $batteryInteractionRouter.presentedInteraction) { interaction in
            NavigationStack {
                switch interaction {
                case .batteryJournal(let batteryID):
                    BatteriesJournalView(batteryID: batteryID, isPopup: true)
                case .batteryOverview(let batteryID):
                    BatteryDetailsView(batteryID: batteryID, isPopup: true)
                case .trackChargeCycle(let batteryID):
                    BatteryTrackingView(mdBatteryID: batteryID, isPopup: true)
                case .editBattery(let mdBattery):
                    MDBatteryFormView(existingBattery: mdBattery, isPopup: true)
                }
            }
            // The battery journal is a list.
            .listSheetSize()
        }
        .alert(
            "Couldn't track the charge cycle",
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
        .sensoryFeedback(.success, trigger: trackedCount)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    showingFilterSheet = true
                } label: {
                    Label("Filter", systemImage: MySymbols.filter)
                }
                .badge(numFilters)
                sortGroupMenu
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    batteryInteractionRouter.present(.batteryJournal(batteryID: nil))
                } label: {
                    Label("Batteries journal", systemImage: MySymbols.stockJournal)
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            NavigationStack {
                BatteriesFilterView(filteredStatus: $filteredStatus, dueSoonDays: dueSoonDays)
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
                            Button(role: .destructive) {
                                filteredStatus = .all
                                showingFilterSheet = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium])
            // The filter is a list of pickers.
            .filterSheetSize()
        }
        .environment(batteryInteractionRouter)
    }

    var sortGroupMenu: some View {
        Menu {
            Picker("Sort category", systemImage: MySymbols.sortCategory, selection: $sortOption) {
                Label("Name", systemImage: MySymbols.name)
                    .labelStyle(.titleAndIcon)
                    .tag(BatteriesSortOption.byName)
                Label("Used in", systemImage: MySymbols.batteryUsedIn)
                    .labelStyle(.titleAndIcon)
                    .tag(BatteriesSortOption.byUsedIn)
                Label("Last charged", systemImage: MySymbols.date)
                    .labelStyle(.titleAndIcon)
                    .tag(BatteriesSortOption.byLastCharged)
                Label("Next planned charge cycle", systemImage: MySymbols.date)
                    .labelStyle(.titleAndIcon)
                    .tag(BatteriesSortOption.byNextChargeCycle)
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
        BatteriesView()
    }
}
