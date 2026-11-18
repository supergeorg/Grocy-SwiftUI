//
//  EnvironmentKeys.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.11.25.
//

import SwiftData
import SwiftUI

struct ProfileModelContextKey: EnvironmentKey {
    static let defaultValue: ModelContext? = nil
}

struct ProfileModelContainerKey: EnvironmentKey {
    static let defaultValue: ModelContainer? = nil
}

extension EnvironmentValues {
    var profileModelContext: ModelContext? {
        get { self[ProfileModelContextKey.self] }
        set { self[ProfileModelContextKey.self] = newValue }
    }

    var profileModelContainer: ModelContainer? {
        get { self[ProfileModelContainerKey.self] }
        set { self[ProfileModelContainerKey.self] = newValue }
    }
}

func isRunningOnSimulator() -> Bool {
    #if targetEnvironment(simulator)
        return true
    #else
        return false
    #endif
}
