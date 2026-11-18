//
//  CookingStepPageView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import SwiftUI

/// One preparation step of the cooking mode, in a large text size to read it from a distance,
/// with the ingredients the step mentions.
struct CookingStepPageView: View {
    var step: RecipePreparationStep
    /// The step's number, starting at 1.
    var number: Int
    var count: Int
    var ingredients: [CookingIngredient] = []

    private var paragraphs: [String] {
        step.text.components(separatedBy: "\n").filter { !$0.isEmpty }
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: Spacing.large) {
                // The step number is in the bottom bar; VoiceOver reads it with the header.
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    if let section = step.section, !section.isEmpty {
                        Text(section)
                            .font(.headline)
                            .foregroundStyle(.tint)
                    }
                    if let title = step.title, !title.isEmpty {
                        Text(title)
                            .font(.largeTitle.bold())
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text("Step \(number) of \(count)"))
                .accessibilityValue(Text([step.section, step.title].compactMap(\.self).joined(separator: ", ")))
                .accessibilityAddTraits(.isHeader)

                ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .font(.title2)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }

                if !ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Ingredients")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(ingredients) { ingredient in
                            Text("\(Text(ingredient.amountText).fontWeight(.semibold)) \(ingredient.name)")
                                .font(.body)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.fill.quaternary, in: .rect(cornerRadius: Sizes.recipeThumbnailCornerRadius, style: .continuous))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxWidth: Sizes.cookingReadableWidth)
            // The page's width, so short steps don't shrink and the text is centered on wide screens.
            .containerRelativeFrame(.horizontal)
        }
    }
}

#Preview {
    CookingStepPageView(
        step: RecipePreparationStep(section: "Sauce", title: "Onions", text: "Finely chop the onions and fry them in a little oil until golden.\nThen add the garlic."),
        number: 1,
        count: 3,
        ingredients: [CookingIngredient(id: "1", name: "Onions", amountText: "2 pieces", note: "")]
    )
}
