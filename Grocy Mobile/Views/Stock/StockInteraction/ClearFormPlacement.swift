//
//  ClearFormPlacement.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 28.11.26.
//

import SwiftUI

extension ToolbarItemPlacement {
    /// Where the stock interaction forms put their "Clear" button. On iOS it's the cancellation place, at the other end of the
    /// bar from the action. A Mac window puts the cancellation and primary places next to each other, so there it's a primary
    /// item of its own, kept apart from the actions by a fixed spacer.
    static var clearFormAction: ToolbarItemPlacement {
        #if os(macOS)
            .primaryAction
        #else
            .cancellationAction
        #endif
    }
}
