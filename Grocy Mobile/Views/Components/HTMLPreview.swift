//
//  HTMLPreview.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 22.03.26.
//

import SwiftUI
import WebKit

enum WebColorScheme: String, CaseIterable {
    case light = "Light"
    case system = "System"
    case dark = "Dark"

    var icon: String {
        switch self {
        case .dark: return MySymbols.darkMode
        case .light: return MySymbols.lightMode
        case .system: return MySymbols.systemDarkMode
        }
    }
}

/// Renders HTML (recipe preparation, equipment notes) in a web view that is as tall as its content,
/// so it scrolls with the surrounding list instead of inside a box of its own.
struct HTMLPreviewView: View {
    @Binding var htmlContent: String
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.openURL) private var openURL

    /// The height until the content has been measured.
    var minHeight: CGFloat = 300
    var showControlBar: Bool = true
    var minFontScale: Double = 0.5
    var maxFontScale: Double = 2.0

    /// Created once, on appear. A `WebPage()` as the initial value of `@State` would be built
    /// (and thrown away) every time the parent view re-evaluates its body.
    @State private var page: WebPage?
    @State private var contentHeight: CGFloat?
    @State private var viewWidth: CGFloat = 0
    @State private var fontScale: Double = 1.0
    @State private var webColorScheme: WebColorScheme = .system

    private static let blank = URL(string: "about:blank")

    /// The height of the document's content. `scrollHeight` never gets smaller than the view, so it can't be used to shrink it.
    private static let measureScript = "return Math.ceil(document.documentElement.getBoundingClientRect().height);"

    private var activeIsDark: Bool {
        switch webColorScheme {
        case .light: return false
        case .dark: return true
        case .system: return systemColorScheme == .dark
        }
    }

    /// Changes that need the content to be measured again, after the web view laid it out.
    private struct LayoutKey: Equatable {
        var width: CGFloat
        var fontScale: Double
    }

    var body: some View {
        VStack(spacing: 0) {
            if showControlBar {
                controlBar
            }

            webView
                .frame(height: contentHeight ?? minHeight)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .onAppear {
            createPageIfNeeded()
        }
        .onChange(of: htmlContent) {
            loadContent()
        }
        // Switching the appearance only changes the color scheme of the loaded document instead of loading it again.
        .onChange(of: activeIsDark) {
            applyColorScheme()
        }
        // Live updates while the slider is dragged.
        .onChange(of: fontScale) {
            applyFontScale()
        }
        .onChange(of: page?.isLoading) { _, isLoading in
            guard isLoading == false else { return }
            Task { await measureContentHeight() }
        }
        // Debounced: a window resize or a slider drag measures once, after it settled.
        .task(id: LayoutKey(width: viewWidth, fontScale: fontScale)) {
            guard contentHeight != nil, (try? await Task.sleep(for: .milliseconds(150))) != nil else { return }
            await measureContentHeight()
        }
    }

    @ViewBuilder
    private var webView: some View {
        if let page {
            WebView(page)
                .webViewBackForwardNavigationGestures(.disabled)
                .webViewMagnificationGestures(.disabled)
                .scrollBounceBehavior(.basedOnSize)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { newWidth in
                    viewWidth = newWidth
                }
        } else {
            Color.clear
        }
    }

    // MARK: - Web page

    private func createPageIfNeeded() {
        guard page == nil else { return }
        var configuration = WebPage.Configuration()
        // The content is only displayed. Scripts in it don't run; the app's own calls still work.
        configuration.defaultNavigationPreferences.allowsContentJavaScript = false
        #if os(macOS)
            configuration.applicationNameForUserAgent = HTMLPreviewScrollForwarding.applicationName
            HTMLPreviewScrollForwarding.install()
        #endif
        page = WebPage(configuration: configuration, navigationDecider: ExternalLinkNavigationDecider(openURL: openURL))
        loadContent()
    }

    private func loadContent() {
        guard let page, let blank = Self.blank else { return }
        page.load(html: preparedHTML(htmlContent), baseURL: blank)
    }

    /// Adds the color scheme, the font scale and responsive styles, so the first layout is already the right one.
    private func preparedHTML(_ raw: String) -> String {
        let scheme = activeIsDark ? "dark" : "light"
        let injection = """
            <meta name="color-scheme" content="\(scheme)">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                html { font-size: \(Int(fontScale * 100))%; color-scheme: \(scheme); }
                body { overflow-x: hidden !important; word-wrap: break-word; }
                img, video, pre, table { max-width: 100%; }
            </style>
            """
        if let range = raw.range(of: "<head>", options: .caseInsensitive) {
            var result = raw
            result.insert(contentsOf: injection, at: range.upperBound)
            return result
        }
        return injection + raw
    }

    private func applyColorScheme() {
        let scheme = activeIsDark ? "dark" : "light"
        let script = """
            document.documentElement.style.colorScheme = '\(scheme)';
            document.querySelector('meta[name="color-scheme"]')?.setAttribute('content', '\(scheme)');
            """
        run(script)
    }

    private func applyFontScale() {
        run("document.documentElement.style.fontSize = '\(Int(fontScale * 100))%';")
    }

    /// Runs a script on the loaded document. While the page loads, it already uses the current settings (see `preparedHTML`).
    private func run(_ script: String) {
        guard let page, !page.isLoading else { return }
        Task { _ = try? await page.callJavaScript(script) }
    }

    private func measureContentHeight() async {
        guard let page, !page.isLoading,
            let result = try? await page.callJavaScript(Self.measureScript),
            let height = (result as? NSNumber)?.doubleValue, height > 0
        else { return }
        let newHeight = CGFloat(height)
        if contentHeight != newHeight {
            contentHeight = newHeight
        }
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        VStack(spacing: Spacing.small) {
            // Line 1: Appearance picker + scale percentage
            GlassEffectContainer(spacing: Spacing.medium) {
                HStack(spacing: Spacing.medium) {
                    Picker("Appearance", selection: $webColorScheme) {
                        ForEach(WebColorScheme.allCases, id: \.self) { scheme in
                            Image(systemName: scheme.icon).tag(scheme)
                        }
                    }
                    .pickerStyle(.segmented)

                    Spacer()

                    Text(fontScale, format: .percent)
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .fixedSize()  // Prevents wrapping
                        .onTapGesture {
                            withAnimation(.smooth) { fontScale = 1.0 }
                        }
                }
                .padding(.vertical, Spacing.xxSmall)
            }

            // Line 2: Smaller → Slider → Larger
            GlassEffectContainer(spacing: Spacing.medium) {
                HStack(spacing: Spacing.medium) {
                    Button {
                        fontScale = max(minFontScale, (fontScale - 0.1).rounded(toPlaces: 1))
                    } label: {
                        Image(systemName: MySymbols.fontSizeDecrease)
                            .frame(width: Sizes.minimumHitTarget, height: Sizes.minimumHitTarget)
                    }
                    .glassEffect(.regular.interactive(), in: .circle)
                    .disabled(fontScale <= minFontScale)

                    Slider(value: $fontScale, in: minFontScale...maxFontScale, step: 0.1)

                    Button {
                        fontScale = min(maxFontScale, (fontScale + 0.1).rounded(toPlaces: 1))
                    } label: {
                        Image(systemName: MySymbols.fontSizeIncrease)
                            .frame(width: Sizes.minimumHitTarget, height: Sizes.minimumHitTarget)
                    }
                    .glassEffect(.regular.interactive(), in: .circle)
                    .disabled(fontScale >= maxFontScale)
                }
                .padding(.vertical, Spacing.xxSmall)
            }
        }
        .buttonStyle(.plain)
        .padding(.bottom, Spacing.small)
    }
}

