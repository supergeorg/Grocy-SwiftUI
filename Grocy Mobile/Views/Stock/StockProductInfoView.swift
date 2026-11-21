//
//  ProductOverviewView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 30.11.20.
//

import SwiftData
import SwiftUI

/// The product overview, like Grocy's product card: the product, its stock, prices and statistics,
/// with links to its stock entries, stock journal and recipes, and the stock actions in the toolbar.
struct StockProductInfoView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.dismiss) var dismiss
    @Environment(\.grocyFeatures) private var features

    @Query var detailsList: [StockProductDetails]
    var productDetails: StockProductDetails? {
        detailsList.first
    }
    @Query var productList: [MDProduct]
    var product: MDProduct? {
        productList.first ?? stockElement.product
    }
    @Query var productGroups: MDProductGroups
    private var productGroup: MDProductGroup? {
        guard let productGroupID = product?.productGroupID else { return nil }
        return productGroups.first(where: { $0.id == productGroupID })
    }

    @AppStorage("localizationKey") var localizationKey: String = "en"

    var stockElement: StockElement
    var isPopup: Bool = false

    /// Fetched on demand, like Grocy's product card; `nil` while loading, when it failed, or with price tracking turned off.
    @State private var priceHistory: ProductPriceHistories?
    @State private var isLoadingDetails: Bool = true
    @State private var isDescriptionExpanded: Bool = false
    /// The description as plain text; Grocy's web app stores it as HTML.
    @State private var descriptionText: String = ""
    /// A stock action or the product form, shown in a sheet above the overview.
    @State private var presentedInteraction: StockInteraction?

    init(stockElement: StockElement, isPopup: Bool = false) {
        self.stockElement = stockElement
        self.isPopup = isPopup
        let productID = stockElement.productID
        _detailsList = Query(filter: #Predicate<StockProductDetails> { $0.productID == productID })
        _productList = Query(filter: #Predicate<MDProduct> { $0.id == productID })
    }

    private var isPriceTrackingEnabled: Bool {
        grocyVM.systemConfig?.featureFlagStockPriceTracking ?? true
    }

    private var isShoppingListEnabled: Bool {
        grocyVM.systemConfig?.featureFlagShoppinglist ?? true
    }

    private func loadDetails() async {
        isLoadingDetails = true
        await grocyVM.requestStockInfo(stockModeGet: .details, productID: stockElement.productID)
        isLoadingDetails = false
    }

    private func loadPriceHistory() async {
        guard isPriceTrackingEnabled else {
            priceHistory = nil
            return
        }
        do {
            priceHistory = try await grocyVM.getProductPriceHistory(productID: stockElement.productID)
        } catch {
            GrocyLogger.error("Loading the price history failed. \(error)")
        }
    }

    private func loadDescription() async {
        let description = product?.mdProductDescription ?? ""
        if description.contains("<") {
            let attributed = await description.htmlToAttributedStringAsync()
            descriptionText = String(attributed.characters).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            descriptionText = description.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func reload() async {
        await loadDetails()
        await loadPriceHistory()
    }

    private func amountText(_ amount: Double, quantityUnit: MDQuantityUnit?) -> String {
        "\(amount.formattedAmount) \(quantityUnit?.getName(amount: amount) ?? "")"
    }

    private func priceText(_ price: Double?, quantityUnit: MDQuantityUnit?) -> LocalizedStringKey {
        guard let price else { return "Unknown" }
        return "\(grocyVM.getFormattedCurrency(amount: price)) per \(quantityUnit?.name ?? "")"
    }

    var body: some View {
        Form {
            headerSection
            if let productDetails {
                stockSection(productDetails)
                linksSection
                purchasesSection(productDetails)
                statisticsSection(productDetails)
                if isPriceTrackingEnabled, let priceHistory {
                    if priceHistory.isEmpty {
                        Section {
                            Text("No price history available")
                                .foregroundStyle(.secondary)
                        } header: {
                            Label("Price history", systemImage: MySymbols.priceHistory)
                        }
                    } else {
                        StockProductPriceHistoryView(priceHistory: priceHistory, quantityUnitName: productDetails.quantityUnitStock?.name)
                    }
                }
            } else if isLoadingDetails {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            } else {
                Section {
                    Text("Retrieving Details failed.")
                        .foregroundStyle(.secondary)
                }
                linksSection
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Product overview")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await reload()
        }
        .task(id: product?.mdProductDescription) {
            await loadDescription()
        }
        .refreshable {
            await reload()
        }
        .navigationDestination(for: ProductOverviewDestination.self) { destination in
            switch destination {
            case .stockEntries: StockEntriesView(stockElement: stockElement)
            case .stockJournal: StockJournalView(stockElement: stockElement)
            case .recipes: StockProductRecipesView(stockElement: stockElement)
            }
        }
        .sheet(
            item: $presentedInteraction,
            onDismiss: {
                Task { await reload() }
            },
            content: { interaction in
                NavigationStack {
                    StockInteractionView(interaction: interaction)
                }
            }
        )
        .toolbar {
            if isPopup {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            if stockElement.product != nil || product != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button(
                        action: { presentedInteraction = .editProduct(stockElement: stockElement) },
                        label: { Label("Edit product", systemImage: MySymbols.edit) }
                    )
                }
            }
            #if os(iOS)
                ToolbarItemGroup(placement: .bottomBar) {
                    stockActionButtons
                }
                ToolbarSpacer(.flexible, placement: .bottomBar)
                if isShoppingListEnabled {
                    ToolbarItem(placement: .bottomBar) {
                        addToShoppingListButton
                    }
                }
            #else
                ToolbarItemGroup(placement: .automatic) {
                    stockActionButtons
                    if isShoppingListEnabled {
                        addToShoppingListButton
                    }
                }
            #endif
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section("Product") {
            if let pictureFileName = product?.pictureFileName, !pictureFileName.isEmpty {
                PictureView(pictureFileName: pictureFileName, pictureType: .productPictures)
                    .frame(maxWidth: .infinity, maxHeight: Sizes.picturePreview)
                    .clipShape(.rect(cornerRadius: Sizes.recipeThumbnailCornerRadius))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(product?.name ?? "")
                    .font(.title2)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                if let productGroup {
                    Label(productGroup.name, systemImage: MySymbols.productGroup)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            if !descriptionText.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text(descriptionText)
                        .foregroundStyle(.secondary)
                        .lineLimit(isDescriptionExpanded ? nil : 3)
                    Button(isDescriptionExpanded ? "Show less" : "Show more") {
                        withAnimation {
                            isDescriptionExpanded.toggle()
                        }
                    }
                    .buttonStyle(.borderless)
                    .font(.subheadline)
                }
            }
        }
    }

    private func stockSection(_ productDetails: StockProductDetails) -> some View {
        Section("Stock") {
            LabeledContent {
                VStack(alignment: .trailing) {
                    Text(amountText(productDetails.stockAmount, quantityUnit: productDetails.quantityUnitStock))
                    if features.openedTracking, let opened = productDetails.stockAmountOpened, opened > 0 {
                        Text("\(opened.formattedAmount) opened")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } label: {
                Label("Stock amount", systemImage: MySymbols.amount)
                    .foregroundStyle(.primary)
            }
            if productDetails.hasChilds, let aggregated = productDetails.stockAmountAggregated {
                LabeledContent {
                    VStack(alignment: .trailing) {
                        Text(amountText(aggregated, quantityUnit: productDetails.quantityUnitStock))
                        if features.openedTracking, let opened = productDetails.stockAmountOpenedAggregated, opened > 0 {
                            Text("\(opened.formattedAmount) opened")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } label: {
                    Label("Including sub products", systemImage: MySymbols.parentProduct)
                        .foregroundStyle(.primary)
                }
            }
            if isPriceTrackingEnabled {
                LabeledContent {
                    Text(grocyVM.getFormattedCurrency(amount: productDetails.stockValue ?? 0.0))
                } label: {
                    Label("Stock value", systemImage: MySymbols.price)
                        .foregroundStyle(.primary)
                }
            }
            if features.locationTracking {
                LabeledContent {
                    Text(productDetails.location?.name ?? "")
                } label: {
                    Label("Default location", systemImage: MySymbols.location)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    /// Grocy's product card links to the stock entries and the stock journal; the app also lists the recipes.
    private var linksSection: some View {
        Section("Details") {
            NavigationLink(value: ProductOverviewDestination.stockEntries) {
                Label("Stock entries", systemImage: MySymbols.stockEntries)
                    // A link in a form is tinted like a button; the other rows use the primary color.
                    .foregroundStyle(.primary)
            }
            NavigationLink(value: ProductOverviewDestination.stockJournal) {
                Label("Stock journal", systemImage: MySymbols.stockJournal)
                    .foregroundStyle(.primary)
            }
            if features.recipes {
                NavigationLink(value: ProductOverviewDestination.recipes) {
                    Label("Recipes", systemImage: MySymbols.recipe)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private func purchasesSection(_ productDetails: StockProductDetails) -> some View {
        Section("History") {
            dateRow("Last purchased", date: productDetails.lastPurchased)
            dateRow("Last used", date: productDetails.lastUsed)
            if isPriceTrackingEnabled {
                LabeledContent {
                    Text(priceText(productDetails.lastPrice, quantityUnit: productDetails.quantityUnitStock))
                } label: {
                    Label("Last price", systemImage: MySymbols.price)
                        .foregroundStyle(.primary)
                }
                LabeledContent {
                    Text(priceText(productDetails.avgPrice, quantityUnit: productDetails.quantityUnitStock))
                } label: {
                    Label("Average price", systemImage: MySymbols.price)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private func statisticsSection(_ productDetails: StockProductDetails) -> some View {
        Section("Statistics") {
            if features.dueDateTracking {
                LabeledContent {
                    Text(
                        (productDetails.averageShelfLifeDays ?? 0) > 0
                            ? LocalizedStringKey(formatDays(daysToFormat: productDetails.averageShelfLifeDays) ?? "Unknown") : "Unknown"
                    )
                } label: {
                    Label("Average shelf life", systemImage: MySymbols.date)
                        .foregroundStyle(.primary)
                }
            }
            LabeledContent {
                Text("\(productDetails.spoilRatePercent.formattedAmount) %")
            } label: {
                Label("Spoil rate", systemImage: MySymbols.spoiled)
                    .foregroundStyle(.primary)
            }
        }
    }

    private func dateRow(_ title: LocalizedStringKey, date: Date?) -> some View {
        LabeledContent {
            VStack(alignment: .trailing) {
                Text(LocalizedStringKey(formatDateAsString(date, localizationKey: localizationKey) ?? "Never"))
                if let relative = getRelativeDateAsText(date, localizationKey: localizationKey) {
                    Text(relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            Label(title, systemImage: MySymbols.date)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var stockActionButtons: some View {
        Button(
            action: { presentedInteraction = .productPurchase(stockElement: stockElement) },
            label: { Label("Purchase", systemImage: MySymbols.purchase) }
        )
        Button(
            action: { presentedInteraction = .productConsume(stockElement: stockElement) },
            label: { Label("Consume", systemImage: MySymbols.consume) }
        )
        if features.locationTracking {
            Button(
                action: { presentedInteraction = .productTransfer(stockElement: stockElement) },
                label: { Label("Transfer", systemImage: MySymbols.transfer) }
            )
        }
        Button(
            action: { presentedInteraction = .productInventory(stockElement: stockElement) },
            label: { Label("Inventory", systemImage: MySymbols.inventory) }
        )
    }

    private var addToShoppingListButton: some View {
        Button(
            action: { presentedInteraction = .addToShL(stockElement: stockElement) },
            label: { Label("Add to shopping list", systemImage: MySymbols.addToShoppingList) }
        )
    }
}

/// The screens the product overview links to, pushed in its navigation stack.
private enum ProductOverviewDestination: Hashable {
    case stockEntries, stockJournal, recipes
}

#Preview(traits: .previewData) {
    let container = PreviewContainer.shared
    let context = ModelContext(container)

    // Fetch one object from the preview store
    let descriptor = FetchDescriptor<StockElement>(sortBy: [SortDescriptor(\.productID)])
    let stockElement = (try? context.fetch(descriptor).first)

    if let stockElement {
        NavigationStack {
            StockProductInfoView(stockElement: stockElement, isPopup: true)
        }
    } else {
        EmptyView()
    }
}
