//
//  RecipePreparationEditorView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 07.03.26.
//

internal import Combine
import InfomaniakRichHTMLEditor
import SwiftUI

#if os(iOS)
    import UIKit
#endif

struct RecipePreparationEditorView: View {
    @Binding var htmlContent: String
    /// The editor is shared by recipes ("Preparation") and equipment ("Notes").
    var title: LocalizedStringKey = "Preparation"
    @State private var temporaryHTML: String = ""
    @State private var selectedTab: TabSelection = .wysiwygEditor
    @Environment(\.dismiss) var dismiss

    enum TabSelection {
        case rawEditor
        case wysiwygEditor
        case preview
    }

    init(htmlContent: Binding<String>, title: LocalizedStringKey = "Preparation") {
        self._htmlContent = htmlContent
        self.title = title
        self._temporaryHTML = State(initialValue: htmlContent.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top tab bar — stays visible above keyboard at all times
                Picker("", selection: $selectedTab) {
                    Label("WYSIWYG", systemImage: MySymbols.richText)
                        .labelStyle(.titleAndIcon)
                        .tag(RecipePreparationEditorView.TabSelection.wysiwygEditor)
                    Label("HTML", systemImage: MySymbols.htmlCode)
                        .labelStyle(.titleAndIcon)
                        .tag(RecipePreparationEditorView.TabSelection.rawEditor)
                    Label("Preview", systemImage: MySymbols.preview)
                        .labelStyle(.titleAndIcon)
                        .tag(RecipePreparationEditorView.TabSelection.preview)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, Spacing.small)

                Divider()

                // Content area — switches between the three editor modes
                Group {
                    switch selectedTab {
                    case .wysiwygEditor:
                        WYSIWYGEditorView(htmlContent: $temporaryHTML)
                    case .rawEditor:
                        RawEditorView(htmlContent: $temporaryHTML)
                    case .preview:
                        PreviewTabView(html: $temporaryHTML)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(title)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
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

// MARK: - WYSIWYG Editor View

struct WYSIWYGEditorView: View {
    @Binding var htmlContent: String
    @State private var bridge = RichHTMLEditorBridge()
    @State private var showLinkDialog = false
    @State private var selectedColor: Color = .black
    @State private var selectedBackgroundColor: Color = .white
    @State private var linkURL: String = ""
    @State private var linkText: String = ""
    #if os(iOS)
        /// True while the keyboard is visible. Drives toolbar visibility.
        @State private var keyboardVisible: Bool = false
    #else
        /// macOS has no on-screen keyboard, the formatting bar is always shown.
        private let keyboardVisible: Bool = true
    #endif

    var body: some View {
        editor
            // The formatting bar attaches to the bottom safe area inset. On iOS,
            // SwiftUI lifts this inset when the keyboard appears, so the bar travels with the keyboard.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if keyboardVisible {
                    GlassEffectContainer {
                        ScrollView(.horizontal, showsIndicators: false) {
                            formattingBar
                        }
                    }
                    .padding()
                    .background(.bar)
                    .overlay(alignment: .top) { Divider() }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            #if os(iOS)
                .onReceive(
                    NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                ) { _ in
                    withAnimation(.easeOut(duration: 0.25)) { keyboardVisible = true }
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                ) { _ in
                    withAnimation(.easeIn(duration: 0.2)) { keyboardVisible = false }
                }
            #endif
            .sheet(isPresented: $showLinkDialog) {
                LinkDialog(
                    linkURL: $linkURL,
                    linkText: $linkText,
                    isPresented: $showLinkDialog,
                    onInsert: {
                        if !linkURL.isEmpty {
                            bridge.addLink(
                                url: URL(string: linkURL) ?? URL(fileURLWithPath: ""),
                                text: linkText.isEmpty ? nil : linkText
                            )
                            linkURL = ""
                            linkText = ""
                            showLinkDialog = false
                        }
                    }
                )
            }
    }

    @ViewBuilder
    private var editor: some View {
        #if os(iOS)
            // The editor grows with its content and the native ScrollView scrolls it. SwiftUI's
            // scroll view handles keyboard avoidance itself (shrinking its frame, not the window),
            // so the tab bar above is unaffected, and the editor scrolls the caret into view.
            ScrollView(.vertical) {
                RichHTMLEditorRepresentable(html: $htmlContent, bridge: bridge)
                    .padding(.horizontal)
                    .frame(minHeight: Sizes.preparationEditorMinHeight)
                    .frame(maxWidth: .infinity)
            }
        #else
            // The web view scrolls its content itself on macOS.
            RichHTMLEditorRepresentable(html: $htmlContent, bridge: bridge)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }

    var formattingBar: some View {
        HStack(spacing: Spacing.small) {
            #if os(iOS)
                Button {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                } label: {
                    Image(systemName: MySymbols.dismissKeyboard)
                        .font(.callout.weight(.semibold))
                }
                .tint(.secondary)
                .buttonStyle(FormattingButtonStyleAdditional())
            #endif

            Divider()
                .frame(height: Sizes.toolbarDividerHeight)

            // Bold
            Button(action: { bridge.bold() }) {
                Image(systemName: MySymbols.formatBold)
                    .font(.callout.weight(.semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: bridge.formatting.hasBold))

            // Italic
            Button(action: { bridge.italic() }) {
                Image(systemName: MySymbols.formatItalic)
                    .font(.callout.weight(.semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: bridge.formatting.hasItalic))

            // Underline
            Button(action: { bridge.underline() }) {
                Image(systemName: MySymbols.formatUnderline)
                    .font(.callout.weight(.semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: bridge.formatting.hasUnderline))

            // Strikethrough
            Button(action: { bridge.strikethrough() }) {
                Image(systemName: MySymbols.formatStrikethrough)
                    .font(.callout.weight(.semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: bridge.formatting.hasStrikethrough))

            Divider()
                .frame(height: Sizes.toolbarDividerHeight)

            // Bullet List
            Button(action: { bridge.unorderedList() }) {
                Image(systemName: MySymbols.formatBulletList)
                    .font(.callout.weight(.semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: bridge.formatting.hasUnorderedList))

            // Numbered List
            Button(action: { bridge.orderedList() }) {
                Image(systemName: MySymbols.formatNumberedList)
                    .font(.callout.weight(.semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: bridge.formatting.hasOrderedList))

            Divider()
                .frame(height: Sizes.toolbarDividerHeight)

            // Align Left
            Button(action: { bridge.justify(.left) }) {
                Image(systemName: MySymbols.formatAlignLeft)
                    .font(.callout.weight(.semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: bridge.formatting.textJustification == .left))

            // Align Center
            Button(action: { bridge.justify(.center) }) {
                Image(systemName: MySymbols.formatAlignCenter)
                    .font(.callout.weight(.semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: bridge.formatting.textJustification == .center))

            // Align Right
            Button(action: { bridge.justify(.right) }) {
                Image(systemName: MySymbols.formatAlignRight)
                    .font(.callout.weight(.semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: bridge.formatting.textJustification == .right))

            // Justify
            Button(action: { bridge.justify(.full) }) {
                Image(systemName: MySymbols.formatJustify)
                    .font(.callout.weight(.semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: bridge.formatting.textJustification == .full))

            Divider()
                .frame(height: Sizes.toolbarDividerHeight)

            // Indent
            Button(action: { bridge.indent() }) {
                Image(systemName: MySymbols.formatIndentIncrease)
                    .font(.callout.weight(.semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyleAdditional())

            // Outdent
            Button(action: { bridge.outdent() }) {
                Image(systemName: MySymbols.formatIndentDecrease)
                    .font(.callout.weight(.semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyleAdditional())

            Divider()
                .frame(height: Sizes.toolbarDividerHeight)

            // Foreground Color
            FormattingColorPicker(selection: $selectedColor, iconName: MySymbols.formatTextColor)
                .onChange(of: selectedColor) {
                    bridge.setForegroundColor(PlatformColor(selectedColor))
                }
                .labelsHidden()

            // Background Color
            FormattingColorPicker(selection: $selectedBackgroundColor, iconName: MySymbols.formatHighlightColor)
                .onChange(of: selectedBackgroundColor) {
                    bridge.setBackgroundColor(PlatformColor(selectedBackgroundColor))
                }
                .labelsHidden()

            Divider()
                .frame(height: Sizes.toolbarDividerHeight)

            // Link
            Button(action: { showLinkDialog = true }) {
                Image(systemName: MySymbols.link)
                    .font(.callout.weight(.semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyle(isSelected: bridge.formatting.hasLink))

            Divider()
                .frame(height: Sizes.toolbarDividerHeight)

            // Undo
            Button(action: { bridge.undo() }) {
                Image(systemName: MySymbols.editorUndo)
                    .font(.callout.weight(.semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyleAdditional())

            // Redo
            Button(action: { bridge.redo() }) {
                Image(systemName: MySymbols.editorRedo)
                    .font(.callout.weight(.semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyleAdditional())

            // Clear Format
            Button(action: { bridge.removeFormat() }) {
                Image(systemName: MySymbols.formatClear)
                    .font(.callout.weight(.semibold))
            }
            .tint(.primary)
            .buttonStyle(FormattingButtonStyleAdditional())
        }
    }
}

// MARK: - Button Style
struct FormattingButtonStyleAdditional: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(height: Sizes.minimumHitTarget)
            .frame(minWidth: Sizes.minimumHitTarget)
            .glassEffect(.regular.interactive())

    }
}

struct FormattingButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(height: Sizes.minimumHitTarget)
            .frame(minWidth: Sizes.minimumHitTarget)
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
                        .frame(height: Sizes.colorIndicatorHeight)
                        .padding(.horizontal, Spacing.xxSmall)
                        .offset(y: 6)
                }
                .allowsHitTesting(false)
        }
        .frame(height: Sizes.minimumHitTarget)
        .frame(minWidth: Sizes.minimumHitTarget)
        .glassEffect(.regular.interactive())
    }
}

// MARK: - RichHTMLEditor Representable

/// Hosts the `RichHTMLEditorView` (a `UIView` on iOS, an `NSView` on macOS).
struct RichHTMLEditorRepresentable {
    @Binding var html: String
    let bridge: RichHTMLEditorBridge

    private func makeEditor() -> RichHTMLEditorView {
        bridge.onHTMLChange = { newHTML in html = newHTML }
        return bridge.makeEditor(html: html)
    }

    private func updateEditor() {
        bridge.onHTMLChange = { newHTML in html = newHTML }
        bridge.update(html: html)
    }
}

#if os(iOS)
    extension RichHTMLEditorRepresentable: UIViewRepresentable {
        func makeUIView(context: Context) -> RichHTMLEditorView { makeEditor() }

        func updateUIView(_ uiView: RichHTMLEditorView, context: Context) { updateEditor() }

        /// As tall as its content, so the surrounding scroll view scrolls it.
        func sizeThatFits(_ proposal: ProposedViewSize, uiView: RichHTMLEditorView, context: Context) -> CGSize? {
            proposal.replacingUnspecifiedDimensions(by: uiView.intrinsicContentSize)
        }
    }
#else
    extension RichHTMLEditorRepresentable: NSViewRepresentable {
        func makeNSView(context: Context) -> RichHTMLEditorView { makeEditor() }

        func updateNSView(_ nsView: RichHTMLEditorView, context: Context) { updateEditor() }

        /// Fills the offered space, the web view scrolls its content.
        func sizeThatFits(_ proposal: ProposedViewSize, nsView: RichHTMLEditorView, context: Context) -> CGSize? {
            proposal.replacingUnspecifiedDimensions(
                by: CGSize(width: Sizes.preparationEditorMinHeight, height: Sizes.preparationEditorMinHeight)
            )
        }
    }
#endif

// MARK: - RichHTMLEditor Bridge

/// The formatting of the selected text, as shown by the formatting bar.
struct EditorFormatting: Equatable {
    var hasBold = false
    var hasItalic = false
    var hasUnderline = false
    var hasStrikethrough = false
    var hasOrderedList = false
    var hasUnorderedList = false
    var hasLink = false
    var textJustification: TextJustification?

    init() {}

    init(_ attributes: UITextAttributes) {
        hasBold = attributes.hasBold
        hasItalic = attributes.hasItalic
        hasUnderline = attributes.hasUnderline
        hasStrikethrough = attributes.hasStrikeThrough
        hasOrderedList = attributes.hasOrderedList
        hasUnorderedList = attributes.hasUnorderedList
        hasLink = attributes.hasLink
        textJustification = attributes.textJustification
    }
}

/// Owns the editor, syncs its HTML with SwiftUI and runs the formatting commands.
@Observable
final class RichHTMLEditorBridge: RichHTMLEditorViewDelegate {
    /// Only replaced when the formatting changed, so moving the caret doesn't redraw the formatting bar.
    private(set) var formatting = EditorFormatting()

    @ObservationIgnored private(set) var editor: RichHTMLEditorView?
    @ObservationIgnored var onHTMLChange: ((String) -> Void)?
    /// The HTML the editor has, as far as SwiftUI knows: what it was given or last reported.
    /// The editor's own `html` only changes once its web view reported back, so it can't be used to detect outside changes.
    @ObservationIgnored private var knownHTML: String?

    /// Makes the empty space below the text editable too.
    private static let editorCSS = """
        #swift-rich-html-editor { min-height: 100vh; box-sizing: border-box; }
        """

    func makeEditor(html: String) -> RichHTMLEditorView {
        let editor = RichHTMLEditorView()
        editor.delegate = self
        editor.injectAdditionalCSS(Self.editorCSS)
        editor.html = html
        knownHTML = html
        self.editor = editor
        return editor
    }

    /// Passes changes made outside the editor (e.g. in the HTML tab) to it. Changes it reported itself aren't sent back,
    /// that would reset the caret while typing.
    func update(html: String) {
        guard html != knownHTML else { return }
        knownHTML = html
        editor?.html = html
    }

    // MARK: - RichHTMLEditorViewDelegate

    func richHTMLEditorViewDidLoad(_ richHTMLEditorView: RichHTMLEditorView) {
        #if os(macOS)
            // AppKit declares `NSView.window` `unowned(unsafe)`. Safe here: the view is in its window while it loads.
            unsafe richHTMLEditorView.window?.makeFirstResponder(richHTMLEditorView.webView)
        #endif
        _ = richHTMLEditorView.becomeFirstResponder()
    }

    func richHTMLEditorViewDidChange(_ richHTMLEditorView: RichHTMLEditorView) {
        let newHTML = richHTMLEditorView.html
        guard newHTML != knownHTML else { return }
        knownHTML = newHTML
        onHTMLChange?(newHTML)
    }

    func richHTMLEditorView(_ richHTMLEditorView: RichHTMLEditorView, selectedTextAttributesDidChange textAttributes: UITextAttributes) {
        let newFormatting = EditorFormatting(textAttributes)
        if newFormatting != formatting {
            formatting = newFormatting
        }
    }

    // MARK: - Commands
    // The editor reports the new formatting after each command.

    func bold() { editor?.bold() }
    func italic() { editor?.italic() }
    func underline() { editor?.underline() }
    func strikethrough() { editor?.strikethrough() }
    func orderedList() { editor?.orderedList() }
    func unorderedList() { editor?.unorderedList() }
    func indent() { editor?.indent() }
    func outdent() { editor?.outdent() }
    func undo() { editor?.undo() }
    func redo() { editor?.redo() }
    func removeFormat() { editor?.removeFormat() }
    func justify(_ alignment: TextJustification) { editor?.justify(alignment) }
    func setForegroundColor(_ color: PlatformColor) { editor?.setForegroundColor(color) }
    func setBackgroundColor(_ color: PlatformColor) { editor?.setBackgroundColor(color) }
    func addLink(url: URL, text: String?) { editor?.addLink(url: url, text: text) }
}

// MARK: - Raw Editor View with Formatting Toolbar
struct RawEditorView: View {
    @Binding var htmlContent: String

    var body: some View {
        TextEditor(text: $htmlContent)
            .font(.system(.body, design: .monospaced))
            #if os(iOS)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Button {
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil,
                                from: nil,
                                for: nil
                            )
                        } label: {
                            Image(systemName: MySymbols.dismissKeyboard)
                        }
                        .tint(.secondary)
                        Spacer()
                    }
                }
            #endif
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
                    TextField("URL", text: $linkURL)
                        #if os(iOS)
                            .keyboardType(.URL)
                        #endif
                    TextField("Link Text", text: $linkText)
                }
            }
            .navigationTitle("Insert Link")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        onInsert()
                    } label: {
                        Label("Insert", systemImage: MySymbols.link)
                    }
                    .disabled(linkURL.isEmpty || linkText.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview Tab
struct PreviewTabView: View {
    @Binding var html: String

    var body: some View {
        // The preview is as tall as its content.
        ScrollView {
            HTMLPreviewView(htmlContent: $html)
                .padding(.horizontal)
        }
    }
}

#Preview {
    @Previewable @State var previewHTML =
        "<h1>Lorem ipsum</h1><p>Lorem ipsum <b>dolor sit</b> amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur <span style=\"background-color:rgb(255,255,0);\">sadipscing elitr</span>, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.</p><ul><li>At vero eos et accusam et justo duo dolores et ea rebum.</li><li>Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.</li></ul><h1>Lorem ipsum</h1><p>Lorem ipsum <b>dolor sit</b> amet, consetetur \nsadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et \ndolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et\n justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea \ntakimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit \namet, consetetur <span style=\"background-color:rgb(255,255,0);\">sadipscing elitr</span>,\n sed diam nonumy eirmod tempor invidunt ut labore et dolore magna \naliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo \ndolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus \nest Lorem ipsum dolor sit amet.</p>"

    return RecipePreparationEditorView(htmlContent: $previewHTML)
}