// MARK: - Navigation

/// Opens tapped links in the browser instead of replacing the displayed content.
private struct ExternalLinkNavigationDecider: WebPage.NavigationDeciding {
    let openURL: OpenURLAction

    func decidePolicy(for action: WebPage.NavigationAction, preferences: inout WebPage.NavigationPreferences) async -> WKNavigationActionPolicy {
        guard action.navigationType == .linkActivated, let url = action.request.url else {
            return .allow
        }
        openURL(url)
        return .cancel
    }
}

#if os(macOS)
    /// On the Mac, a web view keeps the scrolling of the mouse and the trackpad while the pointer is over it, even when it has
    /// nothing to scroll, so the list around a preparation or a note stopped scrolling there. The previews are as tall as their
    /// content, so their scrolling goes to the scroll view around them instead. The rich text editor's web view isn't touched:
    /// the previews are told apart by the application name in their user agent.
    private enum HTMLPreviewScrollForwarding {
        static let applicationName = "GrocyMobilePreview"
        private static var monitor: Any?

        static func install() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                // Local monitors run on the main thread.
                let forwarded = MainActor.assumeIsolated {
                    guard let scrollView = enclosingScrollView(ofPreviewAt: event) else { return false }
                    scrollView.scrollWheel(with: event)
                    return true
                }
                return forwarded ? nil : event
            }
        }

        private static func enclosingScrollView(ofPreviewAt event: NSEvent) -> NSScrollView? {
            var view = event.window?.contentView?.hitTest(event.locationInWindow)
            while let current = view, !(current is WKWebView) {
                view = current.superview
            }
            guard let webView = view as? WKWebView, webView.configuration.applicationNameForUserAgent == applicationName else { return nil }
            return webView.enclosingScrollView
        }
    }
#endif

// MARK: - Extensions

extension Double {
    fileprivate func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var htmlContent: String =
        "<h1>Lorem ipsum</h1><p>Lorem ipsum <b>dolor sit</b> amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur <span style=\"background-color:rgb(255,255,0);\">sadipscing elitr</span>, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.</p><ul><li>At vero eos et accusam et justo duo dolores et ea rebum.</li><li>Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.</li></ul><h1>Lorem ipsum</h1><p>Lorem ipsum <b>dolor sit</b> amet, consetetur \nsadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et \ndolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et\n justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea \ntakimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit \namet, consetetur <span style=\"background-color:rgb(255,255,0);\">sadipscing elitr</span>,\n sed diam nonumy eirmod tempor invidunt ut labore et dolore magna \naliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo \ndolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus \nest Lorem ipsum dolor sit amet.</p>"

    ScrollView {
        HTMLPreviewView(htmlContent: $htmlContent)
            .padding(.horizontal)
    }
}
