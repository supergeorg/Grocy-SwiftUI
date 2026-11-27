# AGENTS.md

Guidance for AI coding agents working on **Grocy Mobile**. It covers the project's structure, its architecture, and the conventions to follow.

## Project Overview

Grocy Mobile is a native SwiftUI client for [Grocy](https://grocy.info), a self-hosted app for managing groceries and the household. The app can't run without a server. It talks to a Grocy instance (only version 4.7.1, see `GrocyAPP.supportedVersions`) over Grocy's REST API, or to one of the public demo servers. It can also reach Grocy through a Home Assistant Ingress.

- **Platforms:** iOS / iPadOS 26.5+ and macOS 26.5+ (Tahoe), built from one multiplatform target. All targets share these deployment targets (`IPHONEOS_`/`MACOSX_`/`XROS_DEPLOYMENT_TARGET = 26.5`; kept at the newest SDK of the CI runner's Xcode). visionOS is listed in `SUPPORTED_PLATFORMS` but isn't a focus.
- **Design language:** Liquid Glass (`.glassEffect(...)`, system toolbars, `ContentUnavailableView`). There's no fallback for older OS versions, and none should be added.
- **Language / toolchain:** Swift 6, latest Xcode. The app target uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_STRICT_CONCURRENCY = complete`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`, and `SWIFT_STRICT_MEMORY_SAFETY = YES`.
- **Bundle IDs:** `georgappdev.Grocy` (app), `georgappdev.Grocy.Grocy-Widget` (widget), `georgappdev.Grocy.watchkitapp` (Watch app). App Group: `group.georgappdev.Grocy`. iCloud container: `iCloud.georgappdev.Grocy`.
- **Version:** `MARKETING_VERSION` in the project (currently 4.0.0). Release notes go in `Changelogs/Changelog_<version>.md`, in English and German.
- **Dependencies (SPM):** `InfomaniakRichHTMLEditor` (`swift-rich-html-editor`, up to next major from 3.3.1), used for editing recipe preparation HTML. Prefer Apple frameworks over adding new packages.

## Repository Layout

```
Grocy Mobile/                 App target (file-system synchronized group, so new files are added automatically)
  Grocy_MobileApp.swift       @main entry: ModelContainers, GrocyViewModel, deep links, scenes
  Localizable.xcstrings       String Catalog (source language: en, ~30 locales)
  InfoPlist.xcstrings         Permission prompts (NS…UsageDescription), translated like Localizable
  AppShortcuts.xcstrings      Siri phrases of `GrocyAppShortcuts` (placeholders `${applicationName}`, `${product}`)
  Model/                      API client, view model, SwiftData @Model types, sync
    GrocyAPI.swift            `GrocyAPI` protocol + `GrocyApi` URLSession implementation, entity enums
    GrocyViewModel.swift      Central @Observable state & actions (injected via environment)
    SwiftDataSync.swift       `SwiftDataSynchronizer`: diff/upsert API results into SwiftData
    APIError.swift            Unified error enum
    MasterData/ Stock/ ShoppingList/ Recipes/ Chores/ Tasks/ Batteries/ Equipment/ User/ System/ HomeAssistant/
    Preview/                  PreviewContainer + TestData/*.json (fixtures named after API endpoints)
  Views/                      Grouped by feature
    Navigation/               ContentView, PhoneTabNavigation, PhoneNavigationStyle (PhonePlace), AppTabNavigation, AppSidebarNavigation,
                              Navigation (NavigationItem router), GlobalSearchView, AccountView
    Due/                      The due agenda of the smart iPhone navigation (DueView, DueItemRowView)
    Stock/ ShoppingList/ Recipes/ Chores/ Tasks/ Batteries/ Equipment/ MasterData/MD*/ Settings/ Onboarding/ Admin/ Scanner/
    Components/               Reusable form controls (MyTextField, MyToggle, MyDoubleStepper, ProductField, ...) and FilterCapsuleBar
    Additional/               ServerProblemView, FlowLayout, ...
  Helper/                     Logger, symbols, formatters, decoding helpers, deep links, AI matcher, reminders
Grocy Widget/                 WidgetKit extension: stock, shopping list, chores and tasks widgets
Grocy Watch Watch App/        watchOS companion app: shopping list, tasks and chores, data from the iPhone
Grocy MobileTests/            Unit tests (currently XCTest)
Grocy MobileUITests/          UI tests (XCUIAutomation)
Changelogs/                   Release notes per version (Changelog_<version>.md, English + German)
Guides/<Topic>/               Feature and contributor guides (Home Assistant Ingress, Recipe Import, Translation)
Screenshots/ PrivacyPolicy/ Assets/   Non-code assets
```

The widget target compiles a few files from the app folder through membership exceptions: `DateFormatter.swift`, `Decoder.swift`, `MySymbols.swift`, `APIError.swift`, `SharedModel.swift`, `ProductStatus.swift`, `VolatileStockModel.swift`, `Assets.xcassets`, and `Localizable.xcstrings`. Keep these files free of app-only dependencies such as `GrocyViewModel` or SwiftUI views from the app target. Don't break them, or the widget stops building.

The Watch app target compiles `SharedModel.swift`, `Model/Watch/WatchSyncModel.swift` and `Localizable.xcstrings` from the app folder the same way. The same rules apply.

## Architecture

### Data flow

```
Grocy REST API ──► GrocyApi (URLSession, async/await)
                     │  decoded Codable @Model objects
                     ▼
               GrocyViewModel (@MainActor @Observable)
                     │  SwiftDataSynchronizer.sync*()
                     ▼
               SwiftData store (App Group container)
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
6. **Server reachability:** `grocyVM.connectionProblem` (`ConnectionProblem`, `Model/System/`) says why the server can't be used: offline, not reachable (also a proxy's 502–504) or an error answer. `requestData` reports each `db-changed-time` result (no checks in advance), and an `NWPathMonitor` reports the device's network. While there's a problem, `checkServerConnection()` runs every 30 seconds, when the network comes back and when the app becomes active, and then reloads what failed and what the views asked for meanwhile. `ServerStatusView` shows it unobtrusively, never as an alert: in the tab view's bottom accessory (`serverStatusAccessory`) or at the bottom of the sidebar (`serverStatusBar`, on iPhone with the sidebar navigation also on the pushed screens). Tapping it tries again.

### Persistence

- There are two `ModelContainer`s.
  - **Main store:** all Grocy data, stored at `sharedModelContainerURL()` in the App Group. Not synced to iCloud. The widgets don't open it (see Widgets below).
  - **Profile store:** `ServerProfile` and `LoginCustomHeader`, stored at `profiles.store` and synced with CloudKit (except on the simulator). It's exposed through custom environment keys `\.profileModelContext` and `\.profileModelContainer` (see `Helper/EnvironmentKeys.swift`).
- If the main store fails to migrate, it's deleted and rebuilt, because it's only a cache. Adding a new `@Model` type means registering it in the **main schema** in `Grocy_MobileApp.init`. If previews or tests need it, also add it to `PreviewContainer.modelTypes`.
- `GrocyViewModel` sets `modelContext.autosaveEnabled = false`. `SwiftDataSynchronizer` saves explicitly and rolls back on error.

### Navigation

- `NavigationItem` (in `Views/Navigation/Navigation.swift`) lists every top-level destination, and `Navigation` switches over it.
- `ContentView` chooses the navigation from the size class, the `phoneNavigationStyle` setting (`PhoneNavigationStyle`: `smart`, `tabs`, `sidebar`; iPhone) and `iPadTabNavigation` (iPad). macOS always uses the sidebar.
  - **iPhone (every width) and iPad in compact width:** the user picks the style in the app settings. `PhoneNavigationStyle.applies(in:)` decides where it applies; `ContentView` and the settings use it. On iPhone it applies in regular width too (the inner display of iPhone Duo), so opening or closing the device keeps the same navigation, its selected place and its pushed screens. `ContentView` keeps one `if` branch per navigation for the same reason. `PhoneTabNavigation` uses `.sidebarAdaptable`, so in regular width the tab bar can become a sidebar with the same places.
    - `smart` (default): `PhoneTabNavigation` with Stock, Shopping list, Recipes, Due and a search tab (`Tab(role: .search)`). `DueView` is one agenda (`DueItem`) with swipe actions: products that are expired, overdue, due today or due soon, or below their minimum stock amount (from the volatile stock, like the stock overview's filters), and chores, tasks and batteries that are overdue, due today or due soon. Each kind can be hidden (`DueKindToggles`, stored in `dueHiddenKinds`; all shown by default), in the due tab's menu and the app settings. Each section can be collapsed (`dueCollapsedSections`). Its badge counts expired, overdue and due today. The complete lists (chores, tasks, batteries, equipment) open from the settings button. Product rows are keyed by the stock element's ID, which changes with every stock sync; keying them by product makes SwiftUI compare a deleted element and crash.
    - `tabs`: `PhoneTabNavigation` with up to four places the user chooses in `PhoneTabsSettingsView` (stored in `phoneTabs`), plus search.
    - `sidebar`: `AppSidebarNavigation`, which collapses to the sidebar list.
    - At most five tabs, so the system "More" list is never needed. `PhonePlace` lists every place that can be a tab; places that aren't tabs are pushed (`phonePlaceDestinations()`) and listed on `AccountView`. Server feature flags hide places.
    - `GlobalSearchView` searches stock, products, recipes and master data by name or exact barcode. Quick Scan sits in the tab view's bottom accessory, only while the search tab is selected. The app never restores the search tab at launch, because selecting it activates the search field.
    - Settings and master data open from the settings button (its own toolbar group, `ToolbarSpacer`), through `AccountView`: Settings first (visible without scrolling), the places that aren't tabs, then the master data lists directly (`MasterDataLinks`, shared with `MasterDataView`; their destinations are registered at the tab's stack root by `accountNavigationDestinations()`, because registered on the pushed page they aren't found). Value-based routes; a sheet conflicts with the lists' pull-down search field.
    - Deep links select a tab, or push the place onto the due tab (chores, tasks) or the first tab when it isn't a tab.
  - **iPad in regular width:** `AppTabNavigation` or `AppSidebarNavigation`.
- List → detail navigation uses `NavigationLink(value:)` plus `.navigationDestination(for:)`.
- Creating an item uses a `.sheet` on iOS and `.navigationDestination(isPresented:)` on macOS, behind `#if os(iOS)`.
- Deep links (opened by the widgets) are `grocy://stock/filter/<ProductStatus>`, `grocy://shoppinglist[/list/<id>]`, `grocy://chores/filter/<ChoreStatus>` and `grocy://tasks/filter/<TaskStatus>`. Widgets build them with `WidgetDeepLink` (`SharedModel.swift`); the app parses them with `GrocyDeepLink` (`Helper/DeepLinkHandler.swift`) and hands them over through the `DeepLinkManager` environment object.

### Other subsystems

- **Home Assistant Ingress:** `Model/HomeAssistant/`. A WebSocket-based authenticator obtains the ingress session. See `Guides/Home Assistant Ingress/`.
- **Apple Intelligence:** `Helper/AICategoryMatcher.swift` is an `actor` built on `FoundationModels`. It matches free text such as product names to categories conforming to `Categorizable`. Its answers are guided: the model can only choose one of the given names (or decline with an extra option). `Model/MasterData/ProductPropertySuggester.swift` uses it to suggest a new product's location, product group and quantity unit, with the household's similar products as examples; `MDProductFormView` shows its progress with `AppleIntelligenceProgressRow`. Gate it with `AppleIntelligenceStatus.isAppleIntelligenceAvailable` and the `useAppleIntelligence` setting.
- **Scanning:** `Views/Scanner/` uses VisionKit (`CodeScannerView`, a `DataScannerViewController`) for barcode scanning; there is no other scanner. One-off scans (product field, barcodes, server QR codes) use `CodeScannerSheetView`. Quick Scan works only on iOS. Opened by a button (the iPhone search tab's bottom accessory), it's a sheet (`quickScanSheet(isPresented:)`); opened from a tab (iPad) or the sidebar (`NavigationItem.quickScan`), it's shown in place. Barcode lookups can use `externalBarcodeLookup`.
- **Reminders sync:** `Model/Reminders/`. `ReminderSync` holds the two-way rules (no EventKit, so they're unit-tested); `ReminderStore` applies them with EventKit. A shopping list, the tasks and the chores (`ReminderSyncTarget`) each sync with their own list in Reminders. Each reminder links to its Grocy object through its URL. Grocy decides names, notes and due dates; checking off and adding in Reminders come back (checking off a chore tracks it). Automatic syncs run after a reload of the data, on Reminders changes, every few minutes in the foreground and as a background app refresh task on iOS; the settings are in each area's settings page (`ReminderSyncSection`).
- **Recipe import (work in progress):** `Views/Recipes/Import/` (UI and the JSON-LD `RecipeParser`) and `Model/Recipes/Import/` (ingredient line parser, product/unit mapping, preparation HTML format) import schema.org/Recipe JSON-LD from websites as Grocy recipes. See `Guides/Recipe Import/RecipeImportGuide.md`, and update it when the import changes.
- **Batteries and equipment:** `Model/Batteries/` and `Model/Equipment/`, views in `Views/Batteries/` (overview with due filters, tracking, journal, battery details) and `Views/Equipment/` (list, details with the PDF manual via PDFKit, notes form). Battery due status is `BatteryStatus`. Non-picture files (PDF manuals) are fetched without `force_serve_as=picture`. Tracked times are sent as local `Y-m-d H:i:s`, the only format Grocy accepts.
- **User management:** `Views/Admin/` (list, form with picture and userfields, permission tree), reachable from the sidebar and on iPhone from the settings button; one's own profile is edited from the settings (`GrocyUserInfoView`). Grocy only lets admins read permissions, so `GrocyViewModel.checkCurrentUserIsAdmin()` reads the current user's own permissions to decide whether permission actions are shown; other permission checks are left to the server, whose error message the forms show. Per-user settings of other users and sessions aren't in Grocy's API.
- **Widgets:** `Grocy Widget/` bundles the stock, shopping list, chores and tasks widgets (`AppIntentTimelineProvider`s, also on the Lock Screen). They never open SwiftData. After each sync, `GrocyViewModel` writes small `Codable` summaries (`WidgetStockSummary`, `WidgetShoppingListSummary`, `WidgetDueSummary`) to the App Group's `UserDefaults` via `WidgetSharedStore` (`Model/SharedModel.swift`) and reloads the matching timeline. `deleteAllCachedData` clears them. The app's language override is shared too, so widgets use the same language.
- **Watch app:** `Grocy Watch Watch App/` never talks to the Grocy server. On iOS, `WatchSync` (`Model/Watch/WatchSync.swift`) sends a `WatchSnapshot` with the widgets' shopping list, tasks and chores summaries as the WatchConnectivity application context after each widget update and on logout. The watch keeps the last snapshot in a file and sends check-offs as `WatchAction`s with `transferUserInfo`, so they wait until the iPhone is reachable, and also with `sendMessage` while it's reachable (immediate, and `transferUserInfo` doesn't deliver between simulators). The iPhone carries out each action once with the app's login and lists the handled action IDs in the next snapshot, which is when the watch stops showing them as pending.

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
- **SF Symbols:** never hard-code symbol names in views. Use or add constants in `Helper/MySymbols.swift` (`MySymbols.delete`, `MySymbols.save`, …), named after their meaning rather than the symbol (e.g. `ownServer` vs. `homeAssistant`).
- **Colors:** use the asset catalog colors `Color(.GrocyColors.grocyRed)`, `grocyBlueBackground`, etc.
- **Spacing and sizes:** no ad-hoc numbers. Use the `Spacing` scale (`hairline` … `xLarge`) and the named `Sizes` (`minimumHitTarget` = 44 pt, …) in `Helper/Constants.swift`. Tap targets are at least 44 pt.
- **Platform differences:** use `#if os(iOS)` / `#if os(macOS)` inline. macOS-specific sizes live in `Helper/Constants.swift`.
- **Liquid Glass:** glass belongs to the navigation layer (toolbars, tab bar, bars floating above content), never to the content layer (list rows, cards). Use the system styles (`.buttonStyle(.glass)` / `.glassProminent`) instead of hand-made glass, and don't nest glass effects.
- **Settings:** structured like the system settings. On iOS, `SettingsView` is a list with the account on top (`SettingsAccountRow`, opening `SettingsAccountView` with the user, the server, reset cache and logout), then General (`SettingsAppView`), one page per area named like the area (Stock, Shopping list, …, hidden when the server turns the area off), then App log and About. On macOS, the `Settings` scene shows `MacSettingsView`: the same pages as panes of a `TabView` (one `Tab` with a `Label` per page, each in its own `NavigationStack` with `settingsDestinations()` and the fixed `Sizes.macOSSettingsWidth/Height`). The app log and About are windows of their own on macOS (`Window` scenes `AppWindow.appLog` in the Window menu, `AppWindow.about` from the app menu's "About Grocy Mobile", `AboutCommands`). A new settings page goes into both.
- **Quick filter capsules:** each overview's `…FilterActionsView` puts its `…FilterCapsuleView`s in a `FilterCapsuleBar` (horizontal scroll view with a `GlassEffectContainer`). Style capsules with `filterCapsuleStyle(tint:)`. Show the bar with `.floatingTopBar { … .padding(.vertical, Spacing.small) }` on the list or scroll view, on all platforms (also for other bars above an overview with a large title, like the meal plan's period switcher). On iOS it's an overlay plus a constant top `contentMargins` of the bar's height, not a `safeAreaBar` or `safeAreaInset`: a bar in the safe area below a large title feeds back into the title's collapse, so scrolling back to the top can leave the title stuck half collapsed and flickering, with the search field hidden. (On macOS it stays a `safeAreaBar`.) Don't put it in a `List` section: the row background draws a white box around the glass. Apply `.refreshable` **before** `.floatingTopBar`: the refresh action is an environment value, so applied after it, it reaches the bar's horizontal scroll view too, and the capsules get pull-to-refresh.
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
- Permission prompts live in `InfoPlist.xcstrings` (the English text is also the `INFOPLIST_KEY_…` build setting, keep both equal), and Siri phrases in `AppShortcuts.xcstrings`. Translate new entries there, at least into German.
- Prefer reusing existing keys ("Save", "Delete", "Cancel", "Name", "Required", …) over near-duplicates. German is the most complete translation. Contributors translate with the workflow in `Guides/Translation/TRANSLATION.md`.

### File headers & style

- Keep the standard Xcode file header (`//  File.swift`, `//  Grocy Mobile`, `//  Created by … on dd.MM.yy.`).
- Use 4-space indentation, `// MARK: -` sections in larger files, PascalCase types, and camelCase members. Avoid force-unwraps in new code.

### Formatting (swift-format)

The whole codebase is formatted with Apple's `swift-format` (ships with Xcode, `xcrun swift-format`). The configuration is `.swift-format` in the repository root (4 spaces, 160 columns, one argument per line once a call wraps). Don't change it without being asked.

**After every change, format the Swift files you touched, then lint them:**

```bash
xcrun swift-format format -i -p <changed .swift files>
xcrun swift-format lint -p <changed .swift files>
```

To format all changed files at once: `git diff --name-only --diff-filter=d HEAD -- '*.swift' | tr '\n' '\0' | xargs -0 xcrun swift-format format -i -p`. For the whole codebase: `xcrun swift-format format -i -r -p "Grocy Mobile" "Grocy Widget" "Grocy Watch Watch App" "Grocy MobileTests" "Grocy MobileUITests"`.

- Format before building, and build afterwards: some rules rewrite code (`FileScopedDeclarationPrivacy`, `NoAccessLevelOnExtensionDeclaration`, `OrderedImports`, `UseShorthandTypeNames`, …).
- Fix new lint warnings in code you wrote. The remaining warnings in existing code (`AlwaysUseLowerCamelCase` on names like `chinese_simplified` or snake_case API types, a few `ReplaceForEachWithForLoop`) can't be fixed automatically and are left alone; don't rename them as a side effect.
- Don't hand-format against the tool or add `// swift-format-ignore` without a reason in the comment.

## Building & Testing

- **CI:** `.github/workflows/ci.yml` runs on every pull request on macOS: the `Grocy MobileTests` unit tests on an iPhone simulator (integration suites skip themselves) and a swift-format check, which fails if `swift-format format` would change a file. Keep it green.

- Build and run through Xcode, using the `BuildProject` / `RunProject` tools when available. The scheme is `Grocy Mobile`. For local testing without your own server, use **Demo mode**, which connects to `https://demo.grocy.info`.
- Use `XcodeRefreshCodeIssuesInFile` for quick type-checking after edits, and `RenderPreview` to check views against the preview data.
- Unit tests in `Grocy MobileTests/Model/` use XCTest and check that the preview fixtures decode into SwiftData. **New tests should use Swift Testing** (`import Testing`, `@Test`, `#expect`). UI tests use XCUIAutomation.
- When adding a new entity, add a JSON fixture to `Model/Preview/TestData/`, named after the API path with `/` replaced by `__` (for example `objects__locations.json`), and load it in `PreviewContainer`.
- The test target is hosted by the app (`TEST_HOST`) and builds in Swift 5 mode **without** default MainActor isolation, so mark suites that touch `GrocyViewModel` or SwiftData `@MainActor`. Keep its deployment targets equal to the app's, or `@testable import Grocy_Mobile` fails to compile.

### Integration tests against a real Grocy server

Integration tests live in `Grocy MobileTests/Integration/` and run against a throwaway Grocy server, built in Docker from a local clone of [grocy/grocy](https://github.com/grocy/grocy) (default `../grocy`, override with `GROCY_SOURCE_DIR`), pinned to Grocy 4.7.1 (`GROCY_VERSION`; a missing clone is cloned at that tag). Details are in `TestServer/README.md`.

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

UI tests against the same server live in `Grocy MobileUITests/` (XCTest + XCUIAutomation; see `TestServer/README.md`). Subclass `GrocyUITestCase`, which provides the server gate, `createObject` fixtures (deleted after each test), `launchApp()`, `openMasterData(_:in:)`, platform-aware element helpers and `attachScreenshot`. Examples: `MDLocationUITests.swift` (one screen in depth), `MDMasterDataUITests.swift` (the same check across all master data types), `PhoneNavigationUITests.swift` (every place in the three iPhone navigation styles; `launchApp(phoneNavigationStyle:phoneTabs:)` pins the style). On iPhone, master data is reached through the settings button, not a tab.

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
- Run `swift-format` on every Swift file you changed before you finish (see Formatting above), so the formatting stays consistent.
- Look up new or unfamiliar Apple APIs (Liquid Glass, FoundationModels, iOS 27 SwiftUI changes) in the documentation instead of guessing.
- Check both platforms: code that compiles on iOS can fail on macOS (and the reverse) because of `UIKit`/`AppKit` APIs and `#if os(...)` branches.
