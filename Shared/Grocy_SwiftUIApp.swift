//
//  Grocy_SwiftUIApp.swift
//  Shared
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftUI
import SwiftData

@main
struct Grocy_SwiftUIApp: App {
    @State private var grocyVM = GrocyViewModel()
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    @AppStorage("onboardingNeeded") var onboardingNeeded: Bool = true
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if onboardingNeeded {
                OnboardingView()
                    .environment(\.locale, Locale(identifier: localizationKey))
            } else {
                if !isLoggedIn {
                    LoginView()
                        .environment(\.locale, Locale(identifier: localizationKey))
                } else {
                    ContentView()
                        .environment(\.locale, Locale(identifier: localizationKey))
                        .environment(grocyVM)
                        .modelContainer(for: [
                                            MDLocation.self,
                                        ])
                }
            }
        }
        .commands {
            SidebarCommands()
//            #if os(macOS)
//            AppCommands()
//            #endif
        }
        #if os(macOS)
        Settings {
            if !onboardingNeeded && isLoggedIn {
                SettingsView()
            }
        }
        #endif
    }
}
