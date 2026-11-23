//
//  MealPlanView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import SwiftData
import SwiftUI

/// What opens the entry form: a new entry for a day (and section, or recipe), or an entry to edit.
struct MealPlanFormRequest: Identifiable, Hashable {
    let id = UUID()
    var existingEntry: MealPlanEntry? = nil
    var day: Date = Date()
    var sectionID: Int? = nil
    var recipeID: Int? = nil

    static func == (lhs: MealPlanFormRequest, rhs: MealPlanFormRequest) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// How much of the meal plan is shown at once.
enum MealPlanPeriod: String, CaseIterable, Identifiable {
    case day
    case week

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .day: "Day"
        case .week: "Week"
        }
    }

    var component: Calendar.Component {
        switch self {
        case .day: .day
        case .week: .weekOfYear
        }
    }
}

/// The meal plan of a day or a week: recipes, products and notes planned per day and section, with what they cost and
/// whether they're in stock. A week is a list of days in narrow windows (iPhone), a grid of days and sections in wide
/// ones (iPad, Mac); a day is a list of its sections.
struct MealPlanView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.locale) private var locale
    @AppStorage("localizationKey") private var localizationKey: String = "en"
    @AppStorage("mealPlanPeriod") private var period: MealPlanPeriod = .week
    @AppStorage(MealPlanNames.firstWeekdayKey) private var firstWeekday: Int = MealPlanNames.serverFirstWeekday

    @Query(sort: \MealPlanEntry.id) private var entries: MealPlanEntries
    @Query private var sectionsAll: MDMealPlanSections
    @Query(sort: \Recipe.name) private var recipes: Recipes
    @Query private var fulfillments: RecipeFulfilments
    @Query private var products: MDProducts
    @Query private var quantityUnits: MDQuantityUnits
    @Query private var stock: [StockElement]
    @Query(sort: \ShoppingListDescription.id) private var shoppingLists: ShoppingListDescriptions
    @Query private var systemConfigList: [SystemConfig]

    /// A day of the shown period; switching between day and week keeps it.
    @State private var shownDate: Date = Date()
    /// Where the next period comes in from, so titles and days slide the way the person moved.
    @State private var moveEdge: Edge = .trailing
    @State private var contentWidth: CGFloat = 0
    @State private var showSections: Bool = false

    @State private var formRequest: MealPlanFormRequest? = nil
    @State private var dayToCopy: Date? = nil
    @State private var recipeToShow: Recipe? = nil

    @State private var entryToDelete: MealPlanEntry? = nil
    @State private var entryToConsume: MealPlanEntry? = nil
    @State private var entryToAddToShoppingList: MealPlanEntry? = nil
    @State private var showWeekToShoppingList: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successTrigger: Bool = false

    private let dataToUpdate: [ObjectEntities] = [.meal_plan, .meal_plan_sections, .recipes, .products, .quantity_units, .shopping_lists]
    private let additionalDataToUpdate: [AdditionalEntities] = [.recipeFulfillments, .stock, .system_config]

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    /// Reloads what a change on the server touched. Grocy's change time has a one-second resolution, so a change in the
    /// same second as the last sync would otherwise be skipped.
    private func reloadAfterChange(stockChanged: Bool = false) async {
        grocyVM.timeStampsObjects[.meal_plan] = nil
        grocyVM.timeStampsObjects[.recipes] = nil
        grocyVM.timeStampsAdditionalObjects[.recipeFulfillments] = nil
        var additional: [AdditionalEntities] = [.recipeFulfillments]
        if stockChanged {
            grocyVM.timeStampsAdditionalObjects[.stock] = nil
            additional.append(.stock)
        }
        await grocyVM.requestData(objects: [.meal_plan, .recipes], additionalObjects: additional)
    }

    // MARK: - Computed

    private var systemConfig: SystemConfig? { systemConfigList.first }

    private var calendar: Calendar {
        MealPlanNames.calendar(
            firstWeekday: firstWeekday,
            mealPlanFirstDayOfWeek: systemConfig?.mealPlanFirstDayOfWeek,
            calendarFirstDayOfWeek: systemConfig?.calendarFirstDayOfWeek,
            locale: Locale(identifier: localizationKey)
        )
    }

    private var weekStart: Date { calendar.startOfWeek(for: shownDate) }

    /// The shown days: the week of `shownDate`, or only that day.
    private var days: [Date] {
        switch period {
        case .week: calendar.daysOfWeek(startingAt: weekStart)
        case .day: [calendar.startOfDay(for: shownDate)]
        }
    }

    private var showsToday: Bool {
        switch period {
        case .week: calendar.startOfWeek(for: Date()) == weekStart
        case .day: calendar.isDateInToday(shownDate)
        }
    }

    /// Identifies the shown period, so its days are replaced (and slide) when it changes.
    private var periodID: String {
        "\(period.rawValue)-\(MealPlanNames.dayName(for: days.first ?? shownDate))"
    }

    private var lookup: MealPlanLookup {
        MealPlanLookup(
            recipes: recipes,
            fulfillments: fulfillments,
            products: products,
            quantityUnits: quantityUnits,
            stock: stock,
            sections: sectionsAll,
            systemConfig: systemConfig
        )
    }

    /// The week's entries by day (`YYYY-MM-DD`), each day in the order of the sections.
    private func entriesByDay(lookup: MealPlanLookup) -> [String: MealPlanEntries] {
        let dayNames = Set(days.map(MealPlanNames.dayName(for:)))
        let weekEntries = entries.filter { dayNames.contains(MealPlanNames.dayName(for: $0.day)) }
        return Dictionary(grouping: weekEntries, by: { MealPlanNames.dayName(for: $0.day) })
            .mapValues { $0.sorted { lookup.sortKey(of: $0) < lookup.sortKey(of: $1) } }
    }

    /// The rows of the grid and the day: every section, and the one without a name only when something shown is in it.
    private func shownSections(entriesByDay: [String: MealPlanEntries], lookup: MealPlanLookup) -> MDMealPlanSections {
        let usesNoSection = entriesByDay.values.joined().contains { lookup.sectionsByID[$0.sectionID]?.isNoSection ?? true }
        let sections = sectionsAll.sortedForMealPlan.filter { !$0.isNoSection }
        if sections.isEmpty || usesNoSection {
            return [lookup.sectionsByID[MDMealPlanSection.noSectionID] ?? MDMealPlanSection(id: MDMealPlanSection.noSectionID)] + sections
        }
        return sections
    }

    private var showsShoppingList: Bool { systemConfig?.featureFlagShoppinglist ?? true }

    private var usesGrid: Bool {
        !dynamicTypeSize.isAccessibilitySize && contentWidth >= Sizes.mealPlanSectionLabelWidth + 7 * Sizes.mealPlanDayMinWidth
    }

    private var periodTitle: String {
        switch period {
        case .week:
            guard let lastDay = days.last else { return "" }
            return (weekStart..<lastDay).formatted(.interval.day().month(.abbreviated).year().locale(locale))
        case .day:
            let isThisYear = calendar.isDate(shownDate, equalTo: Date(), toGranularity: .year)
            let style = Date.FormatStyle.dateTime.weekday(.wide).day().month(.abbreviated).locale(locale)
            return shownDate.formatted(isThisYear ? style : style.year())
        }
    }

    /// What everything shown costs and its calories, from Grocy's day recipes.
    private func periodSummary(lookup: MealPlanLookup, entriesByDay: [String: MealPlanEntries]) -> String? {
        let dayFulfillments = days.filter { entriesByDay[MealPlanNames.dayName(for: $0)]?.isEmpty == false }.compactMap(lookup.dayFulfillment(for:))
        guard !dayFulfillments.isEmpty else { return nil }
        var parts: [String] = []
        let costs = dayFulfillments.compactMap(\.costs).reduce(0, +)
        if lookup.showsCosts, costs > 0 {
            parts.append(grocyVM.getFormattedCurrency(amount: costs))
        }
        let calories = dayFulfillments.compactMap(\.calories).reduce(0, +)
        if calories > 0 {
            parts.append("\(calories.formatted(.number.precision(.fractionLength(0)).locale(locale))) \(lookup.energyUnit)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    // MARK: - Actions

    private func move(by value: Int) {
        guard let date = calendar.date(byAdding: period.component, value: value, to: shownDate) else { return }
        moveEdge = value > 0 ? .trailing : .leading
        withAnimation(.snappy) {
            shownDate = date
        }
    }

    private func showToday() {
        let today = Date()
        moveEdge = today > shownDate ? .trailing : .leading
        withAnimation(.snappy) {
            shownDate = today
        }
    }

    /// The missing products of what's shown: of the day, or of Grocy's weeks the shown week lies in.
    private func shownRecipeIDs(lookup: MealPlanLookup) -> [Int] {
        switch period {
        case .week: lookup.weekRecipeIDs(for: days)
        case .day: days.compactMap(lookup.dayRecipeID(for:))
        }
    }

    /// A horizontal swipe moves to the previous or next period, as in Calendar. Vertical drags are left to scrolling.
    private var periodSwipe: some Gesture {
        DragGesture(minimumDistance: Sizes.minimumHitTarget / 2)
            .onEnded { value in
                let width = value.translation.width
                guard abs(width) > Sizes.minimumHitTarget * 1.5, abs(width) > abs(value.translation.height) * 2 else { return }
                // Swiping to the left brings the next period, like turning a page.
                move(by: width < 0 ? 1 : -1)
            }
    }

    private func select(_ entry: MealPlanEntry, lookup: MealPlanLookup) {
        if entry.type == .recipe, let recipe = lookup.recipe(of: entry) {
            recipeToShow = recipe
        } else {
            formRequest = MealPlanFormRequest(existingEntry: entry)
        }
    }

    private func perform(_ action: MealPlanEntryAction, on entry: MealPlanEntry, lookup: MealPlanLookup) {
        switch action {
        case .edit:
            formRequest = MealPlanFormRequest(existingEntry: entry)
        case .toggleDone:
            Task { await setDone(!entry.done, for: entry) }
        case .consume:
            if entry.type == .recipe {
                entryToConsume = entry
            } else {
                Task { await consumeProduct(of: entry) }
            }
        case .addToShoppingList:
            if entry.type == .recipe {
                entryToAddToShoppingList = entry
            } else {
                Task { await addProductToShoppingList(entry) }
            }
        case .delete:
            entryToDelete = entry
        }
    }

    private func handle(_ error: Error, _ message: String) {
        GrocyLogger.error("\(message) \(error)")
        errorMessage = (error as? APIError)?.displayMessage ?? error.localizedDescription
    }

    private func setDone(_ done: Bool, for entry: MealPlanEntry) async {
        do {
            try await grocyVM.putMDObjectWithID(object: .meal_plan, id: entry.id, content: MealPlanDoneModel(done: done))
            GrocyLogger.info("Marking meal plan entry as \(done ? "done" : "not done") was successful.")
            // Shown at once; the sync confirms it.
            entry.done = done
            await reloadAfterChange()
        } catch {
            handle(error, "Marking meal plan entry failed.")
        }
    }

    private func consumeRecipe(of entry: MealPlanEntry) async {
        guard let shadowRecipeID = lookup.shadowRecipeID(of: entry) else { return }
        do {
            try await grocyVM.consumeRecipe(recipeID: shadowRecipeID)
            try await grocyVM.putMDObjectWithID(object: .meal_plan, id: entry.id, content: MealPlanDoneModel(done: true))
            GrocyLogger.info("Consuming meal plan recipe was successful.")
            successTrigger.toggle()
            await reloadAfterChange(stockChanged: true)
        } catch {
            handle(error, "Consuming meal plan recipe failed.")
        }
    }

    private func consumeProduct(of entry: MealPlanEntry) async {
        guard let productID = entry.productID else { return }
        do {
            try await grocyVM.postStockObject(id: productID, stockModePost: .consume, content: ProductConsume(amount: entry.productAmount))
            try await grocyVM.putMDObjectWithID(object: .meal_plan, id: entry.id, content: MealPlanDoneModel(done: true))
            GrocyLogger.info("Consuming meal plan product was successful.")
            successTrigger.toggle()
            await reloadAfterChange(stockChanged: true)
        } catch {
            handle(error, "Consuming meal plan product failed.")
        }
    }

    private func addMissingProducts(ofRecipes recipeIDs: [Int]) async {
        do {
            for recipeID in recipeIDs {
                try await grocyVM.addNotFulfilledProductsToShoppinglist(recipeID: recipeID, content: RecipeAddToShLModel())
            }
            GrocyLogger.info("Adding missing meal plan products to the shopping list was successful.")
            successTrigger.toggle()
            grocyVM.timeStampsObjects[.shopping_list] = nil
            await grocyVM.requestData(objects: [.shopping_list])
            await reloadAfterChange()
        } catch {
            handle(error, "Adding missing meal plan products to the shopping list failed.")
        }
    }

    private func addProductToShoppingList(_ entry: MealPlanEntry) async {
        guard let productID = entry.productID else { return }
        do {
            let content = ShoppingListAddProductModel(
                productID: productID,
                listID: shoppingLists.first?.id ?? 1,
                productAmount: entry.productAmount,
                note: nil
            )
            try await grocyVM.addProductToShoppingList(content: content)
            GrocyLogger.info("Adding meal plan product to the shopping list was successful.")
            successTrigger.toggle()
            grocyVM.timeStampsObjects[.shopping_list] = nil
            await grocyVM.requestData(objects: [.shopping_list])
        } catch {
            handle(error, "Adding meal plan product to the shopping list failed.")
        }
    }

    private func deleteEntry(_ entry: MealPlanEntry) async {
        do {
            try await grocyVM.deleteMDObject(object: .meal_plan, id: entry.id)
            GrocyLogger.info("Deleting meal plan entry was successful.")
            await reloadAfterChange()
        } catch {
            handle(error, "Deleting meal plan entry failed.")
        }
    }

    /// Copies a day's entries to another day, not done, as the Grocy web app does.
    private func copyDay(_ sourceDay: Date, to targetDay: Date) async -> Bool {
        let dayName = MealPlanNames.dayName(for: sourceDay)
        let sourceEntries = entries.filter { MealPlanNames.dayName(for: $0.day) == dayName }
        var usedIDs = Set(entries.map(\.id))
        do {
            // Reloaded first, so new IDs don't collide with entries added elsewhere.
            await grocyVM.requestData(objects: [.meal_plan])
            usedIDs.formUnion(grocyVM.mealPlan.map(\.id))
            for sourceEntry in sourceEntries {
                var nextID = 1
                while usedIDs.contains(nextID) { nextID += 1 }
                usedIDs.insert(nextID)
                let copy = MealPlanEntry(copying: sourceEntry)
                copy.id = nextID
                copy.day = targetDay
                copy.done = false
                _ = try await grocyVM.postMDObject(object: .meal_plan, content: copy)
            }
            GrocyLogger.info("Copying meal plan day was successful.")
            successTrigger.toggle()
            await reloadAfterChange()
            return true
        } catch {
            handle(error, "Copying meal plan day failed.")
            await reloadAfterChange()
            return false
        }
    }

    // MARK: - Views

    private func mainView(lookup: MealPlanLookup, entriesByDay: [String: MealPlanEntries]) -> some View {
        ZStack {
            content(entriesByDay: entriesByDay, lookup: lookup)
                .id(periodID)
                .transition(.push(from: moveEdge))
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            contentWidth = width
        }
        // The period switcher floats above the days (the navigation layer).
        .floatingTopBar {
            periodBar(summary: periodSummary(lookup: lookup, entriesByDay: entriesByDay))
                .padding(.vertical, Spacing.small)
        }
        .navigationTitle("Meal plan")
        .toolbar {
            toolbarContent(lookup: lookup)
        }
        .task {
            await updateData()
        }
    }

    /// The forms and sheets the meal plan opens; apart from `body`, which is too long to type-check otherwise.
    private func presentations(_ base: some View) -> some View {
        base
            #if os(iOS)
                .sheet(item: $formRequest) { request in
                    NavigationStack {
                        formView(for: request)
                    }
                }
                .sheet(item: dayToCopyBinding) { day in
                    NavigationStack {
                        MealPlanCopyDayView(sourceDay: day.date) { targetDay in
                            await copyDay(day.date, to: targetDay)
                        }
                    }
                    .presentationDetents([.medium])
                }
            #else
                .navigationDestination(item: $formRequest) { request in
                    formView(for: request)
                }
                .navigationDestination(item: dayToCopyBinding) { day in
                    MealPlanCopyDayView(sourceDay: day.date) { targetDay in
                        await copyDay(day.date, to: targetDay)
                    }
                }
            #endif
            // A sheet on the Mac too: the sections are edited aside, the meal plan stays where it was.
            .sheet(isPresented: $showSections) {
                NavigationStack {
                    MealPlanSectionsView()
                }
                // The system's size for a form sheet; on the Mac, a fixed minimum looked cramped.
                .presentationSizing(.form)
            }
    }

    var body: some View {
        let lookup = lookup
        let entriesByDay = entriesByDay(lookup: lookup)

        presentations(mainView(lookup: lookup, entriesByDay: entriesByDay))
            .navigationDestination(item: $recipeToShow) { recipe in
                RecipeView(initialRecipe: recipe)
            }
            .alert(
                "Are you sure you want to delete \"\(entryToDelete.map { entryTitle($0, lookup: lookup) } ?? "")\" from the meal plan?",
                isPresented: Binding(get: { entryToDelete != nil }, set: { if !$0 { entryToDelete = nil } }),
                presenting: entryToDelete,
                actions: { entry in
                    Button("Cancel", role: .cancel) {}
                    // No destructive role: the person chose to delete, this button carries out their intent (HIG).
                    Button("Delete") {
                        Task { await deleteEntry(entry) }
                    }
                },
                message: { _ in
                    Text("This can't be undone.")
                }
            )
            .alert(
                "Are you sure you want to consume all ingredients needed by recipe \"\(entryToConsume.map { entryTitle($0, lookup: lookup) } ?? "")\"?",
                isPresented: Binding(get: { entryToConsume != nil }, set: { if !$0 { entryToConsume = nil } }),
                presenting: entryToConsume,
                actions: { entry in
                    Button("Cancel", role: .cancel) {}
                    Button("Consume") {
                        Task { await consumeRecipe(of: entry) }
                    }
                },
                message: { _ in
                    Text("For ingredients that are only partially in stock, the in stock amount will be consumed.")
                }
            )
            .alert(
                "Are you sure you want to put all missing ingredients for recipe \"\(entryToAddToShoppingList.map { entryTitle($0, lookup: lookup) } ?? "")\" on the shopping list?",
                isPresented: Binding(get: { entryToAddToShoppingList != nil }, set: { if !$0 { entryToAddToShoppingList = nil } }),
                presenting: entryToAddToShoppingList,
                actions: { entry in
                    Button("Cancel", role: .cancel) {}
                    Button("Add") {
                        if let shadowRecipeID = lookup.shadowRecipeID(of: entry) {
                            Task { await addMissingProducts(ofRecipes: [shadowRecipeID]) }
                        }
                    }
                }
            )
            .alert(
                period == .week
                    ? "Are you sure you want to put all missing products of this week on the shopping list?"
                    : "Are you sure you want to put all missing products of this day on the shopping list?",
                isPresented: $showWeekToShoppingList,
                actions: {
                    Button("Cancel", role: .cancel) {}
                    Button("Add") {
                        Task { await addMissingProducts(ofRecipes: shownRecipeIDs(lookup: lookup)) }
                    }
                },
                message: {
                    if period == .week {
                        Text("Grocy sums up the meal plan per week from Monday to Sunday.")
                    }
                }
            )
            .alert(
                "Error",
                isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }),
                actions: {
                    Button("OK", role: .cancel) {}
                },
                message: {
                    Text(errorMessage ?? "")
                }
            )
            .sensoryFeedback(.success, trigger: successTrigger)
    }

    @ViewBuilder
    private func content(entriesByDay: [String: MealPlanEntries], lookup: MealPlanLookup) -> some View {
        if grocyVM.failedToLoadObjects.contains(where: dataToUpdate.contains) {
            List {
                ServerProblemView()
            }
        } else if period == .day, let day = days.first {
            dayView(day: day, entries: entriesByDay[MealPlanNames.dayName(for: day)] ?? [], entriesByDay: entriesByDay, lookup: lookup)
                .refreshable {
                    await updateData()
                }
        } else if usesGrid {
            MealPlanWeekGridView(
                days: days,
                sections: shownSections(entriesByDay: entriesByDay, lookup: lookup),
                entriesByDay: entriesByDay,
                lookup: lookup,
                showsShoppingList: showsShoppingList,
                onSelect: { select($0, lookup: lookup) },
                onAdd: { day, sectionID in formRequest = MealPlanFormRequest(day: day, sectionID: sectionID) },
                onCopy: { dayToCopy = $0 },
                perform: { action, entry in perform(action, on: entry, lookup: lookup) }
            )
            .refreshable {
                await updateData()
            }
            #if os(iOS)
                // The grid has no swipe actions of its own, so a swipe can turn the week.
                .simultaneousGesture(periodSwipe)
            #endif
        } else {
            weekList(entriesByDay: entriesByDay, lookup: lookup)
                .refreshable {
                    await updateData()
                }
        }
    }

    @ToolbarContentBuilder
    private func toolbarContent(lookup: MealPlanLookup) -> some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button(
                action: {
                    let today = Date()
                    let day = days.contains { calendar.isDate($0, inSameDayAs: today) } ? today : (days.first ?? today)
                    formRequest = MealPlanFormRequest(day: day)
                },
                label: {
                    Label("Add to meal plan", systemImage: MySymbols.new)
                }
            )
            .keyboardShortcut("n", modifiers: .command)
        }
        #if os(macOS)
            ToolbarItem {
                periodPicker
                    .pickerStyle(.segmented)
            }
        #endif
        #if os(macOS)
            // The Mac's toolbar shows secondary actions as bare icons; a menu gives each its name.
            ToolbarItem {
                Menu {
                    moreActions(lookup: lookup)
                } label: {
                    Label("More", systemImage: MySymbols.moreActions)
                }
            }
        #else
            ToolbarItemGroup(placement: .secondaryAction) {
                // A submenu: an inline picker isn't shown in the toolbar's overflow menu.
                periodPicker
                    .pickerStyle(.menu)
                moreActions(lookup: lookup)
            }
        #endif
    }

    @ViewBuilder
    private func moreActions(lookup: MealPlanLookup) -> some View {
        if period == .day, let day = days.first {
            Button(
                action: { dayToCopy = day },
                label: {
                    Label("Copy this day", systemImage: MySymbols.copyDay)
                }
            )
            .disabled(entries.allSatisfy { !calendar.isDate($0.day, inSameDayAs: day) })
        }
        if showsShoppingList {
            Button(
                action: { showWeekToShoppingList = true },
                label: {
                    // Short for the menu; the confirmation says whether it's the day or the week.
                    Label("Put missing products on the shopping list", systemImage: MySymbols.addToShoppingList)
                }
            )
            .disabled(shownRecipeIDs(lookup: lookup).isEmpty)
        }
        Divider()
        Button(
            action: { showSections = true },
            label: {
                Label("Edit sections…", systemImage: MySymbols.mealPlanSection)
            }
        )
    }

    /// Day or week, as in Calendar (⌘1, ⌘2).
    private var periodPicker: some View {
        Picker(
            selection: Binding(
                get: { period },
                set: { newPeriod in withAnimation(.snappy) { period = newPeriod } }
            )
        ) {
            ForEach(MealPlanPeriod.allCases) { period in
                Text(period.title)
                    .tag(period)
            }
        } label: {
            Label("View", systemImage: MySymbols.mealPlanPeriod)
        }
    }

    private func formView(for request: MealPlanFormRequest) -> some View {
        MealPlanEntryFormView(
            existingEntry: request.existingEntry,
            day: request.day,
            sectionID: request.sectionID,
            recipeID: request.recipeID
        )
    }

    /// `Date` isn't `Identifiable`, so the day to copy is wrapped for the sheet.
    private var dayToCopyBinding: Binding<IdentifiableDay?> {
        Binding(
            get: { dayToCopy.map(IdentifiableDay.init) },
            set: { dayToCopy = $0?.date }
        )
    }

    private func entryTitle(_ entry: MealPlanEntry, lookup: MealPlanLookup) -> String {
        switch entry.type {
        case .recipe: lookup.recipe(of: entry)?.name ?? ""
        case .product: lookup.product(of: entry)?.name ?? ""
        case .note: entry.note
        }
    }

    /// Previous and next period around the title. Away from today, a "Today" capsule grows out of the next button
    /// (the buttons share a glass container, so the glass flows between them).
    private func periodBar(summary: String?) -> some View {
        GlassEffectContainer(spacing: Spacing.large) {
            HStack(spacing: Spacing.small) {
                Button(action: { move(by: -1) }) {
                    Label(period == .week ? "Previous week" : "Previous day", systemImage: MySymbols.previousWeek)
                        .labelStyle(.iconOnly)
                        .frame(minWidth: Sizes.minimumHitTarget, minHeight: Sizes.minimumHitTarget)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .keyboardShortcut(.leftArrow, modifiers: .command)

                VStack(spacing: Spacing.hairline) {
                    Text(periodTitle)
                        .font(.headline)
                        // The full width, so the old title slides out of the bar instead of over the new one.
                        .frame(maxWidth: .infinity)
                        .id(periodTitle)
                        .transition(.push(from: moveEdge))
                    if let summary {
                        Text(summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .clipped()
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)

                if !showsToday {
                    Button(action: showToday) {
                        Text("Today")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, Spacing.xSmall)
                            .frame(minHeight: Sizes.minimumHitTarget)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)
                    .keyboardShortcut("t", modifiers: .command)
                    .transition(ScaleTransition(0.6, anchor: .trailing).combined(with: OpacityTransition()))
                }

                Button(action: { move(by: 1) }) {
                    Label(period == .week ? "Next week" : "Next day", systemImage: MySymbols.nextWeek)
                        .labelStyle(.iconOnly)
                        .frame(minWidth: Sizes.minimumHitTarget, minHeight: Sizes.minimumHitTarget)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .keyboardShortcut(.rightArrow, modifiers: .command)
            }
            .padding(.horizontal, Spacing.large)
        }
        .animation(.snappy, value: showsToday)
        #if os(iOS)
            // The bar is always free of swipe actions, so it turns the period in every layout.
            .contentShape(.rect)
            .gesture(periodSwipe)
        #endif
        // Day and week, without the menu: ⌘1 and ⌘2, as in Calendar.
        .background {
            Group {
                Button("Day") { withAnimation(.snappy) { period = .day } }
                    .keyboardShortcut("1", modifiers: .command)
                Button("Week") { withAnimation(.snappy) { period = .week } }
                    .keyboardShortcut("2", modifiers: .command)
            }
            .hidden()
            .accessibilityHidden(true)
        }
    }

    // MARK: - Lists

    private func entryRow(_ entry: MealPlanEntry, lookup: MealPlanLookup, showsSection: Bool) -> some View {
        Button {
            select(entry, lookup: lookup)
        } label: {
            MealPlanEntryRowView(entry: entry, lookup: lookup, showsSection: showsSection)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                perform(.toggleDone, on: entry, lookup: lookup)
            } label: {
                if entry.done {
                    Label("Mark as not done", systemImage: MySymbols.undone)
                } else {
                    Label("Mark as done", systemImage: MySymbols.done)
                }
            }
            .tint(Color(.GrocyColors.grocyGreen))
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                perform(.delete, on: entry, lookup: lookup)
            } label: {
                Label("Delete", systemImage: MySymbols.delete)
            }
            Button {
                perform(.edit, on: entry, lookup: lookup)
            } label: {
                Label("Edit", systemImage: MySymbols.edit)
            }
        }
        .contextMenu {
            MealPlanEntryActionsView(entry: entry, lookup: lookup, showsShoppingList: showsShoppingList) { action in
                perform(action, on: entry, lookup: lookup)
            }
        }
    }

    private func addButton(day: Date, sectionID: Int? = nil) -> some View {
        Button {
            formRequest = MealPlanFormRequest(day: day, sectionID: sectionID)
        } label: {
            Label("Nothing planned", systemImage: MySymbols.new)
                .foregroundStyle(.secondary)
        }
    }

    /// The week as a list of days, for narrow windows.
    private func weekList(entriesByDay: [String: MealPlanEntries], lookup: MealPlanLookup) -> some View {
        List {
            ForEach(days, id: \.self) { day in
                let dayEntries = entriesByDay[MealPlanNames.dayName(for: day)] ?? []
                Section {
                    if dayEntries.isEmpty {
                        addButton(day: day)
                    }
                    ForEach(dayEntries, id: \.id) { entry in
                        entryRow(entry, lookup: lookup, showsSection: true)
                    }
                } header: {
                    MealPlanDayHeaderView(
                        day: day,
                        lookup: lookup,
                        hasEntries: !dayEntries.isEmpty,
                        onAdd: { formRequest = MealPlanFormRequest(day: day) },
                        onCopy: { dayToCopy = day }
                    )
                }
            }
        }
    }

    /// A day as a list of its sections; the bar above names the day.
    private func dayView(day: Date, entries dayEntries: MealPlanEntries, entriesByDay: [String: MealPlanEntries], lookup: MealPlanLookup) -> some View {
        List {
            ForEach(shownSections(entriesByDay: entriesByDay, lookup: lookup), id: \.id) { section in
                let sectionEntries = dayEntries.filter { entry in
                    // Entries of a deleted section are shown without a section.
                    let sectionID = lookup.sectionsByID[entry.sectionID] == nil ? MDMealPlanSection.noSectionID : entry.sectionID
                    return sectionID == section.id
                }
                Section {
                    if sectionEntries.isEmpty {
                        addButton(day: day, sectionID: section.id)
                    }
                    ForEach(sectionEntries, id: \.id) { entry in
                        entryRow(entry, lookup: lookup, showsSection: false)
                    }
                } header: {
                    if !section.isNoSection {
                        HStack(alignment: .firstTextBaseline) {
                            Text(section.name)
                            Spacer()
                            if !section.timeInfo.isEmpty {
                                Label(section.timeInfo, systemImage: MySymbols.sectionTime)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

/// A day for `sheet(item:)`.
struct IdentifiableDay: Identifiable, Hashable {
    let date: Date
    var id: Date { date }
}

#Preview(traits: .previewData) {
    NavigationStack {
        MealPlanView()
    }
}
