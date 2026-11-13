//
//  FieldDescription.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 06.01.21.
//

import SwiftUI

struct FieldDescription: View {
    var description: LocalizedStringKey

    @State private var showDescription: Bool = false

    var body: some View {
        Button {
            showDescription.toggle()
        } label: {
            Image(systemName: MySymbols.hint)
                .foregroundStyle(.secondary)
        }
        // Borderless, so tapping the button doesn't trigger the whole Form row (e.g. a Toggle).
        .buttonStyle(.borderless)
        // The glyph is smaller than the HIG minimum hit region (44x44 pt on iOS, 20x20 pt on macOS).
        // Enlarge only the clickable area; the negative padding keeps the row layout unchanged.
        #if os(iOS)
            .padding(10)
            .contentShape(Rectangle())
            .padding(-10)
        #else
            .padding(4)
            .contentShape(Rectangle())
            .padding(-4)
        #endif
        .help(description)
        .accessibilityLabel(Text("Details"))
        .accessibilityHint(Text(description))
        .popover(isPresented: $showDescription) {
            #if os(iOS)
                // No ScrollView: it has no ideal height, so the fitted popover would cut the text off.
                // The width must stay below the narrowest iPhone width; otherwise the height is measured
                // for a wider popover than the one shown, and the last line gets clipped.
                Text(description)
                    .padding()
                    .frame(width: 300)
                    .fixedSize(horizontal: false, vertical: true)
                    .presentationCompactAdaptation(.popover)
                    .presentationSizing(.fitted)
            #else
                Text(description)
                    .padding()
                    .frame(maxWidth: 400)
                    .fixedSize(horizontal: false, vertical: true)
            #endif
        }
    }
}

#Preview {
    NavigationStack {
        FieldDescription(description: "Description")
    }
}
