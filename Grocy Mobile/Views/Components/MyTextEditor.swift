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

    // In a Form, the TextEditor only gets the label's height: on macOS an empty one collapses to a sliver of a line,
    // and on iOS its text sits below the inset and gets clipped. Keep room for a few lines, scaled with the text size.
    @ScaledMetric(relativeTo: .body) private var minEditorHeight: CGFloat = 54

    var body: some View {
        LabeledContent(
            content: {
                TextEditor(text: $textToEdit)
                    // In a Form row, the content column is trailing-aligned on macOS; text reads from the leading edge.
                    .multilineTextAlignment(.leading)
                    .accessibilityLabel(Text(description))
                    .frame(minHeight: minEditorHeight)
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
