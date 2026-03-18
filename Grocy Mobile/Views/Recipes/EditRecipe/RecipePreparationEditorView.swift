//
//  RecipePreparationEditorView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 07.03.26.
//

internal import Combine
import InfomaniakRichHTMLEditor
import SwiftUI
import UIKit

struct RecipePreparationEditorView: View {
    @Binding var htmlContent: String
    @State private var temporaryHTML: String = ""
    @State private var selectedTab: TabSelection = .wysiwygEditor
    @Environment(\.dismiss) var dismiss

    enum TabSelection {
        case rawEditor
        case wysiwygEditor
        case preview
    }

    init(htmlContent: Binding<String>) {
        self._htmlContent = htmlContent
        self._temporaryHTML = State(initialValue: htmlContent.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                WYSIWYGEditorView(htmlContent: $temporaryHTML)
                    .tag(TabSelection.wysiwygEditor)
                    .tabItem {
                        Label("WYSIWYG", systemImage: "doc.richtext")
                    }

                RawEditorView(htmlContent: $temporaryHTML)
                    .tag(TabSelection.rawEditor)
                    .tabItem {
                        Label("Raw HTML", systemImage: "chevron.left.slash.chevron.right")
                    }

                PreviewTabView(convertedHTML: $temporaryHTML)
                    .tag(TabSelection.preview)
                    .tabItem {
                        Label("Preview", systemImage: "eye")
                    }
            }
            .navigationTitle("Recipe Preparation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", role: .confirm) {
                        htmlContent = temporaryHTML
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Text View Coordinator for Selection Access
class TextViewCoordinator: NSObject, UITextViewDelegate, ObservableObject {
    weak var textView: UITextView?
    @Published var isEditing = false

    func textViewDidChange(_ textView: UITextView) {
        // Update parent binding through the editor
    }
}

// MARK: - WYSIWYG Editor View
struct WYSIWYGEditorView: View {
    @Binding var htmlContent: String
    @State private var editorProxy: RichHTMLEditorProxy?
    @State private var showLinkDialog = false
    @State private var selectedColor: Color = .black
    @State private var selectedBackgroundColor: Color = .white
    @State private var linkURL = ""
    @State private var linkText = ""

    var body: some View {
        RichHTMLEditorViewRepresentable(html: $htmlContent, proxy: $editorProxy)
            .editorScrollable(true)
            .safeAreaInset(edge: .bottom, spacing: -70) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        // Text Formatting
                        Menu {
                            Button(action: { editorProxy?.bold() }) {
                                Label("Bold", systemImage: "bold")
                            }
                            Button(action: { editorProxy?.italic() }) {
                                Label("Italic", systemImage: "italic")
                            }
                            Button(action: { editorProxy?.underline() }) {
                                Label("Underline", systemImage: "underline")
                            }
                            Button(action: { editorProxy?.strikethrough() }) {
                                Label("Strikethrough", systemImage: "strikethrough")
                            }
                        } label: {
                            Label("Format", systemImage: "character.textbox")
                                .labelStyle(.iconOnly)
                        }
                        .tint(.primary)

                        Divider()

                        // Lists
                        Menu {
                            Button(action: { editorProxy?.unorderedList() }) {
                                Label("Bullet List", systemImage: "list.bullet")
                            }
                            Button(action: { editorProxy?.orderedList() }) {
                                Label("Numbered List", systemImage: "list.number")
                            }
                        } label: {
                            Label("Lists", systemImage: "list.bullet")
                                .labelStyle(.iconOnly)
                        }
                        .tint(.primary)

                        Divider()

                        // Alignment
                        Menu {
                            Button(action: { editorProxy?.justify(.left) }) {
                                Label("Left", systemImage: "text.alignleft")
                                    .labelStyle(.iconOnly)
                            }
                            .tint(.primary)
                            
                            Button(action: { editorProxy?.justify(.center) }) {
                                Label("Center", systemImage: "text.aligncenter")
                                    .labelStyle(.iconOnly)
                            }
                            .tint(.primary)
                            
                            Button(action: { editorProxy?.justify(.right) }) {
                                Label("Right", systemImage: "text.alignright")
                                    .labelStyle(.iconOnly)
                            }
                            .tint(.primary)
                            
                            Button(action: { editorProxy?.justify(.full) }) {
                                Label("Justify", systemImage: "text.justify")
                                    .labelStyle(.iconOnly)
                            }
                            .tint(.primary)
                        } label: {
                            Label("Aligment", systemImage: "text.alignleft")
                                .labelStyle(.iconOnly)
                        }
                        .foregroundStyle(.primary)

                        Divider()

                        // Colors
                        ColorPicker("Text Color", selection: $selectedColor)
                            .onChange(of: selectedColor) {
                                editorProxy?.setForegroundColor(UIColor(selectedColor))
                            }
                            .labelsHidden()

                        ColorPicker("Background", selection: $selectedBackgroundColor)
                            .onChange(of: selectedBackgroundColor) {
                                editorProxy?.setBackgroundColor(UIColor(selectedBackgroundColor))
                            }
                            .labelsHidden()

                        Divider()

                        // Indent/Outdent
                        Button(action: { editorProxy?.indent() }) {
                            Label("Indent", systemImage: "increase.indent")
                                .labelStyle(.iconOnly)
                        }
                        .tint(.primary)

                        Button(action: { editorProxy?.outdent() }) {
                            Label("Outdent", systemImage: "decrease.indent")
                                .labelStyle(.iconOnly)
                        }
                        .tint(.primary)

                        Divider()

                        // Link
                        Button(action: { showLinkDialog = true }) {
                            Label("Link", systemImage: "link")
                                .labelStyle(.iconOnly)
                        }
                        .tint(.primary)

                        // Undo/Redo
                        Button(action: { editorProxy?.undo() }) {
                            Label("Undo", systemImage: "arrow.uturn.left")
                                .labelStyle(.iconOnly)
                        }
                        .tint(.primary)

                        Button(action: { editorProxy?.redo() }) {
                            Label("Redo", systemImage: "arrow.uturn.right")
                                .labelStyle(.iconOnly)
                        }
                        .tint(.primary)

                        Button(action: { editorProxy?.removeFormat() }) {
                            Label("Clear Format", systemImage: "text.badge.x")
                                .labelStyle(.iconOnly)
                        }
                        .tint(.primary)

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .background(Color(.secondarySystemBackground))
                .border(Color(.separator), width: 0.5)
            }
            .sheet(isPresented: $showLinkDialog) {
                LinkDialog(
                    linkURL: $linkURL,
                    linkText: $linkText,
                    isPresented: $showLinkDialog,
                    onInsert: {
                        if !linkURL.isEmpty {
                            editorProxy?.addLink(url: URL(string: linkURL) ?? URL(fileURLWithPath: ""), text: linkText.isEmpty ? nil : linkText)
                            linkURL = ""
                            linkText = ""
                            showLinkDialog = false
                        }
                    }
                )
            }
    }
}

// MARK: - RichHTMLEditor UIViewRepresentable
struct RichHTMLEditorViewRepresentable: UIViewRepresentable {
    @Binding var html: String
    @Binding var proxy: RichHTMLEditorProxy?

    class Coordinator: NSObject {
        var parent: RichHTMLEditorViewRepresentable
        var editorProxy: RichHTMLEditorProxy?

        init(_ parent: RichHTMLEditorViewRepresentable) {
            self.parent = parent
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> RichHTMLEditorView {
        let editor = RichHTMLEditorView()
        
        let editorProxy = RichHTMLEditorProxy(editor: editor)
        context.coordinator.editorProxy = editorProxy
        self.proxy = editorProxy
        
        return editor
    }

    func updateUIView(_ uiView: RichHTMLEditorView, context: Context) {
        if uiView.html != html {
            uiView.html = html
        }
    }
}

// MARK: - RichHTMLEditor Proxy
class RichHTMLEditorProxy {
    private let editor: RichHTMLEditorView

    init(editor: RichHTMLEditorView) {
        self.editor = editor
    }

    func bold() { editor.bold() }
    func italic() { editor.italic() }
    func underline() { editor.underline() }
    func strikethrough() { editor.strikethrough() }
    func orderedList() { editor.orderedList() }
    func unorderedList() { editor.unorderedList() }
    func indent() { editor.indent() }
    func outdent() { editor.outdent() }
    func undo() { editor.undo() }
    func redo() { editor.redo() }
    func removeFormat() { editor.removeFormat() }
    func toggleSubscript() { editor.toggleSubscript() }
    func toggleSuperscript() { editor.toggleSuperscript() }

    func justify(_ alignment: TextJustification) {
        editor.justify(alignment)
    }

    func setForegroundColor(_ color: UIColor) {
        editor.setForegroundColor(color)
    }

    func setBackgroundColor(_ color: UIColor) {
        editor.setBackgroundColor(color)
    }

    func addLink(url: URL, text: String?) {
        editor.addLink(url: url, text: text)
    }
}

// MARK: - Raw Editor View with Formatting Toolbar
struct RawEditorView: View {
    @Binding var htmlContent: String
    @State private var showColorPicker = false
    @State private var showLinkDialog = false
    @State private var showImageDialog = false
    @State private var showVideoDialog = false
    @State private var linkURL = ""
    @State private var linkText = ""
    @State private var imageURL = ""
    @State private var imageAltText = ""
    @State private var videoURL = ""
    @State private var selectedTextColor: Color = .black
    @StateObject private var coordinator = TextViewCoordinator()

    var body: some View {
        HTMLTextEditor(html: $htmlContent, coordinator: coordinator)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Text Formatting
                        Menu {
                            Button(action: { insertFormatting(tag: "b") }) {
                                Label("Bold", systemImage: "bold")
                            }
                            Button(action: { insertFormatting(tag: "i") }) {
                                Label("Italic", systemImage: "italic")
                            }
                            Button(action: { insertFormatting(tag: "u") }) {
                                Label("Underline", systemImage: "underline")
                            }
                            Divider()
                            Button(action: { insertFormatting(tag: "h1") }) {
                                Text("H1")
                            }
                            Button(action: { insertFormatting(tag: "h2") }) {
                                Text("H2")
                            }
                        } label: {
                            Label("Format", systemImage: "character.textbox")
                                .labelStyle(.iconOnly)
                        }
                        .tint(.primary)

                        // Lists
                        Menu {
                            Button(action: { insertList(type: "ul") }) {
                                Label("Bullet List", systemImage: "list.bullet")
                            }
                            Button(action: { insertList(type: "ol") }) {
                                Label("Numbered List", systemImage: "list.number")
                            }
                        } label: {
                            Label("Lists", systemImage: "list.bullet")
                                .labelStyle(.iconOnly)
                        }
                        .tint(.primary)

                        // Color
                        Button(action: { showColorPicker = true }) {
                            Label("Color", systemImage: "paintpalette")
                                .labelStyle(.iconOnly)
                        }
                        .tint(.primary)

                        // Insert Elements
                        Menu {
                            Button(action: { showLinkDialog = true }) {
                                Label("Link", systemImage: "link")
                            }
                            Button(action: { showImageDialog = true }) {
                                Label("Image", systemImage: "photo")
                            }
                            Button(action: { showVideoDialog = true }) {
                                Label("Video", systemImage: "play.rectangle")
                            }
                        } label: {
                            Label("Insert", systemImage: "plus.circle")
                                .labelStyle(.iconOnly)
                        }
                        .tint(.primary)

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .background(Color(.secondarySystemBackground))
                .border(Color(.separator), width: 0.5)
            }
            .sheet(isPresented: $showColorPicker) {
                ColorPickerSheet(selectedColor: $selectedTextColor, isPresented: $showColorPicker)
            }
            .sheet(isPresented: $showLinkDialog) {
                LinkDialog(
                    linkURL: $linkURL,
                    linkText: $linkText,
                    isPresented: $showLinkDialog,
                    onInsert: insertLink
                )
            }
            .sheet(isPresented: $showImageDialog) {
                ImageDialog(
                    imageURL: $imageURL,
                    altText: $imageAltText,
                    isPresented: $showImageDialog,
                    onInsert: insertImage
                )
            }
            .sheet(isPresented: $showVideoDialog) {
                VideoDialog(
                    videoURL: $videoURL,
                    isPresented: $showVideoDialog,
                    onInsert: insertVideo
                )
            }
    }

    private func insertFormatting(tag: String) {
        guard let textView = coordinator.textView else {
            print("DEBUG: textView is nil")
            return
        }

        let selectedRange = textView.selectedRange
        let text = textView.text as NSString

        if selectedRange.length > 0 {
            // Apply formatting to selected text
            let selectedText = text.substring(with: selectedRange)
            let formattedText = "<\(tag)>\(selectedText)</\(tag)>"
            let newText = text.replacingCharacters(in: selectedRange, with: formattedText)

            // Update textView directly
            textView.text = newText
            htmlContent = newText

            // Update cursor position to select the formatted text
            let newCursorPos = selectedRange.location + tag.count + 2
            textView.selectedRange = NSRange(location: newCursorPos, length: selectedText.count)
        } else {
            // Insert empty tag at cursor
            let location = selectedRange.location
            let newText = NSMutableString(string: text)
            newText.insert("<\(tag)></\(tag)>", at: location)
            let finalText = String(newText)

            // Update textView directly
            textView.text = finalText
            htmlContent = finalText

            // Move cursor inside the tag
            textView.selectedRange = NSRange(location: location + tag.count + 2, length: 0)
        }
    }

    private func insertList(type: String) {
        guard let textView = coordinator.textView else { return }

        let selectedRange = textView.selectedRange
        let text = textView.text as NSString
        let location = selectedRange.location

        let html =
            type == "ul"
            ? "<ul><li></li></ul>"
            : "<ol><li></li></ol>"

        let newText = NSMutableString(string: text)
        newText.insert(html, at: location)
        let finalText = String(newText)

        // Update textView directly
        textView.text = finalText
        htmlContent = finalText

        // Move cursor inside the list item
        let itemLocation = location + (type == "ul" ? 9 : 9)
        textView.selectedRange = NSRange(location: itemLocation, length: 0)
    }

    private func insertLink() {
        if !linkURL.isEmpty, !linkText.isEmpty {
            guard let textView = coordinator.textView else { return }

            let location = textView.selectedRange.location
            let text = textView.text as NSString
            let html = "<a href=\"\(linkURL)\">\(linkText)</a>"
            let newText = NSMutableString(string: text)
            newText.insert(html, at: location)
            let finalText = String(newText)

            // Update textView directly
            textView.text = finalText
            htmlContent = finalText

            // Move cursor after the link
            textView.selectedRange = NSRange(location: location + html.count, length: 0)

            linkURL = ""
            linkText = ""
            showLinkDialog = false
        }
    }

    private func insertImage() {
        if !imageURL.isEmpty {
            guard let textView = coordinator.textView else { return }

            let location = textView.selectedRange.location
            let text = textView.text as NSString
            let html = "<img src=\"\(imageURL)\" alt=\"\(imageAltText)\" style=\"max-width:100%;height:auto;\" />"
            let newText = NSMutableString(string: text)
            newText.insert(html, at: location)
            let finalText = String(newText)

            // Update textView directly
            textView.text = finalText
            htmlContent = finalText

            // Move cursor after the image
            textView.selectedRange = NSRange(location: location + html.count, length: 0)

            imageURL = ""
            imageAltText = ""
            showImageDialog = false
        }
    }

    private func insertVideo() {
        if !videoURL.isEmpty {
            guard let textView = coordinator.textView else { return }

            let location = textView.selectedRange.location
            let text = textView.text as NSString
            let html = "<iframe src=\"\(videoURL)\" width=\"100%\" height=\"315\" frameborder=\"0\" allowfullscreen=\"true\"></iframe>"
            let newText = NSMutableString(string: text)
            newText.insert(html, at: location)
            let finalText = String(newText)

            // Update textView directly
            textView.text = finalText
            htmlContent = finalText

            // Move cursor after the video
            textView.selectedRange = NSRange(location: location + html.count, length: 0)

            videoURL = ""
            showVideoDialog = false
        }
    }
}

// MARK: - Color Picker Sheet
struct ColorPickerSheet: View {
    @Binding var selectedColor: Color
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ColorPicker("Choose Text Color", selection: $selectedColor)
                    .padding()

                Spacer()
            }
            .navigationTitle("Text Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Font Size Picker Sheet
struct FontSizePickerSheet: View {
    @State private var fontSize: CGFloat = 16
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Font Size")
                    .font(.headline)

                Slider(value: $fontSize, in: 8...36, step: 1)
                    .padding()

                Text("\(Int(fontSize))pt")
                    .font(.system(size: fontSize))

                Spacer()
            }
            .padding()
            .navigationTitle("Font Size")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Link Dialog Sheet
struct LinkDialog: View {
    @Binding var linkURL: String
    @Binding var linkText: String
    @Binding var isPresented: Bool
    var onInsert: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Link Details") {
                    TextField("URL", text: $linkURL, prompt: Text("https://example.com"))
                        .keyboardType(.URL)
                    TextField("Link Text", text: $linkText, prompt: Text("Click here"))
                }
            }
            .navigationTitle("Insert Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Insert") {
                        onInsert()
                    }
                    .disabled(linkURL.isEmpty || linkText.isEmpty)
                }
            }
        }
    }
}

