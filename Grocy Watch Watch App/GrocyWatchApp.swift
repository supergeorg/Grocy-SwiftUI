//
//  GrocyWatchApp.swift
//  Grocy Watch Watch App
//
//  Created by Georg Meißner on 25.11.26.
//

import SwiftUI

@main
struct GrocyWatchApp: App {
    @State private var store = WatchStore.shared

    init() {
        WatchStore.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
