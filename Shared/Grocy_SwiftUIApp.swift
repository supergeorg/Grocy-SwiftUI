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
    @State private var grocyVM: GrocyViewModel
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    @AppStorage("onboardingNeeded") var onboardingNeeded: Bool = true
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for:
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
                                                VolatileStock.self
            )
            let modelContext = ModelContext(modelContainer)
            _grocyVM = State(initialValue: GrocyViewModel(modelContext: modelContext))
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
