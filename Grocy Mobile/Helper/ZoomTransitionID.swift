//
//  ZoomTransitionID.swift
//  Grocy Mobile
//

import SwiftUI

/// The IDs of the toolbar buttons that sheets zoom out of (iOS 26 zoom transition): the button is marked with
/// `.matchedTransitionSource(id:in:)`, and the sheet's content with `.navigationTransition(.zoom(sourceID:in:))`.
/// As Liquid Glass sheets morph out of the button that opens them.
enum ZoomTransitionID {
    /// The create button (plus) of a list, which opens the form for a new object.
    static let add = "add"
}

#if os(iOS)
    extension View {
        /// For a sheet that several buttons open: zooms out of the toolbar button `sourceID` when `isZooming`,
        /// and slides up as usual otherwise.
        @ViewBuilder
        func zoomTransition(sourceID: String, in namespace: Namespace.ID, if isZooming: Bool) -> some View {
            if isZooming {
                navigationTransition(.zoom(sourceID: sourceID, in: namespace))
            } else {
                self
            }
        }
    }
#endif
