//
//  Grocy_SwiftUIApp.swift
//  Shared
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI

@main
struct Grocy_SwiftUIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: "de"))
        }
        .commands {
            SidebarCommands()
            #if os(macOS)
//            AppCommands()
            #endif
        }
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
