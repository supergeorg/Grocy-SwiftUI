//
//  Grocy_SwiftUIApp.swift
//  Shared
//
//  Created by Georg Meissner on 13.11.20.
//

import SwiftData
import SwiftUI

// MARK: - Deep Link State

@Observable
class DeepLinkManager {
    var pendingStockFilter: ProductStatus?

    func apply(deepLink: GrocyDeepLink) {
        if case .stock(let filter) = deepLink {
            pendingStockFilter = filter
        }
    }

    func consume() {
        pendingStockFilter = nil
    }
}

extension ModelContainer {
    static func deleteStore(at url: URL) throws {
        let fileManager = FileManager.default

        // Delete main store file
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }

        // Delete SQLite WAL and SHM files
        let walURL = url.deletingPathExtension().appendingPathExtension("store-wal")
        let shmURL = url.deletingPathExtension().appendingPathExtension("store-shm")

        if fileManager.fileExists(atPath: walURL.path) {
            try fileManager.removeItem(at: walURL)
        }
        if fileManager.fileExists(atPath: shmURL.path) {
            try fileManager.removeItem(at: shmURL)
        }
    }

    static func ensureStorePath() throws {
        let storeDirectory = sharedModelContainerURL().deletingLastPathComponent()
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: storeDirectory.path) {
            try fileManager.createDirectory(
                at: storeDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}

@main
struct Grocy_MobileApp: App {
    @State private var grocyVM: GrocyViewModel
    @State private var deepLinkManager = DeepLinkManager()

    @AppStorage("localizationKey") var localizationKey: String = "en"
    @AppStorage("onboardingNeeded") var onboardingNeeded: Bool = true
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("isDemoModus") var isDemoModus: Bool = false
    @AppStorage("selectedServerProfileID") private var selectedServerProfileID: UUID?

    // For legacy migration reasons
    @AppStorage("grocyServerURL") var grocyServerURL: String = ""
    @AppStorage("grocyAPIKey") var grocyAPIKey: String = ""
    @AppStorage("useHassIngress") var useHassIngress: Bool = false
    @AppStorage("hassToken") var hassToken: String = ""

    var modelContainer: ModelContainer
    let profileModelContainer: ModelContainer

    init() {
        // Main container schema (all data except ServerProfile and LoginCustomHeader)
        let mainSchema = Schema([
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
            MDTaskCategory.self,
            StockJournalEntry.self,
            GrocyUser.self,
            StockEntry.self,
            GrocyUserSettings.self,
            StockProductDetails.self,
            StockProduct.self,
            VolatileStock.self,
            Recipe.self,
            StockLocation.self,
            SystemConfig.self,
            RecipePos.self,
            RecipePosResolvedElement.self,
            RecipeFulfilment.self,
            MDChore.self,
            Chore.self,
            ChoreLogEntry.self,
            ChoreDetails.self,
            GrocyTask.self,
            RecipeNesting.self,
        ])

        // Profile container schema (ServerProfile and LoginCustomHeader with iCloud sync)
        let profileSchema = Schema([
            ServerProfile.self,
            LoginCustomHeader.self,
        ])

        let mainConfig = ModelConfiguration(
            schema: mainSchema,
            url: sharedModelContainerURL(),
            allowsSave: true,
            cloudKitDatabase: .none
        )
        let profileConfig = ModelConfiguration(
            schema: profileSchema,
            url: URL.applicationSupportDirectory.appending(component: "profiles.store"),
            allowsSave: true,
            cloudKitDatabase: isRunningOnSimulator() ? .none : .private("iCloud.georgappdev.Grocy")
        )

        // Initialize profile container
        do {
            profileModelContainer = try ModelContainer(for: profileSchema, migrationPlan: .none, configurations: profileConfig)
        } catch {
            // Reset profile store if there's a migration error
            ModelContainer.resetProfileStore()

            // Try creating the container again
            do {
                profileModelContainer = try ModelContainer(for: profileSchema, configurations: profileConfig)
            } catch {
                fatalError("Failed to create profile ModelContainer after reset: \(error)")
            }
            isLoggedIn = false
        }

        func initializeMainContainer(profileContainer: ModelContainer) throws -> (ModelContainer, GrocyViewModel) {
            try ModelContainer.ensureStorePath()
            let container = try ModelContainer(for: mainSchema, configurations: mainConfig)
            let modelContext = ModelContext(container)
            let vm = GrocyViewModel(modelContext: modelContext, profileModelContext: ModelContext(profileContainer))
            return (container, vm)
        }

        do {
            let (container, vm) = try initializeMainContainer(profileContainer: profileModelContainer)
            self.modelContainer = container
            self._grocyVM = State(initialValue: vm)
        } catch {
            // First attempt failed, try recovery
            let storeURL = sharedModelContainerURL()
            let nsError = error as NSError
            let isMigrationError = nsError.code == 134140 && nsError.domain == NSCocoaErrorDomain

            if isMigrationError {
                GrocyLogger.error("Data model migration error detected. The data model has changed and the store is incompatible. Deleting store at \(storeURL.path)")
            } else {
                GrocyLogger.error("Failed to create main ModelContainer: \(error). Attempting to delete store at \(storeURL.path)")
            }

            // Delete corrupted/incompatible store files
            try? ModelContainer.deleteStore(at: storeURL)

            // Retry after cleanup with fresh directory creation
            do {
                // Force clean directory creation
                let storeDirectory = storeURL.deletingLastPathComponent()
                try? FileManager.default.removeItem(at: storeDirectory)
                try ModelContainer.ensureStorePath()

                let (container, vm) = try initializeMainContainer(profileContainer: profileModelContainer)
                self.modelContainer = container
                self._grocyVM = State(initialValue: vm)
                GrocyLogger.info("Successfully recovered main ModelContainer after store deletion")
            } catch {
                // Last resort: reset everything and start fresh
                GrocyLogger.error("Failed to recover main ModelContainer, attempting full reset: \(error)")
                try? ModelContainer.deleteStore(at: storeURL)
                ModelContainer.resetProfileStore()

                do {
                    // Try one more time with clean slate
                    let (container, vm) = try initializeMainContainer(profileContainer: profileModelContainer)
                    self.modelContainer = container
                    self._grocyVM = State(initialValue: vm)
                    GrocyLogger.info("Successfully recovered main ModelContainer after full reset")
                } catch {
                    // Complete failure - this should not happen if the code is correct
                    fatalError("Failed to create main ModelContainer after all recovery attempts: \(error)")
                }
            }
        }

        // Do migration for old AppStorage based to profile
        let profileModelContext = ModelContext(profileModelContainer)
        var descriptor = FetchDescriptor<ServerProfile>()
        descriptor.fetchLimit = 0

        let numProfiles: Int = (try? profileModelContext.fetchCount(descriptor)) ?? 0
        if isLoggedIn && !isDemoModus && numProfiles == 0 && !grocyServerURL.isEmpty && !grocyAPIKey.isEmpty {
            let profile = ServerProfile(name: "", grocyServerURL: grocyServerURL, grocyAPIKey: grocyAPIKey, useHassIngress: useHassIngress, hassToken: hassToken)
            selectedServerProfileID = profile.id
            profileModelContext.insert(profile)
            let vm = grocyVM
            Task {
                await vm.setLoginModus()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            if onboardingNeeded {
                OnboardingView()
            } else {
                if !isLoggedIn {
                    NavigationStack {
                        LoginView()
                    }
                } else {
                    ContentView()
                        .environment(deepLinkManager)
                        .onOpenURL { url in
                            if let deepLink = GrocyDeepLink(url: url) {
                                deepLinkManager.apply(deepLink: deepLink)
                            }
                        }
                }
            }
        }
        .modelContainer(modelContainer)
        .modelContainer(profileModelContainer)
        .environment(grocyVM)
        .environment(\.profileModelContext, ModelContext(profileModelContainer))
        .environment(\.profileModelContainer, profileModelContainer)
        .environment(\.locale, Locale(identifier: localizationKey))
        .commands {
            SidebarCommands()
            //            #if os(macOS)
            //            AppCommands()
            //            #endif
        }
        #if os(macOS)
            Settings {
                if !onboardingNeeded, isLoggedIn {
                    NavigationStack {
                        SettingsView()
                    }
                    .modelContainer(modelContainer)
                    .modelContainer(profileModelContainer)
                    .environment(grocyVM)
                    .environment(\.profileModelContext, ModelContext(profileModelContainer))
                    .environment(\.profileModelContainer, profileModelContainer)
                    .environment(\.locale, Locale(identifier: localizationKey))
                }
            }
        #endif
    }
}

extension ModelContainer {
    static func resetStore() {
        let storeURL = sharedModelContainerURL()
        try? ModelContainer.deleteStore(at: storeURL)
    }

    static func resetProfileStore() {
        let storePath = URL.applicationSupportDirectory.appending(component: "profiles.store")
        try? FileManager.default.removeItem(at: storePath)
    }
}

func sharedModelContainerURL() -> URL {
    let appGroupID = "group.georgappdev.Grocy"
    guard let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
        let errorMsg = "Could not access shared app group container. App Groups entitlement might not be configured correctly. Expected identifier: \(appGroupID)"
        GrocyLogger.error(errorMsg)
        fatalError(errorMsg)
    }
    
    let appSupportDir = sharedContainerURL.appending(component: "Library/Application Support")
    let fileManager = FileManager.default
    
    // Ensure Application Support directory exists
    if !fileManager.fileExists(atPath: appSupportDir.path) {
        do {
            try fileManager.createDirectory(at: appSupportDir, withIntermediateDirectories: true, attributes: nil)
            GrocyLogger.info("Created Application Support directory at \(appSupportDir.path)")
        } catch {
            GrocyLogger.error("Failed to create Application Support directory: \(error)")
        }
    }
    
    return appSupportDir.appending(component: "default.store")
}
