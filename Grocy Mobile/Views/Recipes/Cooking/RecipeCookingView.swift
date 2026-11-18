//
//  RecipeCookingView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import SwiftData
import SwiftUI

/// Cooking mode for a recipe: a mise en place checklist of the ingredients first, then one page per preparation step,
/// and a last page to finish (and consume the ingredients).
///
/// The pages scroll horizontally and snap. The steps come from the preparation HTML (`RecipePreparationFormat`):
/// each `<li>` of an `<ol>` is a step; other HTML is split into its paragraphs.
struct RecipeCookingView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query private var mdProducts: MDProducts
    @Query private var mdQuantityUnits: MDQuantityUnits
    @Query private var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query private var ingredients: [RecipePosResolvedElement]

    let recipe: Recipe

    /// The ingredients the person has ready, by `CookingIngredient.id` (stable across syncs, unlike the element's UUID).
    @State private var readyIngredients: Set<String> = []
    @State private var currentPage: Int = 0

    @State private var showConsumeConfirmation: Bool = false
    @State private var isProcessing: Bool = false
    @State private var isConsumed: Bool = false
    @State private var errorMessage: String?

    init(recipe: Recipe) {
        self.recipe = recipe
        let recipeID = recipe.id
        _ingredients = Query(filter: #Predicate<RecipePosResolvedElement> { $0.recipeID == recipeID })
    }

    // MARK: Data

    private var steps: [RecipePreparationStep] {
        RecipePreparationFormat.steps(fromHTML: recipe.recipeDescription)
    }

    private var ingredientGroups: [(name: String, ingredients: [CookingIngredient])] {
        ingredients.groupedForDisplay.map { group in
            (name: group.name, ingredients: group.ingredients.map(cookingIngredient))
        }
    }

    private func cookingIngredient(_ ingredient: RecipePosResolvedElement) -> CookingIngredient {
        let display = RecipeAmountConversion.displayAmount(
            for: ingredient,
            products: mdProducts,
            quantityUnits: mdQuantityUnits,
            conversions: mdQuantityUnitConversions
        )
        let amountText: String
        if !ingredient.recipeVariableAmount.isEmpty {
            amountText = ingredient.recipeVariableAmount
        } else {
            let unitName = display.unit?.getName(amount: display.amount) ?? ""
            amountText = unitName.isEmpty ? display.amount.formattedAmount : "\(display.amount.formattedAmount) \(unitName)"
        }
        return CookingIngredient(
            id: "\(ingredient.recipeID)-\(ingredient.recipePosID)-\(ingredient.productID)",
            name: ingredient.productName,
            amountText: amountText,
            note: ingredient.note
        )
    }

    // MARK: Pages

    /// Page 0 is the mise en place, then one page per step, then the finish page.
    private var pageCount: Int { steps.count + 2 }
    private var finishPage: Int { pageCount - 1 }
    private var page: Int { currentPage }

    private func goToPage(_ newPage: Int) {
        let target = min(max(newPage, 0), finishPage)
        withAnimation(reduceMotion ? nil : .smooth) {
            currentPage = target
        }
    }

    private var pageTitle: LocalizedStringKey {
        if page == 0 { return "Mise en place" }
        if page == finishPage { return "Finished" }
        return "Step \(page) of \(steps.count)"
    }

    private var nextButtonTitle: LocalizedStringKey {
        if page == 0 { return steps.isEmpty ? "Finish" : "Start cooking" }
        return page == finishPage - 1 ? "Finish" : "Next"
    }

    // MARK: Actions

    private func consumeIngredients() async {
        isProcessing = true
        do {
            try await grocyVM.consumeRecipe(recipeID: recipe.id)
            GrocyLogger.info("Consume all ingredients of recipe \(recipe.name) successful.")
            await grocyVM.requestData(objects: [.recipes_pos_resolved], additionalObjects: [.stock, .recipeFulfillments])
            errorMessage = nil
            isConsumed = true
        } catch {
            GrocyLogger.error("Consume all ingredients of recipe \(recipe.name) failed. \(error)")
            errorMessage = (error as? APIError)?.displayMessage ?? error.localizedDescription
        }
        isProcessing = false
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            pager
            .navigationTitle(recipe.name)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
                #if os(iOS)
                    ToolbarItem(placement: .bottomBar) {
                        previousButton
                    }
                    ToolbarSpacer(.flexible, placement: .bottomBar)
                    ToolbarItem(placement: .bottomBar) {
                        pageIndicator
                    }
                    // Plain text, not a control, so no glass behind it.
                    .sharedBackgroundVisibility(.hidden)
                    ToolbarSpacer(.flexible, placement: .bottomBar)
                    ToolbarItem(placement: .bottomBar) {
                        nextButton
                    }
                #endif
            }
            #if os(macOS)
                .safeAreaBar(edge: .bottom) {
                    HStack {
                        previousButton
                        Spacer()
                        pageIndicator
                        Spacer()
                        nextButton
                    }
                    .padding()
                }
            #endif
        }
        #if os(macOS)
            .frame(minWidth: Constants.macOSCookingMinWidth, minHeight: Constants.macOSCookingMinHeight)
        #endif
        #if os(iOS)
            // The screen stays on while cooking, so the step is still visible with dough on the fingers.
            .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        #endif
        .sensoryFeedback(.selection, trigger: currentPage)
        .sensoryFeedback(.success, trigger: isConsumed) { _, newValue in newValue }
        .alert(
            "Consume all ingredients needed by this recipe",
            isPresented: $showConsumeConfirmation,
            actions: {
                Button("Cancel", role: .cancel) {}
                Button("Consume") {
                    Task { await consumeIngredients() }
                }
            },
            message: {
                Text(
                    "\(Text("Are you sure you want to consume all ingredients needed by recipe \"\(recipe.name)\" (ingredients marked with \"only check if any amount is in stock\" will be ignored)?"))\n\n\(Text("For ingredients that are only partially in stock, the in stock amount will be consumed."))"
                )
            }
        )
    }

    /// The pages, swiped horizontally. iOS uses the system's paging tab view (it handles the lists' safe areas);
    /// macOS has no page style, so it uses a paging scroll view.
    @ViewBuilder
    private var pager: some View {
        #if os(iOS)
            TabView(selection: $currentPage) {
                ForEach(0..<pageCount, id: \.self) { index in
                    pageContent(index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color(.systemGroupedBackground))
        #else
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<pageCount, id: \.self) { index in
                        pageContent(index)
                            .containerRelativeFrame([.horizontal, .vertical])
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: Binding { Optional(currentPage) } set: { if let newPage = $0 { currentPage = newPage } })
            .scrollIndicators(.hidden)
        #endif
    }

    @ViewBuilder
    private func pageContent(_ index: Int) -> some View {
        if index == 0 {
            miseEnPlacePage
        } else if index == finishPage {
            finishPageContent
        } else if steps.indices.contains(index - 1) {
            CookingStepPageView(
                step: steps[index - 1],
                number: index,
                count: steps.count,
                ingredients: ingredientsMentioned(in: steps[index - 1])
            )
        }
    }

    // MARK: Navigation bar

    private var previousButton: some View {
        Button {
            goToPage(page - 1)
        } label: {
            Label("Back", systemImage: MySymbols.previousStep)
        }
        .disabled(page == 0)
        .keyboardShortcut(.leftArrow, modifiers: [])
    }

    @ViewBuilder
    private var nextButton: some View {
        if page == finishPage {
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.glassProminent)
            .keyboardShortcut(.defaultAction)
        } else {
            Button {
                goToPage(page + 1)
            } label: {
                // Text and symbol: the title says what comes next ("Start cooking", "Finish").
                // Not a Label: the toolbar would show only its icon.
                HStack(spacing: Spacing.xSmall) {
                    Text(nextButtonTitle)
                    Image(systemName: MySymbols.nextStep)
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.glassProminent)
            .keyboardShortcut(.rightArrow, modifiers: [])
        }
    }

    private var pageIndicator: some View {
        Text(pageTitle)
            .font(.subheadline.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .contentTransition(.numericText())
            .animation(reduceMotion ? nil : .default, value: page)
    }
}

// MARK: - Mise en place

extension RecipeCookingView {
    private var allIngredientIDs: [String] {
        ingredientGroups.flatMap { $0.ingredients.map(\.id) }
    }

    private var readyCount: Int {
        allIngredientIDs.filter { readyIngredients.contains($0) }.count
    }

    private func readyBinding(_ id: String) -> Binding<Bool> {
        Binding {
            readyIngredients.contains(id)
        } set: { isReady in
            if isReady {
                readyIngredients.insert(id)
            } else {
                readyIngredients.remove(id)
            }
        }
    }

    private var miseEnPlacePage: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Label("Mise en place", systemImage: MySymbols.miseEnPlace)
                        .font(.title2.bold())
                    Text("Get all ingredients ready before you start cooking.")
                        .foregroundStyle(.secondary)
                    if recipe.desiredServings > 0 {
                        Label("Servings: \(recipe.desiredServings.formattedAmount)", systemImage: MySymbols.servings)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if !allIngredientIDs.isEmpty {
                        ProgressView(value: Double(readyCount), total: Double(allIngredientIDs.count)) {
                            Text("\(readyCount) of \(allIngredientIDs.count) ready")
                                .font(.subheadline)
                                .monospacedDigit()
                        }
                        .tint(Color(.GrocyColors.grocyGreen))
                        .padding(.top, Spacing.xxSmall)
                    }
                }
                .padding(.vertical, Spacing.xxSmall)
            }

            if ingredients.isEmpty {
                ContentUnavailableView("No ingredients", systemImage: MySymbols.miseEnPlace)
                    .listRowBackground(Color.clear)
            }

            ForEach(ingredientGroups, id: \.name) { group in
                Section {
                    ForEach(group.ingredients) { ingredient in
                        Toggle(isOn: readyBinding(ingredient.id)) {
                            MiseEnPlaceIngredientLabel(ingredient: ingredient, isReady: readyIngredients.contains(ingredient.id))
                        }
                        #if os(macOS)
                            .toggleStyle(.checkbox)
                        #else
                            .toggleStyle(.miseEnPlace)
                        #endif
                    }
                } header: {
                    if group.name.isEmpty {
                        Text("Ingredients")
                    } else {
                        Text(group.name)
                    }
                }
            }
        }
        #if os(macOS)
            .listStyle(.inset)
        #else
            .listStyle(.insetGrouped)
        #endif
        .frame(maxWidth: Sizes.cookingReadableWidth)
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.selection, trigger: readyIngredients)
    }

    // MARK: Ingredients of a step

    /// The ingredients a step mentions by name, matched at the start of a word (so "egg" also finds "eggs", but "Ei" not "weiter").
    private func ingredientsMentioned(in step: RecipePreparationStep) -> [CookingIngredient] {
        let text = [step.title, step.text].compactMap(\.self).joined(separator: " ")
        return ingredientGroups
            .flatMap(\.ingredients)
            .filter { ingredient in
                let name = ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return false }
                let pattern = "(?<![\\p{L}\\p{N}])" + NSRegularExpression.escapedPattern(for: name)
                return text.range(of: pattern, options: [.regularExpression, .caseInsensitive, .diacriticInsensitive]) != nil
            }
    }

    // MARK: Finish

    private var finishPageContent: some View {
        ScrollView(.vertical) {
            VStack(spacing: Spacing.large) {
                Image(systemName: MySymbols.cookingFinished)
                    .font(.system(.largeTitle))
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .symbolEffect(.bounce, value: isConsumed)
                    .accessibilityHidden(true)

                Text("Enjoy your meal!")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                if let errorMessage {
                    Label(errorMessage, systemImage: MySymbols.error)
                        .foregroundStyle(Color(.GrocyColors.grocyRed))
                }

                if isConsumed {
                    Label("The ingredients were consumed from your stock.", systemImage: MySymbols.success)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else if !ingredients.isEmpty {
                    Text("Consume the ingredients to take them out of your stock.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        showConsumeConfirmation = true
                    } label: {
                        Label("Consume all ingredients needed by this recipe", systemImage: MySymbols.consume)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(isProcessing)
                    if isProcessing {
                        ProgressView()
                    }
                }
            }
            .padding()
            .frame(maxWidth: Sizes.cookingReadableWidth)
            // The page's width, so the content is centered (a vertical scroll view doesn't stretch it).
            .containerRelativeFrame(.horizontal)
        }
        .defaultScrollAnchor(.center)
    }
}

// MARK: - Supporting types

/// An ingredient as cooking mode shows it.
struct CookingIngredient: Identifiable, Hashable {
    /// Recipe, position and product, so it stays the same across syncs.
    var id: String
    var name: String
    var amountText: String
    var note: String
}

private struct MiseEnPlaceIngredientLabel: View {
    var ingredient: CookingIngredient
    var isReady: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text("\(Text(ingredient.amountText).fontWeight(.semibold)) \(ingredient.name)")
                .strikethrough(isReady)
            if !ingredient.note.isEmpty {
                Text(ingredient.note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(isReady ? .secondary : .primary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if os(iOS)
    /// A checklist row like in Reminders: a circle that fills with a checkmark. The whole row toggles.
    /// macOS uses the system checkbox instead.
    struct MiseEnPlaceToggleStyle: ToggleStyle {
        func makeBody(configuration: Configuration) -> some View {
            Button {
                configuration.isOn.toggle()
            } label: {
                HStack(spacing: Spacing.medium) {
                    Image(systemName: configuration.isOn ? MySymbols.ingredientReady : MySymbols.ingredientNotReady)
                        .font(.title2)
                        .foregroundStyle(configuration.isOn ? Color(.GrocyColors.grocyGreen) : Color.secondary)
                        .contentTransition(.symbolEffect(.replace))
                        .accessibilityHidden(true)
                    configuration.label
                }
                .frame(minHeight: Sizes.minimumHitTarget)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }

    extension ToggleStyle where Self == MiseEnPlaceToggleStyle {
        static var miseEnPlace: MiseEnPlaceToggleStyle { MiseEnPlaceToggleStyle() }
    }
#endif

// MARK: - Preview

#Preview("Recipe with steps", traits: .previewData) {
    @Previewable @Query(filter: #Predicate<Recipe> { $0.id == 1 }) var recipes: Recipes
    if let recipe = recipes.first {
        RecipeCookingView(recipe: recipe)
            .onAppear {
                recipe.recipeDescription = RecipePreparationFormat.html(
                    introduction: "A quick weeknight dinner.",
                    steps: [
                        RecipePreparationStep(section: "Sauce", title: "Onions", text: "Finely chop the onions and fry them in a little oil until golden."),
                        RecipePreparationStep(section: "Sauce", title: nil, text: "Add the tomatoes, season with salt and pepper and let it simmer for 15 minutes."),
                        RecipePreparationStep(section: "Pasta", title: "Cook the pasta", text: "Cook the pasta in plenty of salted water until al dente.\nDrain and mix it with the sauce."),
                    ]
                )
            }
    }
}

#Preview("Without preparation", traits: .previewData) {
    RecipeCookingView(recipe: Recipe(name: "Recipe without steps"))
}