// MARK: - Image Dialog Sheet
struct ImageDialog: View {
    @Binding var imageURL: String
    @Binding var altText: String
    @Binding var isPresented: Bool
    var onInsert: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Image Details") {
                    TextField("Image URL", text: $imageURL, prompt: Text("https://example.com/image.png"))
                        .keyboardType(.URL)
                    TextField("Alt Text", text: $altText, prompt: Text("Description of image"))
                }
            }
            .navigationTitle("Insert Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Insert") {
                        onInsert()
                    }
                    .disabled(imageURL.isEmpty)
                }
            }
        }
    }
}

// MARK: - Video Dialog Sheet
struct VideoDialog: View {
    @Binding var videoURL: String
    @Binding var isPresented: Bool
    var onInsert: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Video Details") {
                    TextField("Video URL", text: $videoURL, prompt: Text("https://youtube.com/watch?v=..."))
                        .keyboardType(.URL)
                    Text("Supports YouTube, Vimeo, and other video platforms")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Insert Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Insert") {
                        onInsert()
                    }
                    .disabled(videoURL.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview Tab
struct PreviewTabView: View {
    @Binding var convertedHTML: String

    var body: some View {
        Text(convertedHTML.htmlToAttributedString())
            .padding()
    }
}

// MARK: - HTML Text Editor
struct HTMLTextEditor: UIViewRepresentable {
    @Binding var html: String
    var coordinator: TextViewCoordinator

    class Delegate: NSObject, UITextViewDelegate {
        var parent: HTMLTextEditor
        var textViewCoordinator: TextViewCoordinator

        init(parent: HTMLTextEditor, coordinator: TextViewCoordinator) {
            self.parent = parent
            self.textViewCoordinator = coordinator
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.html = textView.text
            textViewCoordinator.isEditing = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            textViewCoordinator.isEditing = false
        }
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = true
        textView.text = html
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .systemBackground
        textView.delegate = context.coordinator
        coordinator.textView = textView
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Always sync the text if the binding changed externally
        if uiView.text != html && !coordinator.isEditing {
            let selectedRange = uiView.selectedRange
            uiView.text = html
            // Restore cursor position if it's valid
            if selectedRange.location <= uiView.text.count {
                uiView.selectedRange = selectedRange
            }
        }
    }

    func makeCoordinator() -> Delegate {
        Delegate(parent: self, coordinator: coordinator)
    }
}

#Preview {
    @Previewable @State var previewHTML =
        "<h1>Lorem ipsum</h1><p>Lorem ipsum <b>dolor sit</b> amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur <span style=\"background-color:rgb(255,255,0);\">sadipscing elitr</span>, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.</p><ul><li>At vero eos et accusam et justo duo dolores et ea rebum.</li><li>Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.</li></ul><h1>Lorem ipsum</h1><p>Lorem ipsum <b>dolor sit</b> amet, consetetur \nsadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et \ndolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et\n justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea \ntakimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit \namet, consetetur <span style=\"background-color:rgb(255,255,0);\">sadipscing elitr</span>,\n sed diam nonumy eirmod tempor invidunt ut labore et dolore magna \naliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo \ndolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus \nest Lorem ipsum dolor sit amet.</p>"

    return RecipePreparationEditorView(htmlContent: $previewHTML)
}
