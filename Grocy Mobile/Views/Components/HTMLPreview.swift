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

struct HTMLPreviewView: View {
    @Binding var htmlContent: String
    @Environment(\.colorScheme) private var systemColorScheme

    var minHeight: CGFloat = 300
    var idealHeight: CGFloat = 500
    var showControlBar: Bool = true
    var minFontScale: Double = 0.5
    var maxFontScale: Double = 2.0

    @State private var page = WebPage()
    @State private var fontScale: Double = 1.0
    @State private var webColorScheme: WebColorScheme = .system

    private let blank = URL(string: "about:blank")!

    private var activeIsDark: Bool { isDark(for: webColorScheme) }

    private func isDark(for scheme: WebColorScheme) -> Bool {
        switch scheme {
        case .light: return false
        case .dark: return true
        case .system: return systemColorScheme == .dark
        }
    }

    private func preparedHTML(_ raw: String) -> String {
        let scheme = activeIsDark ? "dark" : "light"
        let injection = """
            <meta name="color-scheme" content="\(scheme)">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                html { font-size: 100%; }
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

    private func applyFontScale(_ scale: Double) {
        let js = "document.documentElement.style.fontSize = '\(Int(scale * 100))%';"
        Task { _ = try? await page.callJavaScript(js) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if showControlBar {
                controlBar
            }

            WebView(page)
                .frame(minHeight: minHeight, idealHeight: idealHeight)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .onAppear {
            page.load(html: preparedHTML(htmlContent), baseURL: blank)
        }
        .onChange(of: htmlContent) { _, newValue in
            page.load(html: preparedHTML(newValue), baseURL: blank)
        }
        .onChange(of: webColorScheme) { oldScheme, newScheme in
            if isDark(for: oldScheme) != isDark(for: newScheme) {
                page.load(html: preparedHTML(htmlContent), baseURL: blank)
            }
        }
        .onChange(of: systemColorScheme) { _, _ in
            guard webColorScheme == .system else { return }
            page.load(html: preparedHTML(htmlContent), baseURL: blank)
        }
        // Re-apply font scale once the page finishes loading.
        // This covers reloads triggered by color scheme changes,
        // content changes, and initial appearance.
        .onChange(of: page.isLoading) { _, isLoading in
            guard !isLoading else { return }
            applyFontScale(fontScale)
        }
        // Live updates while the page is already loaded (slider drag etc.)
        .onChange(of: fontScale) { _, newScale in
            guard !page.isLoading else { return }
            applyFontScale(newScale)
        }
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        VStack(spacing: 8) {
            // Line 1: Appearance picker + scale percentage
            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
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
                .padding(.vertical, 4)
            }

            // Line 2: Smaller → Slider → Larger
            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    Button {
                        fontScale = max(minFontScale, (fontScale - 0.1).rounded(toPlaces: 1))
                    } label: {
                        Image(systemName: "textformat.size.smaller")
                            .frame(width: 36, height: 36)
                    }
                    .glassEffect(.regular.interactive(), in: .circle)
                    .disabled(fontScale <= minFontScale)

                    Slider(value: $fontScale, in: minFontScale...maxFontScale, step: 0.1)

                    Button {
                        fontScale = min(maxFontScale, (fontScale + 0.1).rounded(toPlaces: 1))
                    } label: {
                        Image(systemName: "textformat.size.larger")
                            .frame(width: 36, height: 36)
                    }
                    .glassEffect(.regular.interactive(), in: .circle)
                    .disabled(fontScale >= maxFontScale)
                }
                .padding(.vertical, 4)
            }
        }
        .buttonStyle(.plain)
        .padding(.bottom, 8)
    }
}

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

    HTMLPreviewView(htmlContent: $htmlContent)
}
