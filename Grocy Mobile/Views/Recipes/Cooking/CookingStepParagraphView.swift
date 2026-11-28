//
//  CookingStepParagraphView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 28.11.26.
//

import SwiftUI

/// A paragraph of a cooking step, with the ingredients it mentions marked.
/// Hovering over an ingredient (Mac) or tapping it shows its amount.
struct CookingStepParagraphView: View {
    var paragraph: String
    var ingredients: [CookingIngredient] = []

    @State private var shownMarkID: String?

    var body: some View {
        styledText
            .font(.title2)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
            .backgroundPreferenceValue(Text.LayoutKey.self) { layouts in
                GeometryReader { proxy in
                    ForEach(marks(in: layouts, proxy: proxy)) { mark in
                        RoundedRectangle(cornerRadius: Sizes.ingredientMarkCornerRadius, style: .continuous)
                            .fill(.tint.opacity(shownMarkID == mark.id ? 0.25 : 0.12))
                            .frame(width: mark.rect.width, height: mark.rect.height)
                            .position(x: mark.rect.midX, y: mark.rect.midY)
                    }
                }
            }
            .overlayPreferenceValue(Text.LayoutKey.self) { layouts in
                GeometryReader { proxy in
                    ForEach(marks(in: layouts, proxy: proxy)) { mark in
                        markTarget(mark)
                    }
                }
                // The amounts are in the ingredient list below, which VoiceOver reads.
                .accessibilityHidden(true)
            }
            .animation(.easeOut(duration: 0.15), value: shownMarkID)
    }

    // MARK: Text

    private var segments: [Segment] {
        var found: [(range: Range<String.Index>, ingredient: CookingIngredient)] = []
        // Longer names first, so "red onion" wins over "onion".
        for ingredient in ingredients.sorted(by: { $0.name.count > $1.name.count }) {
            guard let pattern = ingredient.mentionPattern else { continue }
            var searchStart = paragraph.startIndex
            while searchStart < paragraph.endIndex,
                let range = paragraph.range(of: pattern, options: CookingIngredient.mentionOptions, range: searchStart..<paragraph.endIndex),
                !range.isEmpty
            {
                if !found.contains(where: { $0.range.overlaps(range) }) {
                    found.append((range, ingredient))
                }
                searchStart = range.upperBound
            }
        }
        found.sort { $0.range.lowerBound < $1.range.lowerBound }

        var result: [Segment] = []
        var position = paragraph.startIndex
        for (index, match) in found.enumerated() {
            if position < match.range.lowerBound {
                result.append(Segment(text: String(paragraph[position..<match.range.lowerBound]), mark: nil))
            }
            result.append(
                Segment(
                    text: String(paragraph[match.range]),
                    mark: IngredientMarkAttribute(id: "\(index)-\(match.ingredient.id)", ingredient: match.ingredient)
                )
            )
            position = match.range.upperBound
        }
        if position < paragraph.endIndex {
            result.append(Segment(text: String(paragraph[position...]), mark: nil))
        }
        return result
    }

    private var styledText: Text {
        segments.reduce(Text(verbatim: "")) { text, segment in
            let part: Text
            if let mark = segment.mark {
                part = Text(verbatim: segment.text)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tint)
                    .customAttribute(mark)
            } else {
                part = Text(verbatim: segment.text)
            }
            return Text("\(text)\(part)")
        }
    }

    // MARK: Marks

    private func marks(in layouts: Text.LayoutKey.Value, proxy: GeometryProxy) -> [MarkFrame] {
        var frames: [MarkFrame] = []
        for anchoredLayout in layouts {
            let origin = proxy[anchoredLayout.origin]
            for line in anchoredLayout.layout {
                for run in line {
                    guard let mark = run[IngredientMarkAttribute.self] else { continue }
                    let bounds = run.typographicBounds.rect
                        .offsetBy(dx: origin.x, dy: origin.y)
                        .insetBy(dx: -Spacing.hairline, dy: -Spacing.hairline)
                    // A name broken over two lines has a run on each line.
                    let id = frames.contains(where: { $0.mark.id == mark.id }) ? "\(mark.id)-\(frames.count)" : mark.id
                    frames.append(MarkFrame(id: id, mark: mark, rect: bounds))
                }
            }
        }
        return frames
    }

    private func markTarget(_ frame: MarkFrame) -> some View {
        Color.clear
            .contentShape(.rect(cornerRadius: Sizes.ingredientMarkCornerRadius))
            .frame(width: frame.rect.width, height: frame.rect.height)
            #if os(macOS)
                .onHover { isHovering in
                    if isHovering {
                        shownMarkID = frame.id
                    } else if shownMarkID == frame.id {
                        shownMarkID = nil
                    }
                }
                .pointerStyle(.link)
            #endif
            .onTapGesture {
                shownMarkID = shownMarkID == frame.id ? nil : frame.id
            }
            .popover(
                isPresented: Binding(
                    get: { shownMarkID == frame.id },
                    set: { isShown in
                        if !isShown, shownMarkID == frame.id { shownMarkID = nil }
                    }
                ),
                arrowEdge: .bottom
            ) {
                IngredientAmountPopover(ingredient: frame.mark.ingredient)
                    .presentationCompactAdaptation(.popover)
            }
            // After the popover, so it points at the name and not at the paragraph.
            .position(x: frame.rect.midX, y: frame.rect.midY)
    }
}

// MARK: - Supporting types

private struct Segment {
    var text: String
    var mark: IngredientMarkAttribute?
}

/// Marks an ingredient's name in the text, so its frame can be found in the text layout.
private struct IngredientMarkAttribute: TextAttribute {
    var id: String
    var ingredient: CookingIngredient
}

private struct MarkFrame: Identifiable {
    var id: String
    var mark: IngredientMarkAttribute
    var rect: CGRect
}

private struct IngredientAmountPopover: View {
    var ingredient: CookingIngredient

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text(ingredient.amountText)
                .font(.title3.weight(.semibold))
            Text(ingredient.name)
                .font(.body)
            if !ingredient.note.isEmpty {
                Text(ingredient.note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .fixedSize()
    }
}

#Preview {
    CookingStepParagraphView(
        paragraph: "Finely chop the onions and fry them in a little oil. Add the garlic and the rest of the onion.",
        ingredients: [
            CookingIngredient(id: "1", name: "Onion", amountText: "2 pieces", note: "red"),
            CookingIngredient(id: "2", name: "Garlic", amountText: "1 clove", note: ""),
        ]
    )
    .padding()
}
