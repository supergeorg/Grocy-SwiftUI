//
//  MyTextEditor.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.09.23.
//

import SwiftUI

struct MyTextEditor: View {
    @Binding var textToEdit: String
    var description: LocalizedStringKey
    var leadingIcon: String?

    #if os(macOS)
        // In a macOS Form, an empty TextEditor collapses to a sliver of a line. Keep room for about three lines,
        // scaled with the text size.
        @ScaledMetric(relativeTo: .body) private var minEditorHeight: CGFloat = 54
    #endif

    var body: some View {
        LabeledContent(
            content: {
                TextEditor(text: $textToEdit)
                    // In a Form row, the content column is trailing-aligned on macOS; text reads from the leading edge.
                    .multilineTextAlignment(.leading)
                    .accessibilityLabel(Text(description))
                    #if os(macOS)
                        .frame(minHeight: minEditorHeight)
                    #endif
            },
            label: {
                if let leadingIcon = leadingIcon {
                    Label(description, systemImage: leadingIcon)
                        .foregroundStyle(.primary)
                } else {
                    Text(description)
                }
            }
        )

    }
}

#Preview {
    @Previewable @State var text: String = "TEST"

    Form {
        MyTextEditor(textToEdit: $text, description: "DESCRIPTION")
    }
}
