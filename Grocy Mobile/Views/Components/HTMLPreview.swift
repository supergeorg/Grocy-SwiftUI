//
//  HTMLPreview.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 22.03.26.
//

import SwiftUI
import WebKit

struct HTMLPreviewView: View {
    @Binding var htmlContent: String
    @State private var page = WebPage()
    let blank = URL(string: "about:blank")!

    var body: some View {
        WebView(page)
            .onAppear {
                page.load(html: htmlContent, baseURL: blank)
            }
            .onChange(of: htmlContent) { _, newValue in
                page.load(html: newValue, baseURL: blank)
            }
    }
}
