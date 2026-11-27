//
//  ListSheetSize.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 27.11.26.
//

import SwiftUI

extension View {
    /// The smallest size of a sheet that can show a list (a journal, a log, stock entries).
    /// A Mac sheet takes its content's size, and a list has none of its own, so without it the sheet shrinks to its toolbar.
    /// Forms size to their content and don't need it. On iOS the system sizes sheets, so it does nothing there.
    func listSheetSize() -> some View {
        #if os(macOS)
            frame(minWidth: Sizes.macOSSheetMinWidth, minHeight: Sizes.macOSSheetMinHeight)
        #else
            self
        #endif
    }

    /// The smallest size of a filter sheet, a short list of pickers: smaller than `listSheetSize()`, for the same reason.
    func filterSheetSize() -> some View {
        #if os(macOS)
            frame(minWidth: Sizes.macOSFilterSheetMinWidth, minHeight: Sizes.macOSFilterSheetMinHeight)
        #else
            self
        #endif
    }
}
