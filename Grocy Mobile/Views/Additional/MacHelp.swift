//
//  MacHelp.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 28.11.26.
//

import SwiftUI

extension View {
    /// The help tag (tooltip) a Mac shows while the pointer rests on a control that shows only its icon, like the toolbar buttons.
    /// Pass the control's name. On iOS nothing is added: there, `help` becomes the VoiceOver hint, which would only repeat the
    /// name VoiceOver already reads. A help text that says more than the name (what the action does) belongs in `help(_:)`.
    func macHelp(_ text: LocalizedStringKey) -> some View {
        #if os(macOS)
            help(text)
        #else
            self
        #endif
    }

    /// The help tag of a control whose name isn't a fixed text, e.g. one that names a product.
    func macHelp(_ text: Text) -> some View {
        #if os(macOS)
            help(text)
        #else
            self
        #endif
    }
}
