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
    /// Starts a timer for a time the step mentions.
    var onStartTimer: (CookingDuration) -> Void = { _ in }

    @Environment(\.locale) private var locale

    private var paragraphs: [String] {
        step.text.components(separatedBy: "\n").filter { !$0.isEmpty }
    }

    /// The times the step mentions, each once.
    private var durations: [CookingDuration] {
        var seen: Set<TimeInterval> = []
        return CookingDurationParser.durations(in: step.text).filter { seen.insert($0.seconds).inserted }
    }

    private func durationText(_ duration: CookingDuration) -> String {
        let format = Duration.UnitsFormatStyle(allowedUnits: [.hours, .minutes, .seconds], width: .abbreviated).locale(locale)
        let lower = Duration.seconds(duration.seconds).formatted(format)
        guard let upperSeconds = duration.upperSeconds else { return lower }
        return "\(lower) – \(Duration.seconds(upperSeconds).formatted(format))"
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
                    CookingStepParagraphView(paragraph: paragraph, ingredients: ingredients, onStartTimer: onStartTimer)
                }

                if !durations.isEmpty {
                    FlowLayout(spacing: Spacing.small) {
                        ForEach(durations, id: \.self) { duration in
                            Button {
                                onStartTimer(duration)
                            } label: {
                                Label(durationText(duration), systemImage: MySymbols.timer)
                                    .font(.headline)
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            .controlSize(.large)
                            .accessibilityLabel(Text("Start a timer for \(durationText(duration))"))
                            .macHelp(Text("Start a timer for \(durationText(duration))"))
                        }
                    }
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
        step: RecipePreparationStep(
            section: "Sauce",
            title: "Onions",
            text:
                "Finely chop the onions and fry them in a little oil for 5 to 7 minutes until golden.\nThen add the garlic and the chopped onion and cook for 1 hour 30 minutes."
        ),
        number: 1,
        count: 3,
        ingredients: [
            CookingIngredient(id: "1", name: "Onion", amountText: "2 pieces", note: "red"),
            CookingIngredient(id: "2", name: "Garlic", amountText: "1 clove", note: ""),
        ]
    )
}
