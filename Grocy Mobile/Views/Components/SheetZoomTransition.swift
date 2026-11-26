//
//  SheetZoomTransition.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 26.11.26.
//

import SwiftUI

/// Sheets zoom out of the toolbar button that presents them, like the system's sheets on iOS 26
/// (`matchedTransitionSource` on the button, `.navigationTransition(.zoom)` on the sheet).
/// macOS pushes those screens instead, so both modifiers do nothing there.
extension View {
    /// Marks the button a sheet zooms out of.
    func sheetTransitionSource(id: some Hashable, in namespace: Namespace.ID) -> some View {
        #if os(iOS)
            matchedTransitionSource(id: id, in: namespace)
        #else
            self
        #endif
    }

    /// Lets the sheet's content zoom out of the button marked with `sheetTransitionSource(id:in:)`.
    /// Without an ID (e.g. a sheet opened from a row), the sheet slides in as usual.
    @ViewBuilder
    func sheetZoomTransition(sourceID: AnyHashable?, in namespace: Namespace.ID?) -> some View {
        #if os(iOS)
            if let sourceID, let namespace {
                navigationTransition(.zoom(sourceID: sourceID, in: namespace))
            } else {
                self
            }
        #else
            self
        #endif
    }
}
