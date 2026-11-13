# AGENTS.md

Guidance for AI coding agents working on **Grocy Mobile**. It covers the project's structure, its architecture, and the conventions to follow.

## Project Overview

Grocy Mobile is a native SwiftUI client for [Grocy](https://grocy.info), a self-hosted app for managing groceries and the household. The app can't run without a server. It talks to a Grocy instance (version 4.4 to 4.7.1, see `GrocyAPP.supportedVersions`) over Grocy's REST API, or to one of the public demo servers. It can also reach Grocy through a Home Assistant Ingress.

- **Platforms:** iOS / iPadOS 26+ and macOS 26+ (Tahoe), built from one multiplatform target. visionOS is listed in `SUPPORTED_PLATFORMS` but isn't a focus.
- **Design language:** Liquid Glass (`.glassEffect(...)`, system toolbars, `ContentUnavailableView`). There's no fallback for older OS versions, and none should be added.
- **Language / toolchain:** Swift 6, latest Xcode. The app target uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_STRICT_CONCURRENCY = complete`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`, and `SWIFT_STRICT_MEMORY_SAFETY = YES`.
- **Bundle IDs:** `georgappdev.Grocy` (app), `georgappdev.Grocy.Grocy-Widget` (widget). App Group: `group.georgappdev.Grocy`. iCloud container: `iCloud.georgappdev.Grocy`.
- **Version:** `MARKETING_VERSION` in the project (currently 3.4.0). Release notes go in `Changelogs/Changelog_<version>.md`, in English and German.
- **Dependencies (SPM):** `InfomaniakRichHTMLEditor` (`swift-rich-html-editor`), used for editing recipe preparation HTML. Prefer Apple frameworks over adding new packages.

## Repository Layout

```
Grocy Mobile/                 App target (file-system synchronized group, so new files are added automatically)
  Grocy_MobileApp.swift       @main entry: ModelContainers, GrocyViewModel, deep links, scenes
  Localizable.xcstrings       String Catalog (source language: en, ~30 locales)
  Model/                      API client, view model, SwiftData @Model types, sync
    GrocyAPI.swift            `GrocyAPI` protocol + `GrocyApi` URLSession implementation, entity enums
    GrocyViewModel.swift      Central @Observable state & actions (injected via environment)
    SwiftDataSync.swift       `SwiftDataSynchronizer`: diff/upsert API results into SwiftData
    APIError.swift            Unified error enum
    MasterData/ Stock/ ShoppingList/ Recipes/ Chores/ Tasks/ User/ System/ HomeAssistant/
    Preview/                  PreviewContainer + TestData/*.json (fixtures named after API endpoints)
  Views/                      Grouped by feature
    Navigation/               ContentView, AppTabNavigation, AppSidebarNavigation, Navigation (NavigationItem router)
    Stock/ ShoppingList/ Recipes/ Chores/ Tasks/ MasterData/MD*/ Settings/ Onboarding/ Admin/ Scanner/
    Components/               Reusable form controls (MyTextField, MyToggle, MyDoubleStepper, ProductField, ...)
    Additional/               ServerProblemView, FlowLayout, ...
  Helper/                     Logger, symbols, formatters, decoding helpers, deep links, AI matcher, reminders
Grocy Widget/                 WidgetKit extension (reads the shared SwiftData store)
Grocy MobileTests/            Unit tests (currently XCTest)
Grocy MobileUITests/          UI tests (XCUIAutomation)
Changelogs/ Guides/ Screenshots/ PrivacyPolicy/ Assets/   Non-code assets and docs
```

The widget target compiles a few files from the app folder through membership exceptions: `DateFormatter.swift`, `Decoder.swift`, `MySymbols.swift`, `APIError.swift`, `SharedModel.swift`, `ProductStatus.swift`, `VolatileStockModel.swift`, and `Assets.xcassets`. Keep these files free of app-only dependencies such as `GrocyViewModel` or SwiftUI views from the app target. Don't break them, or the widget stops building.

## Architecture

### Data flow

```
Grocy REST API ──► GrocyApi (URLSession, async/await)
                     │  decoded Codable @Model objects
                     ▼
               GrocyViewModel (@MainActor @Observable)
                     │  SwiftDataSynchronizer.sync*()
                     ▼
               SwiftData store (App Group container, shared with widget)
                     │
                     ▼
               Views read via @Query / modelContext.fetch(FetchDescriptor)
               Views mutate via grocyVM.post/put/delete… then requestData()
```

1. **SwiftData is the offline cache and the views' source of truth.** Views mostly read through `@Query` or computed properties that call `modelContext.fetch(FetchDescriptor(predicate:sortBy:))`. The latter is used when the predicate depends on `@State`, such as a search string.
2. **`GrocyViewModel` is the single façade for server interaction.** It's created in `Grocy_MobileApp.init` and injected with `.environment(grocyVM)`. Views access it with `@Environment(GrocyViewModel.self) private var grocyVM`. It also holds in-memory mirrors of the data (`mdProducts`, `stock`, …), loading and failure sets, and picture caches.
3. **Refreshes are driven by timestamps.** `requestData(objects:additionalObjects:)` fetches `system/db-changed-time` first and only reloads entities whose stored timestamp differs. Each view declares the entities it needs:
   ```swift
   private let dataToUpdate: [ObjectEntities] = [.locations]
   private func updateData() async { await grocyVM.requestData(objects: dataToUpdate) }
   ```
   and calls it from `.task {}` and `.refreshable {}`.
   - `ObjectEntities` are the generic `/objects/{entity}` endpoints.
   - `AdditionalEntities` are the special endpoints: stock, volatile stock, system info and config, users, user settings, recipe fulfillments, chores.
4. **Writes go through the view model.** Use `postMDObject`, `putMDObjectWithID`, `deleteMDObject`, `postStockObject`, `shoppingListAction`, `executeChore`, and similar methods, then call `requestData` to resync. New object IDs come from `grocyVM.findNextID(_:)`.
5. **Errors:** failed loads are tracked in `grocyVM.failedToLoadObjects` and `failedToLoadAdditionalObjects`. Views show `ServerProblemView()` when one of their `dataToUpdate` entities failed.

### Persistence

- There are two `ModelContainer`s.
  - **Main store:** all Grocy data, stored at `sharedModelContainerURL()` in the App Group so the widget can read it. Not synced to iCloud.
  - **Profile store:** `ServerProfile` and `LoginCustomHeader`, stored at `profiles.store` and synced with CloudKit (except on the simulator). It's exposed through custom environment keys `\.profileModelContext` and `\.profileModelContainer` (see `Helper/EnvironmentKeys.swift`).
- If the main store fails to migrate, it's deleted and rebuilt, because it's only a cache. Adding a new `@Model` type means registering it in the **main schema** in `Grocy_MobileApp.init`. If previews or tests need it, also add it to `PreviewContainer.modelTypes`.
- `GrocyViewModel` sets `modelContext.autosaveEnabled = false`. `SwiftDataSynchronizer` saves explicitly and rolls back on error.

### Navigation

- `NavigationItem` (in `Views/Navigation/Navigation.swift`) lists every top-level destination, and `Navigation` switches over it.
- `ContentView` chooses between `AppTabNavigation` and `AppSidebarNavigation`, based on the size class and the `iPhoneTabNavigation` / `iPadTabNavigation` settings. macOS always uses the sidebar.
- List → detail navigation uses `NavigationLink(value:)` plus `.navigationDestination(for:)`.
- Creating an item uses a `.sheet` on iOS and `.navigationDestination(isPresented:)` on macOS, behind `#if os(iOS)`.
- Deep links use the `grocy://stock/filter/<ProductStatus>` scheme. They're parsed by `GrocyDeepLink` and handed over through the `DeepLinkManager` environment object.

### Other subsystems

- **Home Assistant Ingress:** `Model/HomeAssistant/`. A WebSocket-based authenticator obtains the ingress session. See `Guides/Home Assistant Ingress/`.
- **Apple Intelligence:** `Helper/AICategoryMatcher.swift` is an `actor` built on `FoundationModels`. It matches free text such as product names to categories conforming to `Categorizable`. Gate it with `AppleIntelligenceStatus.isAppleIntelligenceAvailable` and the `useAppleIntelligence` setting.
- **Scanning:** `Views/Scanner/` uses VisionKit and AVFoundation barcode scanning. The `*Legacy` variants are older implementations. Quick Scan mode works only on iOS. Barcode lookups can use `externalBarcodeLookup`.
- **Reminders sync:** `Helper/ReminderStore.swift` uses EventKit to mirror a shopping list into Reminders.
- **Recipe import (work in progress):** `Views/Recipes/Import/` parses schema.org/Recipe JSON-LD from web pages. See `RECIPE_IMPORT_GUIDE.md`.
- **Widget:** `Grocy Widget/` is an `AppIntentTimelineProvider` that reads `VolatileStock` from the shared store and refreshes every 15 minutes.

## Coding Conventions

### Models (`Model/`)

- API entities are SwiftData models: `@Model class X: Codable, Equatable, Identifiable`, with `@Attribute(.unique) var id: Int`.
- Name master-data types `MD<Thing>` (`MDLocation`, `MDProduct`, …) and declare a plural typealias: `typealias MDLocations = [MDLocation]`.
- Write explicit `CodingKeys` that map snake_case API keys. A property that collides with Swift or `CustomStringConvertible` gets a prefix, for example `mdLocationDescription = "description"`.
- Write a custom `init(from:)` wrapped in `do { … } catch { throw APIError.decodingError(error: error) }`. Grocy returns numbers and bools inconsistently (`1`, `"1"`, `true`), so **always** use the flexible helpers in `Helper/Decoder.swift`: `decodeFlexibleInt`, `decodeFlexibleBool`, `decodeFlexibleDouble`, and their `IfPresent` variants. Dates are parsed with `getDateFromString`.
- Provide `encode(to:)` and a memberwise `init` with defaults. New objects use `id: Int = -1`, which the form replaces with `findNextID`.
- Implement `static func ==` comparing all relevant fields. `SwiftDataSynchronizer` relies on it to detect changes.
- Request bodies that differ from the entity get their own small `Codable` structs, for example `ProductBuyModel`, `ChoreExecuteModel`, and `GrocyUserPOST`.

### API layer

- Add new endpoints to the `GrocyAPI` protocol and implement them in `GrocyApi`, using the private `call` / `callAPI` / `callEmptyResponse` helpers. Then expose a thin wrapper on `GrocyViewModel`. Views never call `grocyApi` directly.
- Throw `APIError` cases. Show `apiError.displayMessage` to the user.
- Use `async`/`await` only. Don't add new Combine code. The leftover `internal import Combine` and `cancellables` are legacy.

### Views

- One view per file, named `<Feature><Role>View`: `…sView` (list), `…RowView`, `…FormView`, `…FilterView`, `…FilterCapsuleView`, `…FilterActionsView`. Master-data views live in `Views/MasterData/MD<Thing>/`.
- A standard list screen (see `MDLocationsView`) has:
  - `@Environment(GrocyViewModel.self)` and `@Environment(\.modelContext)`
  - a computed fetch filtered by `searchString`, and a separate `fetchCount` for the empty state
  - `ContentUnavailableView` for "nothing defined" and `ContentUnavailableView.search` for "no results"
  - swipe-to-delete with a confirmation `.alert`
  - `.task` + `.refreshable` calling `updateData()`
  - `.searchable`, and a `ToolbarItemGroup(placement: .primaryAction)` "Create" button
- A standard form screen (see `MDLocationFormView`) has:
  - `init(existing…: X? = nil)` that seeds `@State var item = existing ?? X()`
  - live validation state (`isNameCorrect`) updated in `.onChange`
  - `isProcessing`, `isSuccessful: Bool?`, and `errorMessage` state, with `ErrorMessageView` at the top of the `Form`
  - `.formStyle(.grouped)`
  - toolbar items with `.cancellationAction` / `.confirmationAction`, `Button(role: .cancel/.confirm)`, and `.keyboardShortcut`
  - dismissal on success, plus `.sensoryFeedback(.success/.error, …)`
- Build forms from the shared components in `Views/Components/` (`MyTextField`, `MyTextEditor`, `MyToggle`, `MyDoubleStepper`, `MyIntStepper`, `ProductField`, `AmountSelectionView`, …) rather than raw controls, so styling and validation stay consistent.
- **SF Symbols:** never hard-code symbol names in views. Use or add constants in `Helper/MySymbols.swift` (`MySymbols.delete`, `MySymbols.save`, …).
- **Colors:** use the asset catalog colors `Color(.GrocyColors.grocyRed)`, `grocyBlueBackground`, etc.
- **Platform differences:** use `#if os(iOS)` / `#if os(macOS)` inline. macOS-specific sizes live in `Helper/Constants.swift`.
- **Previews:** every view gets a `#Preview(traits: .previewData)`, usually wrapped in a `NavigationStack`. The `.previewData` trait injects an in-memory `PreviewContainer` (seeded from `Model/Preview/TestData/*.json`) and a `GrocyViewModel`. Forms provide separate "Create" and "Edit" previews.

### State & settings

- Use `@State private var` for view state and `@Observable` (not `ObservableObject`) for shared state.
- Settings go in `@AppStorage("key")`. In `@Observable` classes, mark `@AppStorage` properties `@ObservationIgnored`. Some keys are read in several places (`isLoggedIn`, `isDemoModus`, `localizationKey`, `selectedServerProfileID`, …), so reuse the exact key strings.
- The app overrides the locale with `.environment(\.locale, Locale(identifier: localizationKey))`. It doesn't depend only on the system language.

### Concurrency

- Code is `@MainActor` by default. Mark pure helpers `nonisolated` when they're used from non-main contexts, as in `MySymbols` and the decoder extensions. Long-running independent services such as `AICategoryMatcher` are `actor`s.
- Start async work from views with `.task {}` or `Task { await … }` inside button actions.

### Logging

- Use `GrocyLogger.info/debug/warning/error(...)` (an OSLog wrapper with subsystem `georgappdev.Grocy`), not `print`. Logs appear in the in-app `LogView`. Successful and failed server actions are logged in the style `"Deleting location was successful."` / `"… failed. \(error)"`.

### Localization

- UI strings are English `LocalizedStringKey` literals, extracted automatically into `Grocy Mobile/Localizable.xcstrings`. Reusable components take `LocalizedStringKey` parameters.
- Prefer reusing existing keys ("Save", "Delete", "Cancel", "Name", "Required", …) over near-duplicates. German is the most complete translation. Contributors translate with the workflow in `Guides/Translation/TRANSLATION.md`.

### File headers & style

- Keep the standard Xcode file header (`//  File.swift`, `//  Grocy Mobile`, `//  Created by … on dd.MM.yy.`).
- Use 4-space indentation, `// MARK: -` sections in larger files, PascalCase types, and camelCase members. Avoid force-unwraps in new code.

## Building & Testing

- Build and run through Xcode, using the `BuildProject` / `RunProject` tools when available. The scheme is `Grocy Mobile`. For local testing without your own server, use **Demo mode**, which connects to `https://demo.grocy.info`.
- Use `XcodeRefreshCodeIssuesInFile` for quick type-checking after edits, and `RenderPreview` to check views against the preview data.
- Unit tests in `Grocy MobileTests/Model/` use XCTest and check that the preview fixtures decode into SwiftData. **New tests should use Swift Testing** (`import Testing`, `@Test`, `#expect`). UI tests use XCUIAutomation.
- When adding a new entity, add a JSON fixture to `Model/Preview/TestData/`, named after the API path with `/` replaced by `__` (for example `objects__locations.json`), and load it in `PreviewContainer`.
- The test target is hosted by the app (`TEST_HOST`) and builds in Swift 5 mode **without** default MainActor isolation, so mark suites that touch `GrocyViewModel` or SwiftData `@MainActor`. Keep its deployment targets equal to the app's, or `@testable import Grocy_Mobile` fails to compile.

### Integration tests against a real Grocy server

Integration tests live in `Grocy MobileTests/Integration/` and run against a throwaway Grocy server, built in Docker from a local clone of [grocy/grocy](https://github.com/grocy/grocy) (default `../grocy`, override with `GROCY_SOURCE_DIR`). Details are in `TestServer/README.md`.

- **Run:** `TestServer/run-integration-tests.sh [destination]` starts the server, runs the `Grocy MobileTests` target with the server configured, and stops the server again (`KEEP_SERVER=1` keeps it running). Docker Desktop must be running.
- **Server control:** `TestServer/grocy-test-server.sh start|stop|restart|status|logs`. It listens on `http://localhost:9290` with API key `grocy-mobile-integration-tests`. Every start creates an **empty database** (production mode, auth on); the only seeded data is what Grocy's migrations create (e.g. the location "Fridge").
- **Configuration:** tests read `GROCY_TEST_SERVER_URL` / `GROCY_TEST_API_KEY` from the environment. With `xcodebuild`, pass them as `TEST_RUNNER_GROCY_TEST_SERVER_URL=…`; in Xcode, add them to the scheme's test environment. Without the URL, integration suites are **skipped**, so the normal test run stays offline.
- **Shared helpers:** `GrocyTestServer.swift` provides the `.integration` tag, the `isConfigured` / `notConfiguredComment` gate, and `makeLoggedInViewModel()`, which creates a `GrocyViewModel` on empty in-memory stores (CloudKit disabled) and logs in via `checkServer`. Keep the returned `ModelContainer`s alive in the suite.

Adding a suite for another entity (use `MDLocationIntegrationTests.swift` as the template):

1. Create `Grocy MobileTests/Integration/<Thing>IntegrationTests.swift`, a `@MainActor struct` with
   `@Suite("…", .tags(.integration), .serialized, .enabled(if: GrocyTestServer.isConfigured, GrocyTestServer.notConfiguredComment))`
   and an `init() async throws` that calls `GrocyTestServer.makeLoggedInViewModel()`.
2. Test the way the views do it: write through `grocyVM` (`findNextID`, `postMDObject`, `putMDObjectWithID`, `deleteMDObject`, …), resync with `requestData(objects:)`, then assert on the server (`grocyVM.grocyApi.getObject…`) **and** on SwiftData (`container.mainContext.fetch`).
3. Before syncing after a write, clear the entity's cached timestamp (`grocyVM.timeStampsObjects[.<entity>] = nil`; see `syncLocations(forceReload:)`). Grocy's `db-changed-time` has one-second resolution, so writes in the same second as the last sync are otherwise skipped. This is a known app bug, pinned by `writeInSameSecondAsLastSyncIsPickedUp` with `withKnownIssue`. When it's fixed, that test fails; remove the `withKnownIssue` and the forced reset then.
4. Make tests independent of each other and of the server's contents: use unique names (`UUID`), create your own fixtures, and delete them with the `withCleanup` pattern (it also runs when a test fails). Create the entities a test depends on (e.g. a location and quantity unit before a product) inside that test.
5. Check the server's supported version still matches `GrocyAPP.supportedVersions` when updating the Grocy clone.

UI tests against the same server live in `Grocy MobileUITests/` (XCTest + XCUIAutomation; see `TestServer/README.md`). Subclass `GrocyUITestCase`, which provides the server gate, `createObject` fixtures (deleted after each test), `launchApp()`, `openMasterData(_:in:)`, platform-aware element helpers and `attachScreenshot`. Examples: `MDLocationUITests.swift` (one screen in depth), `MDMasterDataUITests.swift` (the same check across all master data types).

- The test passes `GROCY_UITEST_SERVER_URL` / `GROCY_UITEST_API_KEY` in the app's launch environment. That turns on `UITestConfiguration` (DEBUG only): in-memory stores and a direct login, so the installed app's data, login and iCloud profiles are never touched. Launch arguments like `-isLoggedIn YES -onboardingNeeded NO -localizationKey en` go to UserDefaults' argument domain and aren't persisted.
- Run them on macOS **and** an iOS simulator. On macOS, use `click()` instead of `tap()` (taps don't trigger navigation there), and read static text from `value` (iOS uses `label`).
- Attach screenshots (`XCTAttachment`, `.keepAlways`) of each screen, so the layout can be reviewed per platform from the result bundle (`xcrun xcresulttool export attachments`).

## Checklist: Adding a New Grocy Entity

1. Create the `@Model` in `Model/<Area>/`, following the model conventions above (flexible decoding, `CodingKeys`, `==`, typealias).
2. Add a case to `ObjectEntities` (or `AdditionalEntities`) in `GrocyAPI.swift`.
3. Add a property to `GrocyViewModel` and a `case` in `requestDataWithTimeStamp` that fetches and calls `swiftDataSync.syncPersistentCollection(...)`. Add it to `findNextID` and `deleteAllCachedData` if applicable.
4. Register the type in the main `Schema` in `Grocy_MobileApp.init` and in `PreviewContainer.modelTypes`, then add a fixture.
5. Add the views (`…sView`, `…RowView`, `…FormView`), a `NavigationItem` case if it's a top-level destination, and routes in `Navigation`, the sidebar, and the tab navigation.
6. Add symbols to `MySymbols`, and check that new strings appear in `Localizable.xcstrings`.

## Agent Ground Rules

- Keep changes scoped to the request. Don't reformat unrelated code or edit the `.xcuserstate` / `project.pbxproj` files unless that's needed.
- Look up new or unfamiliar Apple APIs (Liquid Glass, FoundationModels, iOS 27 SwiftUI changes) in the documentation instead of guessing.
- Check both platforms: code that compiles on iOS can fail on macOS (and the reverse) because of `UIKit`/`AppKit` APIs and `#if os(...)` branches.
