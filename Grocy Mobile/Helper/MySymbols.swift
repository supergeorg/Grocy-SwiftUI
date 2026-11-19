//
//  MySymbols.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 09.02.21.
//

import Foundation

nonisolated struct MySymbols {
    static let purchase = "cart"
    static let consume = "fork.knife"
    static let open = "envelope.open"
    static let transfer = "arrow.left.arrow.right"
    static let inventory = "list.bullet"
    static let stockJournal = "list.bullet.rectangle"
    static let addToShoppingList = "cart.fill.badge.plus"
    static let shoppingList = "cart.fill"
    static let masterData = "folder"
    static let settings = "gear"
    static let chores = "list.bullet.clipboard"
    static let batteries = "battery.25percent"
    static let equipment = "wrench.and.screwdriver"
    static let batteryCharge = "battery.100percent.bolt"
    static let batteryUsedIn = "powerplug"
    static let batteryChargeInterval = "arrow.triangle.2.circlepath"
    static let instructionManual = "book.pages"

    static let stockOverview = "archivebox"
    static let product = "shippingbox"
    static let quantityUnit = "scalemass"
    static let location = "location"
    static let store = "storefront"
    static let productGroup = "square.on.circle"
    static let recipe = "book"
    static let picture = "photo"
    static let picturePlaceholder = "photo.on.rectangle"
    static let gallery = "photo.on.rectangle.angled"
    static let importRecipe = "square.and.arrow.down"
    static let link = "link"
    static let steps = "list.number"
    /// A product or unit the recipe import found by a similar name, which the person should check.
    static let suggestedMatch = "sparkles"
    /// An imported ingredient the person excluded.
    static let notImported = "minus.circle"
    /// An ingredient whose product was found for sure.
    static let confirmedMatch = "checkmark.circle.fill"
    /// An ingredient that has no product yet.
    static let missingProduct = "exclamationmark.circle.fill"
    static let splitIngredient = "scissors"
    static let connectUnit = "arrow.left.arrow.right"
    static let user = "person"
    static let parentProduct = "rectangle.stack"

    static let amount = "number.circle"
    static let price = "banknote"
    static let spoiled = "trash.circle"
    static let doesntSpoil = "trash.slash.circle"
    static let description = "text.justifyleft"
    static let date = "calendar"
    static let energy = "flame"
    static let freezing = "thermometer.snowflake"
    static let thawing = "thermometer.sun"
    static let accumulate = "arrow.triangle.merge"
    static let tareWeight = "scalemass.fill"
    static let selfProduction = "house"
    static let name = "tag"

    static let logFile = "doc.plaintext"
    static let info = "info.circle"
    static let offline = "wifi.slash"
    static let api = "chevron.left.forwardslash.chevron.right"
    static let website = "network"
    static let unknown = "questionmark"
    static let timeout = "clock.arrow.circlepath"
    static let decimalPlaces = "00.square"
    static let hint = "questionmark.circle.fill"
    static let language = "flag"
    static let richText = "doc.richtext"

    static let new = "plus"
    static let edit = "square.and.pencil"
    static let delete = "trash"
    static let permissions = "lock"
    static let success = "checkmark"
    static let failure = "xmark"
    static let share = "square.and.arrow.up"
    static let cancel = "xmark.circle.fill"
    static let upload = "square.and.arrow.up.fill"
    static let save = "checkmark"
    /// Shown, animated, in place of an action's symbol while it runs (a toolbar item keeps an image, so it stays in iPhone Duo's vertical bar).
    static let progress = "progress.indicator"
    static let login = "key.fill"
    static let logout = "rectangle.portrait.and.arrow.right"
    static let reset = "arrow.counterclockwise"

    static let filter = "line.3.horizontal.decrease.circle"
    static let reload = "arrow.triangle.2.circlepath"
    static let search = "magnifyingglass"
    static let menuPick = "chevron.down.circle"
    static let dropdown = "chevron.down"
    static let done = "checkmark.circle"
    static let undone = "circle"
    static let clear = "clear"
    static let undo = "arrow.counterclockwise"
    static let timedRefresh = "clock.arrow.2.circlepath"
    static let sort = "arrow.up.arrow.down.square"
    static let sortForward = "arrow.up"
    static let sortReverse = "arrow.down"
    static let groupBy = "square.grid.2x2"
    static let sortCategory = "line.3.horizontal.decrease.circle"
    static let sortOrder = "arrow.up.arrow.down"
    static let active = "checkmark.circle.fill"
    static let warning = "exclamationmark.triangle.fill"
    static let error = "xmark.circle.fill"
    static let notSaved = "square.and.arrow.down.badge.clock"
    static let duplicate = "document.on.document"

    static let qrScan = "qrcode.viewfinder"
    static let barcodeScan = "barcode.viewfinder"
    static let barcode = "barcode"
    static let camera = "camera"
    static let torchOn = "bolt.circle"
    static let torchOff = "bolt.slash.circle"
    static let app = "app"
    static let devMode = "wrench.and.screwdriver"
    static let show = "eye"
    static let scanDate = "text.viewfinder"

    static let expiringSoon = "hourglass.bottomhalf.fill"
    static let overdue = "exclamationmark.triangle.fill"
    static let expired = "trash.fill"
    static let belowMinStock = "chart.bar.fill"
    static let soon = "clock.badge.exclamationmark.fill"
    static let today = "calendar.circle.fill"
    static let me = "person.fill"

    static let choreRescheduled = "clock.fill"
    static let choreTrackNext = "play.fill"
    static let choreSkipNext = "forward.fill"
    static let chorePeriodType = "repeat"
    static let choreDayOfMonth = "31.calendar"
    static let choreAssignmentType = "person.crop.circle.fill.badge.checkmark"
    static let choreRollover = "clock.arrow.trianglehead.counterclockwise.rotate.90"

    static let task = "checkmark.circle"
    static let tasks = "checklist"

    static let widgetNoData = "arrow.down.circle"
    static let widgetAllDone = "checkmark.circle.fill"
    static let widgetNoDueDate = "circle"

    static let darkMode = "moon.stars.fill"
    static let lightMode = "sun.horizon.fill"
    static let systemDarkMode = "circle.lefthalf.filled.inverse"
    static let dismissKeyboard = "keyboard.chevron.compact.down"
    static let htmlCode = "chevron.left.slash.chevron.right"
    static let preview = "eye"
    static let forward = "arrow.forward"

    // MARK: - Server & app info

    static let developer = "person.circle"
    static let serverURL = "safari"
    static let phpVersion = "chevron.left.forwardslash.chevron.right"
    static let database = "cylinder.split.1x2"
    static let serverOS = "server.rack"
    static let clientDevices = "ipad.and.iphone"
    static let demoServer = "server.rack"
    static let ownServer = "house"
    static let homeAssistant = "house"
    static let apiKey = "key"
    static let guide = "questionmark.circle"

    // MARK: - Settings

    static let iPhoneTabNavigation = "platter.filled.bottom.iphone"
    static let iPadTabNavigation = "sidebar.left"
    /// iPhone navigation styles: smart (agenda tab), own tabs, sidebar.
    static let smartNavigation = "sparkles.rectangle.stack"
    static let sidebarNavigation = "sidebar.left"
    static let chooseTabs = "rectangle.3.group"
    static let appleIntelligence = "apple.intelligence"
    static let tableColumn = "tablecells"
    static let sortNumber = "list.number"

    // MARK: - Recipes

    static let fulfilled = "checkmark.circle.fill"
    static let partiallyFulfilled = "exclamationmark.circle.fill"
    static let notFulfilled = "xmark.circle.fill"
    static let servings = "person.2"
    static let nestedRecipe = "arrow.turn.down.right"
    static let layoutList = "list.bullet"
    static let layoutGallery = "square.grid.2x2"
    static let viewOptions = "line.3.horizontal.decrease.circle"
    static let editPreparation = "pencil.and.scribble"
    static let fontSizeDecrease = "textformat.size.smaller"
    static let fontSizeIncrease = "textformat.size.larger"
    static let cooking = "frying.pan"
    static let miseEnPlace = "checklist"
    static let ingredientReady = "checkmark.circle.fill"
    static let ingredientNotReady = "circle"
    static let previousStep = "chevron.backward"
    static let nextStep = "chevron.forward"
    static let cookingFinished = "fork.knife.circle"

    // MARK: - Meal plan

    static let mealPlan = "menucard"
    static let mealPlanSection = "square.split.1x2"
    static let mealPlanNote = "note.text"
    static let sectionTime = "clock"
    static let previousWeek = "chevron.backward"
    static let nextWeek = "chevron.forward"
    static let copyDay = "document.on.document"
    static let moreActions = "ellipsis"
    static let dayMenu = "chevron.down"
    static let mealPlanPeriod = "calendar"

    // MARK: - Recipe preparation editor

    static let formatBold = "bold"
    static let formatItalic = "italic"
    static let formatUnderline = "underline"
    static let formatStrikethrough = "strikethrough"
    static let formatBulletList = "list.bullet"
    static let formatNumberedList = "list.number"
    static let formatAlignLeft = "text.alignleft"
    static let formatAlignCenter = "text.aligncenter"
    static let formatAlignRight = "text.alignright"
    static let formatJustify = "text.justify"
    static let formatIndentIncrease = "increase.indent"
    static let formatIndentDecrease = "decrease.indent"
    static let formatTextColor = "paintbrush.pointed"
    static let formatHighlightColor = "paint.bucket.classic"
    static let editorUndo = "arrow.uturn.left"
    static let editorRedo = "arrow.uturn.right"
    static let formatClear = "text.badge.xmark"

    // MARK: - Stock & shopping list

    static let household = "house"
    /// The agenda of everything due (chores, tasks, batteries).
    static let due = "calendar.badge.clock"
    /// Links from the agenda to the complete lists.
    static let allEntries = "square.grid.2x2"
    /// Collapsible section headers (rotated when expanded).
    static let disclosure = "chevron.right"

    static let stockEntry = "tag"
    static let transferFrom = "square.and.arrow.up"
    static let transferTo = "square.and.arrow.down"
    static let note = "square.and.pencil"
    static let exportToReminders = "checklist"

    // MARK: - Scanner

    static let scannerViewFinder = "camera.viewfinder"
    static let scannerCapture = "camera.circle"
    static let scannerPhotoLibrary = "photo.on.rectangle"
    static let scannerButtonBackground = "capsule.fill"
    static let quickScanPause = "pause.rectangle"

    // MARK: - Introduction

    static let serverConnection = "externaldrive.connected.to.line.below"
    static let serverProfiles = "icloud"
    static let householdManagement = "house.and.flag"
    static let whatsNew = "sparkles"
    static let thanks = "heart.fill"
    static let widgets = "widget.small"
}
