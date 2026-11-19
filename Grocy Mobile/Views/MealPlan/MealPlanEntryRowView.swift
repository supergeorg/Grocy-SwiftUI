//
//  MealPlanEntryRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import SwiftData
import SwiftUI

/// A meal plan entry: what's planned, its amount or servings, whether it's in stock and what it costs.
/// As a list row (`compact` false) or as a card of the week grid (`compact` true).
struct MealPlanEntryRowView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.locale) private var locale

    let entry: MealPlanEntry
    let lookup: MealPlanLookup
    /// The list shows the section in the row; the week grid has a row per section.
    var showsSection: Bool = true
    var compact: Bool = false

    @ScaledMetric(relativeTo: .body) private var thumbnailSize: CGFloat = Sizes.mealPlanThumbnail

    private var title: String {
        switch entry.type {
        case .recipe: lookup.recipe(of: entry)?.name ?? String(localized: "Unknown recipe")
        case .product: lookup.product(of: entry)?.name ?? String(localized: "Unknown product")
        case .note: entry.note
        }
    }

    private var pictureFileName: String? {
        switch entry.type {
        case .recipe: lookup.recipe(of: entry)?.pictureFileName
        case .product: lookup.product(of: entry)?.pictureFileName
        case .note: nil
        }
    }

    private var sectionName: String? {
        guard showsSection, let section = lookup.section(of: entry), !section.isNoSection, !section.name.isEmpty else { return nil }
        return section.timeInfo.isEmpty ? section.name : "\(section.name) · \(section.timeInfo)"
    }

    var body: some View {
        if compact {
            card
        } else {
            row
        }
    }

    // MARK: - Layouts

    private var row: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            thumbnail
                .frame(width: thumbnailSize, height: thumbnailSize)
                .clipShape(.rect(cornerRadius: Sizes.recipeThumbnailCornerRadius))
            VStack(alignment: .leading, spacing: Spacing.hairline) {
                if let sectionName {
                    Text(sectionName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                titleText
                    .font(.body)
                details
                    .font(.subheadline)
            }
            Spacer(minLength: 0)
            if entry.done {
                doneSymbol
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            if let pictureFileName, !pictureFileName.isEmpty {
                thumbnail
                    .aspectRatio(Sizes.recipeCardPictureRatio, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: Sizes.recipeThumbnailCornerRadius))
            }
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xxSmall) {
                if entry.type == .note {
                    Image(systemName: MySymbols.mealPlanNote)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                titleText
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(3)
                Spacer(minLength: 0)
                if entry.done {
                    doneSymbol
                        .font(.caption)
                }
            }
            details
                .font(.caption)
        }
        .padding(Spacing.small)
        // The grid may propose less height than the text needs; wrap instead of truncating.
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Content, not navigation: a plain fill, no glass.
        .background(.background.secondary, in: .rect(cornerRadius: Sizes.mealPlanCardCornerRadius))
        .contentShape(.rect(cornerRadius: Sizes.mealPlanCardCornerRadius))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Parts

    private var titleText: some View {
        Text(title)
            .strikethrough(entry.done)
            .foregroundStyle(entry.done ? .secondary : .primary)
            .multilineTextAlignment(.leading)
    }

    private var doneSymbol: some View {
        Image(systemName: MySymbols.fulfilled)
            .foregroundStyle(Color(.GrocyColors.grocyGreen))
            .accessibilityLabel("Done")
    }

    @ViewBuilder
    private var thumbnail: some View {
        switch entry.type {
        case .recipe:
            RecipeThumbnailView(pictureFileName: pictureFileName)
        case .product:
            Rectangle()
                .fill(.quaternary)
                .overlay {
                    if let pictureFileName, !pictureFileName.isEmpty {
                        PictureView(pictureFileName: pictureFileName, pictureType: .productPictures)
                            .scaledToFill()
                    } else {
                        Image(systemName: MySymbols.product)
                            .foregroundStyle(.secondary)
                    }
                }
                .clipped()
                .accessibilityHidden(true)
        case .note:
            Rectangle()
                .fill(.quaternary)
                .overlay {
                    Image(systemName: MySymbols.mealPlanNote)
                        .foregroundStyle(.secondary)
                }
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var details: some View {
        switch entry.type {
        case .recipe:
            VStack(alignment: .leading, spacing: Spacing.hairline) {
                Text("^[\(entry.recipeServings, format: .number) serving](inflect: true)")
                    .foregroundStyle(.secondary)
                if lookup.showsStock {
                    RecipeFulfilmentLabel(fulfillment: lookup.fulfillment(of: entry), compact: true)
                }
                if let costsAndCalories = recipeCostsAndCalories {
                    Text(costsAndCalories)
                        .foregroundStyle(.secondary)
                }
            }
        case .product:
            VStack(alignment: .leading, spacing: Spacing.hairline) {
                Text(productAmount)
                    .foregroundStyle(.secondary)
                if lookup.showsStock, lookup.product(of: entry) != nil {
                    stockLabel
                }
            }
        case .note:
            EmptyView()
        }
    }

    private var productAmount: String {
        let amount = entry.productAmount.formattedAmount
        guard let quantityUnit = lookup.quantityUnit(of: entry) else { return amount }
        return "\(amount) \(quantityUnit.getName(amount: entry.productAmount))"
    }

    private var stockLabel: some View {
        let inStock = lookup.isInStock(entry)
        // An HStack instead of a Label, like `RecipeFulfilmentLabel`, so it lines up with the recipes' label.
        return HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall) {
            Image(systemName: inStock ? MySymbols.fulfilled : MySymbols.notFulfilled)
                .foregroundStyle(Color(inStock ? .GrocyColors.grocyGreen : .GrocyColors.grocyRed))
                .accessibilityHidden(true)
            Text(inStock ? "Enough in stock" : "Not enough in stock")
                .foregroundStyle(.secondary)
        }
    }

    /// The entry's costs and its calories per serving, as the Grocy web app shows them.
    private var recipeCostsAndCalories: String? {
        guard let fulfillment = lookup.fulfillment(of: entry) else { return nil }
        var parts: [String] = []
        if lookup.showsCosts, let costs = fulfillment.costs, costs > 0 {
            parts.append(grocyVM.getFormattedCurrency(amount: costs))
        }
        if let calories = fulfillment.calories, calories > 0, entry.recipeServings > 0 {
            let perServing = (calories / entry.recipeServings).formatted(.number.precision(.fractionLength(0)).locale(locale))
            parts.append(String(localized: "\(perServing) \(lookup.energyUnit) per serving"))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

#Preview(traits: .previewData) {
    @Previewable @Environment(\.modelContext) var modelContext
    let lookup = MealPlanLookup(
        recipes: (try? modelContext.fetch(FetchDescriptor<Recipe>())) ?? [],
        fulfillments: (try? modelContext.fetch(FetchDescriptor<RecipeFulfilment>())) ?? [],
        products: (try? modelContext.fetch(FetchDescriptor<MDProduct>())) ?? [],
        quantityUnits: (try? modelContext.fetch(FetchDescriptor<MDQuantityUnit>())) ?? [],
        stock: (try? modelContext.fetch(FetchDescriptor<StockElement>())) ?? [],
        sections: (try? modelContext.fetch(FetchDescriptor<MDMealPlanSection>())) ?? [],
        systemConfig: nil
    )
    let entries = (try? modelContext.fetch(FetchDescriptor<MealPlanEntry>(sortBy: [SortDescriptor(\.id)]))) ?? []
    List {
        ForEach(entries) { entry in
            MealPlanEntryRowView(entry: entry, lookup: lookup)
        }
    }
}
