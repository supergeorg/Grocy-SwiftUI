//
//  DueView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.26.
//

import SwiftData
import SwiftUI

/// A due item's own page, pushed from the agenda.
enum DueDestination: Hashable {
    case chore(choreID: Int)
    case task(GrocyTask)
    case battery(batteryID: Int)
}

/// A product to add to the shopping list (sheet item).
private struct ShoppingListProduct: Identifiable {
    let id: Int
}

/// The agenda of the smart iPhone navigation: every product, chore, task and battery that is expired, overdue, due today
/// or due soon, and the products below their minimum stock amount, in one list. Swiping does the item (consume or open
/// the product, add it to the shopping list, track the chore, complete the task, charge the battery).
/// Each kind can be hidden (`DueKindToggles`), and each section collapsed; all are shown by default.
///
/// The complete lists (chores, tasks, batteries, equipment) open from the settings button (`AccountView`).
struct DueView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query(filter: #Predicate<StockElement> { $0.amountAggregated > 0 }) private var stock: Stock
    @Query private var volatileStockList: [VolatileStock]
    @Query private var mdProducts: MDProducts
    @Query private var mdQuantityUnits: MDQuantityUnits
    @Query private var chores: Chores
    @Query(filter: #Predicate<GrocyTask> { !$0.done }) private var openTasks: GrocyTasks
    @Query private var batteries: Batteries
    @Query private var grocyUsers: GrocyUsers
    @Query private var mdChores: MDChores
    @Query private var userSettingsList: GrocyUserSettingsList
    @Query private var systemConfigList: [SystemConfig]

    @AppStorage(DueKind.hiddenKindsStorageKey) private var hiddenKindsValue: String = ""
    @AppStorage(DueUrgency.collapsedStorageKey) private var collapsedValue: String = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.grocyFeatures) private var features

    @State private var filteredKind: DueKind? = nil
    @State private var doneCount: Int = 0
    @State private var errorMessage: String? = nil
    @State private var choreInteractionRouter = ChoreInteractionNavigationRouter()
    @State private var batteryInteractionRouter = BatteryInteractionNavigationRouter()
    @State private var stockInteractionRouter = StockInteractionNavigationRouter()
    @State private var shoppingListProduct: ShoppingListProduct? = nil

    private var systemConfig: SystemConfig? { systemConfigList.first }

    private let dataToUpdate: [ObjectEntities] = [.products, .quantity_units, .chores, .tasks, .task_categories, .batteries]
    private let additionalDataToUpdate: [AdditionalEntities] = [.stock, .volatileStock, .chores, .batteries, .user_settings, .current_user, .users]
    private var hiddenKinds: Set<DueKind> { DueKind.hiddenKinds(from: hiddenKindsValue) }

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    private var allItems: [DueItem] {
        DueItem.items(
            stock: stock,
            volatileStock: volatileStockList.first,
            mdProducts: mdProducts,
            chores: chores,
            tasks: openTasks,
            batteries: batteries,
            userSettings: userSettingsList.first,
            systemConfig: systemConfig,
            hiddenKinds: hiddenKinds
        )
    }

    /// The kinds shown: enabled on the server and not hidden by the user.
    private var kinds: [DueKind] {
        DueKind.allCases.filter { $0.place.isEnabled(in: systemConfig) && !hiddenKinds.contains($0) }
    }

    private var collapsed: Set<DueUrgency> { DueUrgency.collapsed(from: collapsedValue) }

    private func toggleCollapsed(_ urgency: DueUrgency) {
        var newCollapsed = collapsed
        if newCollapsed.contains(urgency) { newCollapsed.remove(urgency) } else { newCollapsed.insert(urgency) }
        withAnimation(reduceMotion ? nil : .default) {
            collapsedValue = DueUrgency.encode(collapsed: newCollapsed)
        }
    }

    var body: some View {
        let allItems = allItems
        let items = allItems.filter { filteredKind == nil || $0.kind == filteredKind }
        let counts = Dictionary(grouping: allItems, by: \.kind).mapValues(\.count)

        List {
            if grocyVM.failedToLoadObjects.contains(where: { dataToUpdate.contains($0) })
                || grocyVM.failedToLoadAdditionalObjects.contains(where: { additionalDataToUpdate.contains($0) })
            {
                ServerProblemView()
            } else if items.isEmpty {
                ContentUnavailableView {
                    Label("Nothing due", systemImage: MySymbols.done)
                } description: {
                    Text("Products, chores, tasks and batteries that are overdue or due soon, and products below their minimum stock amount, show up here.")
                }
            }

            ForEach(DueUrgency.allCases) { urgency in
                let group = items.filter { $0.urgency == urgency }
                if !group.isEmpty {
                    Section {
                        if !collapsed.contains(urgency) {
                            ForEach(group) { item in
                                row(for: item)
                            }
                        }
                    } header: {
                        DueSectionHeader(urgency: urgency, count: group.count, isExpanded: !collapsed.contains(urgency)) {
                            toggleCollapsed(urgency)
                        }
                    }
                }
            }
        }
        .refreshable {
            await updateData()
        }
        .floatingTopBar {
            if kinds.count > 1 {
                DueFilterActionsView(filteredKind: $filteredKind, kinds: kinds, counts: counts)
                    .padding(.vertical, Spacing.small)
            }
        }
        .animation(.default, value: filteredKind)
        .onChange(of: hiddenKindsValue) {
            // A hidden kind can't stay the filter.
            if let filteredKind, hiddenKinds.contains(filteredKind) {
                self.filteredKind = nil
            }
        }
        .navigationTitle("Due")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Section("Show") {
                        DueKindToggles()
                    }
                } label: {
                    // Not the filter symbol: the overviews use it for filters, and this menu chooses what the agenda shows.
                    Label("Show", systemImage: MySymbols.show)
                }
            }
        }
        .stockEntriesDestination()
        .navigationDestination(for: DueDestination.self) { destination in
            switch destination {
            case .chore(let choreID):
                ChoreDetailsView(choreID: choreID)
                    .environment(choreInteractionRouter)
            case .task(let task):
                TaskFormView(existingTask: task)
            case .battery(let batteryID):
                BatteryDetailsView(batteryID: batteryID)
                    .environment(batteryInteractionRouter)
            }
        }
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
            .environment(choreInteractionRouter)
        }
        .stockInteractionSheet(router: stockInteractionRouter)
        .sheet(item: $shoppingListProduct) { item in
            NavigationStack {
                ShoppingListEntryFormView(productIDToSelect: item.id, isPopup: true)
            }
        }
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
            .environment(batteryInteractionRouter)
        }
        .alert(
            "Couldn't save the change",
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
        .sensoryFeedback(.success, trigger: doneCount)
        .task {
            await updateData()
        }
    }

    // MARK: - Rows

    private func destination(for item: DueItem) -> DueDestination? {
        switch item.source {
        case .product, .belowMinStock: nil
        case .chore(let chore): .chore(choreID: chore.choreID)
        case .task(let task): .task(task)
        case .battery(let battery): .battery(batteryID: battery.batteryID)
        }
    }

    private func user(for item: DueItem) -> GrocyUser? {
        let userID: Int?
        switch item.source {
        case .chore(let chore): userID = features.choreAssignments ? chore.nextExecutionAssignedToUserID : nil
        case .task(let task): userID = task.assignedToUserID
        case .product, .belowMinStock, .battery: userID = nil
        }
        guard let userID else { return nil }
        return grocyUsers.first(where: { $0.id == userID })
    }

    private func doneTitle(for item: DueItem) -> LocalizedStringKey {
        switch item.kind {
        case .product: "Consume"
        case .belowMinStock: "Add to shopping list"
        case .chore: "Track chore execution now"
        case .task: "Mark task as completed"
        case .battery: "Track charge cycle"
        }
    }

    private func doneIcon(for item: DueItem) -> String {
        switch item.kind {
        case .product: MySymbols.consume
        case .belowMinStock: MySymbols.addToShoppingList
        case .chore: MySymbols.choreTrackNext
        case .task: MySymbols.done
        case .battery: MySymbols.batteryCharge
        }
    }

    @ViewBuilder
    private func row(for item: DueItem) -> some View {
        if case .product(let stockElement) = item.source {
            productRow(for: item, stockElement: stockElement)
        } else if case .belowMinStock(let product, let inStock, _) = item.source {
            belowMinStockRow(for: item, product: product, inStock: inStock)
        } else if let destination = destination(for: item) {
            householdRow(for: item, destination: destination)
        }
    }

    /// The same quick actions as in the stock overview: consume or open the quick consume amount, or consume all.
    private func productRow(for item: DueItem, stockElement: StockElement) -> some View {
        NavigationLink(value: StockEntriesDestination(productID: stockElement.productID)) {
            DueItemRowView(item: item, quantityUnit: quantityUnit(for: stockElement.product))
        }
        .listRowBackground(item.urgency.backgroundColor)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if stockElement.amount > 0 {
                StockTableRowActionsView(stockElement: stockElement, shownActions: [.consumeQA], quantityUnit: quantityUnit(for: stockElement.product))
            }
            if features.openedTracking, (stockElement.amount - stockElement.amountOpened) > 0 {
                StockTableRowActionsView(stockElement: stockElement, shownActions: [.openQA], quantityUnit: quantityUnit(for: stockElement.product))
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if stockElement.amount > 0 {
                StockTableRowActionsView(stockElement: stockElement, shownActions: [.consumeAll], quantityUnit: quantityUnit(for: stockElement.product))
            }
        }
        .contextMenu {
            StockTableMenuEntriesView(stockElement: stockElement, quantityUnit: quantityUnit(for: stockElement.product))
        }
    }

    @ViewBuilder
    private func belowMinStockRow(for item: DueItem, product: MDProduct, inStock: StockElement?) -> some View {
        Group {
            // Opens the product's current stock element, or a stand-in if it isn't in stock.
            NavigationLink(value: StockEntriesDestination(productID: product.id)) {
                DueItemRowView(item: item, quantityUnit: quantityUnit(for: product))
            }
        }
        .listRowBackground(item.urgency.backgroundColor)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                shoppingListProduct = ShoppingListProduct(id: product.id)
            } label: {
                Label("Add to shopping list", systemImage: MySymbols.addToShoppingList)
            }
            .tint(.blue)
        }
        .contextMenu {
            if let inStock {
                StockTableMenuEntriesView(stockElement: inStock, quantityUnit: quantityUnit(for: product))
            } else {
                Button {
                    shoppingListProduct = ShoppingListProduct(id: product.id)
                } label: {
                    Label("Add to shopping list", systemImage: MySymbols.addToShoppingList)
                }
            }
        }
    }

    private func quantityUnit(for product: MDProduct?) -> MDQuantityUnit? {
        mdQuantityUnits.first(where: { $0.id == product?.quIDStock })
    }

    private func householdRow(for item: DueItem, destination: DueDestination) -> some View {
        NavigationLink(value: destination) {
            DueItemRowView(item: item, user: user(for: item))
        }
        .listRowBackground(item.urgency.backgroundColor)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                Task { await markDone(item) }
            } label: {
                Label("OK", systemImage: doneIcon(for: item))
            }
            .tint(.green)
            .accessibilityHint(Text(doneTitle(for: item)))
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if case .chore(let chore) = item.source {
                Button {
                    Task { await trackChore(chore, skipped: true) }
                } label: {
                    Label("Skip", systemImage: MySymbols.choreSkipNext)
                }
                .tint(.gray)
                .accessibilityHint("Skip next chore schedule")
            }
        }
        .contextMenu {
            Button {
                Task { await markDone(item) }
            } label: {
                Label(doneTitle(for: item), systemImage: doneIcon(for: item))
            }
            switch item.source {
            case .chore(let chore):
                Button {
                    Task { await trackChore(chore, skipped: true) }
                } label: {
                    Label("Reschedule next execution", systemImage: MySymbols.choreSkipNext)
                }
                Divider()
                Button {
                    choreInteractionRouter.present(.choreLog(choreID: chore.choreID))
                } label: {
                    Label("Chore journal", systemImage: MySymbols.stockJournal)
                }
                Button {
                    if let mdChore = mdChores.first(where: { $0.id == chore.choreID }) {
                        choreInteractionRouter.present(.editChore(mdChore: mdChore))
                    }
                } label: {
                    Label("Edit chore", systemImage: MySymbols.edit)
                }
            case .battery(let battery):
                Button {
                    batteryInteractionRouter.present(.trackChargeCycle(batteryID: battery.batteryID))
                } label: {
                    Label("Track charge cycle at…", systemImage: MySymbols.date)
                }
                Divider()
                Button {
                    batteryInteractionRouter.present(.batteryJournal(batteryID: battery.batteryID))
                } label: {
                    Label("Battery journal", systemImage: MySymbols.stockJournal)
                }
            case .task, .product, .belowMinStock:
                EmptyView()
            }
        }
    }

    // MARK: - Actions

    private func markDone(_ item: DueItem) async {
        switch item.source {
        case .product, .belowMinStock:
            // Products use the stock overview's actions (see `productRow` and `belowMinStockRow`).
            break
        case .chore(let chore):
            await trackChore(chore)
        case .task(let task):
            await completeTask(task)
        case .battery(let battery):
            await chargeBattery(battery)
        }
    }

    private func trackChore(_ chore: Chore, skipped: Bool = false) async {
        do {
            let executeInfo = ChoreExecuteModel(trackedTime: Date().grocyDateTimeString, doneBy: nil, skipped: skipped)
            _ = try await grocyVM.executeChore(id: chore.id, content: executeInfo)
            GrocyLogger.info("Tracking chore was successful.")
            doneCount += 1
            await updateData()
        } catch {
            GrocyLogger.error("Tracking chore failed. \(error)")
            show(error)
        }
    }

    private func completeTask(_ task: GrocyTask) async {
        do {
            try await grocyVM.executeTask(taskID: task.id, content: TaskExecuteModel(doneTime: Date().grocyDateTimeString))
            GrocyLogger.info("Completing task was successful.")
            doneCount += 1
            await updateData()
        } catch {
            GrocyLogger.error("Completing task failed. \(error)")
            show(error)
        }
    }

    private func chargeBattery(_ battery: Battery) async {
        do {
            try await grocyVM.chargeBattery(id: battery.batteryID, content: BatteryChargeModel(trackedTime: Date().grocyDateTimeString))
            GrocyLogger.info("Tracking charge cycle was successful.")
            doneCount += 1
            await grocyVM.requestData(objects: [.battery_charge_cycles], additionalObjects: [.batteries])
        } catch {
            GrocyLogger.error("Tracking charge cycle failed. \(error)")
            show(error)
        }
    }

    private func show(_ error: Error) {
        if let apiError = error as? APIError {
            errorMessage = apiError.displayMessage
        } else {
            errorMessage = error.localizedDescription
        }
    }
}

/// A section header that collapses and expands its section. The whole header is the button, with a disclosure chevron,
/// and the count stays visible while the section is collapsed.
private struct DueSectionHeader: View {
    var urgency: DueUrgency
    var count: Int
    var isExpanded: Bool
    var toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack {
                Label("\(Text(urgency.title)) (\(count))", systemImage: urgency.icon)
                    .foregroundStyle(urgency.color)
                Spacer()
                Image(systemName: MySymbols.disclosure)
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .accessibilityHidden(true)
            }
            .frame(minHeight: Sizes.minimumHitTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isExpanded ? Text("Expanded") : Text("Collapsed"))
        .accessibilityHint(isExpanded ? Text("Collapses the section") : Text("Expands the section"))
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        DueView()
            .phonePlaceDestinations()
    }
}
