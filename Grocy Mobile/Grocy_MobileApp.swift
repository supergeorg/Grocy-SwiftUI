//
//  Grocy_SwiftUIApp.swift
//  Shared
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftData
import SwiftUI

@main
struct Grocy_MobileApp: App {
    @State private var grocyVM: GrocyViewModel
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    @AppStorage("onboardingNeeded") var onboardingNeeded: Bool = true
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    let modelContainer: ModelContainer
    
    init() {
        let schema = Schema([
            StockElement.self,
            ShoppingListItem.self,
            ShoppingListDescription.self,
            MDLocation.self,
            MDStore.self,
            MDQuantityUnit.self,
            MDQuantityUnitConversion.self,
            MDProductGroup.self,
            MDProduct.self,
            MDProductBarcode.self,
            StockJournalEntry.self,
            GrocyUser.self,
            StockEntry.self,
            GrocyUserSettings.self,
            StockProductDetails.self,
            StockProduct.self,
            VolatileStock.self,
            Recipe.self,
            StockLocation.self,
            SystemConfig.self
        ])
        
        let config = ModelConfiguration()
        do {
            modelContainer = try ModelContainer(for: schema, configurations: config)
            let modelContext = ModelContext(modelContainer)
            _grocyVM = State(initialValue: GrocyViewModel(modelContext: modelContext))
        } catch {
            // Reset store if there's a migration error
            ModelContainer.resetStore()
            
            // Try creating the container again
            do {
                modelContainer = try ModelContainer(for: schema, configurations: config)
                let modelContext = ModelContext(modelContainer)
                _grocyVM = State(initialValue: GrocyViewModel(modelContext: modelContext))
            } catch {
                fatalError("Failed to create ModelContainer after reset: \(error)")
            }
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
                    .environment(grocyVM)
                    .modelContainer(modelContainer)
            }
        }
#endif
    }
}

extension ModelContainer {
    static func resetStore() {
        let storePath = URL.applicationSupportDirectory.appending(component: "default.store")
        try? FileManager.default.removeItem(at: storePath)
    }
}
