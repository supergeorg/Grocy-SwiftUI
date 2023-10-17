//
//  Grocy_SwiftUIApp.swift
//  Shared
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftData
import SwiftUI

@main
struct Grocy_SwiftUIApp: App {
    @State private var grocyVM: GrocyViewModel/* = GrocyViewModel()*/
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    @AppStorage("onboardingNeeded") var onboardingNeeded: Bool = true
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for: MDLocation.self, MDStore.self)
            let modelContext = ModelContext(modelContainer)
            self._grocyVM = State(initialValue: GrocyViewModel(modelContext: modelContext))
        } catch {
            fatalError("Failed to create ModelContainer.")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if onboardingNeeded {
                OnboardingView()
                    .environment(\.locale, Locale(identifier: localizationKey))
            } else {
                if !isLoggedIn {
                    LoginView()
                        .environment(\.locale, Locale(identifier: localizationKey))
                        .environment(grocyVM)
                } else {
                    ContentView()
                        .environment(\.locale, Locale(identifier: localizationKey))
                        .environment(grocyVM)
                        .modelContainer(modelContainer)
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
            if !onboardingNeeded, isLoggedIn {
                SettingsView()
            }
        }
#endif
    }
}
