//
//  MyTextField.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 28.10.20.
//

import SwiftUI

struct MyTextField: View {
    @Binding var textToEdit: String
    var description: LocalizedStringKey
    var subtitle: LocalizedStringKey?
    var prompt: String = ""
    @Binding var isCorrect: Bool
    @FocusState private var isFocused: Bool
    var leadingIcon: String?
    var emptyMessage: LocalizedStringKey?
    var errorMessage: LocalizedStringKey?
    var helpText: LocalizedStringKey?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Becomes true on the first edit, so a new, still empty form doesn't greet people with an error.
    @State private var hasEdited: Bool = false

    var body: some View {
        LabeledContent {
            VStack(alignment: .leading) {
                // Disabled styling and field appearance come from the system.
                // The description is the field's (hidden) label, so VoiceOver names the field, and the prompt
                // stays a placeholder. Otherwise macOS shows the title as a second visible label in the Form row.
                TextField(text: $textToEdit, prompt: Text(LocalizedStringKey(prompt))) {
                    Text(description)
                }
                .labelsHidden()
                #if os(iOS)
                    // On iOS, hiding the label also removes it from accessibility.
                    // (macOS keeps it; an extra label there would be read twice: "Name, Name".)
                    .accessibilityLabel(Text(description))
                #endif
                .onChange(of: textToEdit) {
                        hasEdited = true
                    }

                if !isCorrect && !textToEdit.isEmpty, let errorMessage = errorMessage {
                    validationMessage(errorMessage)
                }
                if textToEdit.isEmpty && hasEdited, let emptyMessage = emptyMessage {
                    validationMessage(emptyMessage)
                }
            }
        } label: {
            if let leadingIcon = leadingIcon {
                Label {
                    labelText
                } icon: {
                    Image(systemName: leadingIcon)
                        .foregroundStyle(.primary)
                }
            } else {
                labelText
            }
            if let subtitle = subtitle {
                Text(subtitle)
                    .lineLimit(nil)
            }
        }
    }

    /// The description with its help button. Only the text is styled as primary, so the help button keeps
    /// the tint like in `MyToggle`.
    private var labelText: some View {
        HStack {
            if dynamicTypeSize.isAccessibilitySize {
                // The row places the label above the field, so it has the whole width and may wrap.
                Text(description)
                    .foregroundStyle(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                // Keeps its whole width: the form row then places the label above the field when both don't fit
                // next to each other, instead of squeezing the label into a column where it wraps and gets clipped.
                Text(description)
                    .foregroundStyle(.primary)
                    .fixedSize()
            }
            if let helpText = helpText {
                FieldDescription(description: helpText)
                    .fixedSize()
            }
        }
    }

    private func validationMessage(_ message: LocalizedStringKey) -> some View {
        Text(message)
            .lineLimit(nil)
            .font(.caption)
            // Asset color with enough contrast for small text on the grouped row background.
            .foregroundStyle(Color(.GrocyColors.grocyRed))
    }
}

#Preview {
    @Previewable @State var textToEdit: String = "Text to Edit"
    @Previewable @State var isCorrect: Bool = true

    Form {
        MyTextField(
            textToEdit: $textToEdit,
            description: "Description",
            subtitle: "Optional subtitle",
            isCorrect: $isCorrect,
            leadingIcon: "tag",
            errorMessage: "Error message",
            helpText: "This is a help text"
        )
        .onChange(
            of: textToEdit,
            {
                if textToEdit == "Error" { isCorrect = false } else { isCorrect = true }
            }
        )
    }
}
