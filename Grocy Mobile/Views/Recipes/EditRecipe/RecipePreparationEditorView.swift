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
    @StateObject private var proxyObserver = RichHTMLEditorProxy(editor: RichHTMLEditorView())
    @State private var showLinkDialog = false
    @State private var selectedColor: Color = .black
    @State private var selectedBackgroundColor: Color = .white
    @State private var linkURL = ""
    @State private var linkText = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            RichHTMLEditorViewRepresentable(html: $htmlContent, proxy: $editorProxy, proxyObserver: proxyObserver)
                .editorScrollable(true)
                .padding(.horizontal)

            Rectangle()
                .glassEffect(.regular, in: .rect)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Color(.systemBackground).opacity(0.6), location: 0.4),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .frame(height: 120)
                .allowsHitTesting(false)
            ScrollView(.horizontal, showsIndicators: false) {
                formattingBar
                    .padding(.horizontal)
            }
            .scrollClipDisabled()
            .padding(.top, 16)
            .padding(.bottom, 35)
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

    var formattingBar: some View {
        HStack(spacing: 8) {
            // Bold
            Button(action: { editorProxy?.bold() }) {
                Image(systemName: "bold")
                    .font(.system(size: 16, weight: .semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: proxyObserver.hasBold))

            // Italic
            Button(action: { editorProxy?.italic() }) {
                Image(systemName: "italic")
                    .font(.system(size: 16, weight: .semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: proxyObserver.hasItalic))

            // Underline
            Button(action: { editorProxy?.underline() }) {
                Image(systemName: "underline")
                    .font(.system(size: 16, weight: .semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: proxyObserver.hasUnderline))

            // Strikethrough
            Button(action: { editorProxy?.strikethrough() }) {
                Image(systemName: "strikethrough")
                    .font(.system(size: 16, weight: .semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: proxyObserver.hasStrikethrough))

            Divider()
                .frame(height: 20)

            // Bullet List
            Button(action: { editorProxy?.unorderedList() }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 16, weight: .semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: proxyObserver.hasUnorderedList))

            // Numbered List
            Button(action: { editorProxy?.orderedList() }) {
                Image(systemName: "list.number")
                    .font(.system(size: 16, weight: .semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: proxyObserver.hasOrderedList))

            Divider()
                .frame(height: 20)

            // Align Left
            Button(action: { editorProxy?.justify(.left) }) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 16, weight: .semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: proxyObserver.currentJustification == .left))

            // Align Center
            Button(action: { editorProxy?.justify(.center) }) {
                Image(systemName: "text.aligncenter")
                    .font(.system(size: 16, weight: .semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: proxyObserver.currentJustification == .center))

            // Align Right
            Button(action: { editorProxy?.justify(.right) }) {
                Image(systemName: "text.alignright")
                    .font(.system(size: 16, weight: .semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: proxyObserver.currentJustification == .right))

            // Justify
            Button(action: { editorProxy?.justify(.full) }) {
                Image(systemName: "text.justify")
                    .font(.system(size: 16, weight: .semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: proxyObserver.currentJustification == .full))

            Divider()
                .frame(height: 20)

            // Indent
            Button(action: { editorProxy?.indent() }) {
                Image(systemName: "increase.indent")
                    .font(.system(size: 16, weight: .semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyleAdditional())

            // Outdent
            Button(action: { editorProxy?.outdent() }) {
                Image(systemName: "decrease.indent")
                    .font(.system(size: 16, weight: .semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyleAdditional())

            Divider()
                .frame(height: 20)

            // Foreground Color
            FormattingColorPicker(selection: $selectedColor, iconName: "paintbrush.pointed")
                .onChange(of: selectedColor) {
                    editorProxy?.setForegroundColor(UIColor(selectedColor))
                }
                .labelsHidden()

            // Background Color
            FormattingColorPicker(selection: $selectedBackgroundColor, iconName: "paint.bucket.classic")
                .onChange(of: selectedBackgroundColor) {
                    editorProxy?.setBackgroundColor(UIColor(selectedBackgroundColor))
                }
                .labelsHidden()

            Divider()
                .frame(height: 20)

            // Link
            Button(action: { showLinkDialog = true }) {
                Image(systemName: "link")
                    .font(.system(size: 16, weight: .semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: proxyObserver.hasLink))

            Divider()
                .frame(height: 20)

            // Undo
            Button(action: { editorProxy?.undo() }) {
                Image(systemName: "arrow.uturn.left")
                    .font(.system(size: 16, weight: .semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyleAdditional())

            // Redo
            Button(action: { editorProxy?.redo() }) {
                Image(systemName: "arrow.uturn.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyleAdditional())

            // Clear Format
            Button(action: { editorProxy?.removeFormat() }) {
                Image(systemName: "text.badge.xmark")
                    .font(.system(size: 16, weight: .semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyleAdditional())

            Spacer()
        }
    }
}

// MARK: - Button Style
struct FormattingButtonStyleAdditional: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(height: 40)
            .frame(minWidth: 40)
            .glassEffect(.regular.interactive())

    }
}

struct FormattingButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(height: 40)
            .frame(minWidth: 40)
            .glassEffect(isSelected ? .regular.tint(.blue.opacity(0.2)).interactive() : .regular.interactive())
    }
}

struct FormattingColorPicker: View {
    @Binding var selection: Color
    let iconName: String

    var body: some View {
        ZStack {
            // Native control: invisible but fully tappable
            ColorPicker("", selection: $selection)
                .labelsHidden()
                .opacity(0.011)  // 0.0 disables hit testing on some versions, keep just above zero

            Image(systemName: iconName)
                .overlay(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(selection)
                        .frame(height: 4)
                        .padding(.horizontal, 4)
                        .offset(y: 6)
                }
                .allowsHitTesting(false)
        }
        .frame(height: 40)
        .frame(minWidth: 40)
        .glassEffect(.regular.interactive())
    }
}

// MARK: - RichHTMLEditor UIViewRepresentable
struct RichHTMLEditorViewRepresentable: UIViewRepresentable {
    @Binding var html: String
    @Binding var proxy: RichHTMLEditorProxy?
    var proxyObserver: RichHTMLEditorProxy

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
        let editor = proxyObserver.editor

        context.coordinator.editorProxy = proxyObserver
        self.proxy = proxyObserver

        return editor
    }

    func updateUIView(_ uiView: RichHTMLEditorView, context: Context) {
        if uiView.html != html {
            uiView.html = html
        }
    }
}

// MARK: - RichHTMLEditor Proxy
class RichHTMLEditorProxy: NSObject, ObservableObject, RichHTMLEditorViewDelegate {
    let editor: RichHTMLEditorView
    @Published var hasBold = false
    @Published var hasItalic = false
    @Published var hasUnderline = false
    @Published var hasStrikethrough = false
    @Published var hasOrderedList = false
    @Published var hasUnorderedList = false
    @Published var hasLink = false
    @Published var currentJustification: TextJustification? = nil

    init(editor: RichHTMLEditorView) {
        self.editor = editor
        super.init()
        self.editor.delegate = self
        updateTextAttributes()
    }

    // MARK: - RichHTMLEditorViewDelegate
    func richHTMLEditorViewDidLoad(_ richHTMLEditorView: RichHTMLEditorView) {
        _ = richHTMLEditorView.becomeFirstResponder()
    }

    func richHTMLEditorView(_ richHTMLEditorView: RichHTMLEditorView, selectedTextAttributesDidChange textAttributes: UITextAttributes) {
        updateTextAttributes(with: textAttributes)
    }

    func bold() {
        editor.bold()
        updateTextAttributes()
    }
    func italic() {
        editor.italic()
        updateTextAttributes()
    }
    func underline() {
        editor.underline()
        updateTextAttributes()
    }
    func strikethrough() {
        editor.strikethrough()
        updateTextAttributes()
    }
    func orderedList() {
        editor.orderedList()
        updateTextAttributes()
    }
    func unorderedList() {
        editor.unorderedList()
        updateTextAttributes()
    }
    func indent() {
        editor.indent()
        updateTextAttributes()
    }
    func outdent() {
        editor.outdent()
        updateTextAttributes()
    }
    func undo() {
        editor.undo()
        updateTextAttributes()
    }
    func redo() {
        editor.redo()
        updateTextAttributes()
    }
    func removeFormat() {
        editor.removeFormat()
        updateTextAttributes()
    }
    func toggleSubscript() {
        editor.toggleSubscript()
        updateTextAttributes()
    }
    func toggleSuperscript() {
        editor.toggleSuperscript()
        updateTextAttributes()
    }

    func justify(_ alignment: TextJustification) {
        editor.justify(alignment)
        updateTextAttributes()
    }

    func setForegroundColor(_ color: UIColor) {
        editor.setForegroundColor(color)
        updateTextAttributes()
    }

    func setBackgroundColor(_ color: UIColor) {
        editor.setBackgroundColor(color)
        updateTextAttributes()
    }

    func addLink(url: URL, text: String?) {
        editor.addLink(url: url, text: text)
        updateTextAttributes()
    }

    // MARK: - Update Text Attributes
    private func updateTextAttributes(with textAttributes: UITextAttributes? = nil) {
        DispatchQueue.main.async {
            let attributes = textAttributes ?? self.editor.selectedTextAttributes
            self.hasBold = attributes.hasBold
            self.hasItalic = attributes.hasItalic
            self.hasUnderline = attributes.hasUnderline
            self.hasStrikethrough = attributes.hasStrikeThrough
            self.hasOrderedList = attributes.hasOrderedList
            self.hasUnorderedList = attributes.hasUnorderedList
            self.hasLink = attributes.hasLink
            self.currentJustification = attributes.textJustification
        }
    }
}

// MARK: - Raw Editor View with Formatting Toolbar
struct RawEditorView: View {
    @Binding var htmlContent: String

    var body: some View {
        TextEditor(text: $htmlContent)
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
        ScrollView {
            Text(convertedHTML.htmlToAttributedString())
                .padding()
        }
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
