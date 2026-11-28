//
//  CookingTimerMetadata.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 28.11.26.
//

#if os(iOS)
    import AlarmKit

    /// What the Live Activity of a cooking timer shows besides the time. Compiled into the app and the widget
    /// extension, which draws the Live Activity, so both decode the same `AlarmAttributes`.
    nonisolated struct CookingTimerMetadata: AlarmMetadata {
        var recipeName: String
        /// The step the time is from, starting at 1.
        var stepNumber: Int?
    }
#endif
