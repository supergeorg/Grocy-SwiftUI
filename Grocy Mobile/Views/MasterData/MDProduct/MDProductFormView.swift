//
//  MDProductFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftData
import SwiftUI

enum MDProductFormPart: Hashable {
    case optional
    case location
    case dueDate
    case quantityUnit
    case amount
    case barcode
    case productPicture
}

enum ExternalBarcodeLookupState {
    case searching, success, notFound, error
}

struct MDProductFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(sort: \MDProductBarcode.id, order: .forward) var mdProductBarcodes: MDProductBarcodes
    @Query(filter: #Predicate<MDQuantityUnit> { $0.active }, sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(filter: #Predicate<MDProductGroup> { $0.active }, sort: \MDProductGroup.id, order: .forward) var mdProductGroups: MDProductGroups
    @Query(filter: #Predicate<MDStore> { $0.active }, sort: \MDStore.name, order: .forward) var mdStores: MDStores
    @Query(filter: #Predicate<MDLocation> { $0.active }, sort: \MDLocation.name, order: .forward) var mdLocations: MDLocations

    @Environment(\.dismiss) var dismiss
    @Environment(\.grocyFeatures) private var features

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil
    @State private var userfieldChanges = UserfieldChanges()

    /// Suggestions that started before the form opened, e.g. in the recipe import.
    private var suggester: ProductPropertySuggester?
    @State private var ownSuggester = ProductPropertySuggester()
    /// The values Apple Intelligence filled in, to disclose them while they're unchanged.
    @State private var appliedSuggestions: [ProductPropertySuggester.Step: Int] = [:]

    @Binding var createdProductID: Int?
    var createBarcode: Bool

    var existingProduct: MDProduct?
    @State private var product: MDProduct

    @AppStorage("useAppleIntelligence") var useAppleIntelligence: Bool = true

    @State private var queuedBarcode: String = ""
    @State private var foundExternalBarcode: ExternalBarcodeLookup?
    @State private var externalBarcodeState: ExternalBarcodeLookupState?
    @State private var barcodeLookupApplied: Bool = false

    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundProduct = mdProducts.first(where: { $0.name == product.name })
        return existingProduct == nil
            ? !(product.name.isEmpty || foundProduct != nil) : !(product.name.isEmpty || (foundProduct != nil && foundProduct!.id != product.id))
    }

    @State private var isBarcodeCorrect: Bool = true
    private func checkBarcodeCorrect() -> Bool {
        let foundBarcode = mdProductBarcodes.first(where: { $0.barcode == queuedBarcode })
        return (queuedBarcode.isEmpty || (foundBarcode == nil))
    }

    init(
        existingProduct: MDProduct? = nil,
        userSettings: GrocyUserSettings? = nil,
        productName: String? = nil,
        queuedBarcode: String? = nil,
        createBarcode: Bool = false,
        createdProductID: Binding<Int?> = .constant(nil),
        suggester: ProductPropertySuggester? = nil
    ) {
        _createdProductID = createdProductID
        self.suggester = suggester
        self.existingProduct = existingProduct
        self._queuedBarcode = State(initialValue: queuedBarcode ?? "")
        self.createBarcode = createBarcode
        self.product =
            existingProduct
            ?? MDProduct(
                name: productName ?? "",
                productGroupID: userSettings?.productPresetsProductGroupID != -1 ? userSettings?.productPresetsProductGroupID : nil,
                locationID: userSettings?.productPresetsLocationID ?? -1,
                quIDPurchase: userSettings?.productPresetsQuID ?? -1,
                quIDStock: userSettings?.productPresetsQuID ?? -1,
                quIDConsume: userSettings?.productPresetsQuID ?? -1,
                quIDPrice: userSettings?.productPresetsQuID ?? -1,
                defaultDueDays: userSettings?.productPresetsDefaultDueDays ?? 0,
                // Like Grocy's web form: new products take the label preset, which the server doesn't apply itself (#194).
                defaultStockLabelType: userSettings?.productPresetsDefaultStockLabelType ?? 0,
                treatOpenedAsOutOfStock: userSettings?.productPresetsTreatOpenedAsOutOfStock ?? false,
            )
    }

    private var currentQUPurchase: MDQuantityUnit? {
        return mdQuantityUnits.first(where: { $0.id == product.quIDPurchase })
    }
    private var currentQUStock: MDQuantityUnit? {
        return mdQuantityUnits.first(where: { $0.id == product.quIDStock })
    }

    private let dataToUpdate: [ObjectEntities] = [.products, .quantity_units, .locations, .shopping_locations, .product_barcodes, .product_groups, .userfields]
    private let additionalDataToUpdate: [AdditionalEntities] = [.system_info]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    private func finishForm() {
        // Not on disappear: that also happens when a part of the form is pushed
        ownSuggester.stop()
        self.dismiss()
    }

    /// An amount Grocy requires (its column isn't nullable), so it can't be emptied; an empty value shows Grocy's default.
    private func requiredAmount(_ keyPath: ReferenceWritableKeyPath<MDProduct, Double?>, default defaultValue: Double) -> Binding<Double> {
        Binding(
            get: { product[keyPath: keyPath] ?? defaultValue },
            set: { product[keyPath: keyPath] = $0 }
        )
    }

    private var isFormValid: Bool {
        !(product.name.isEmpty) && isNameCorrect && (product.locationID != -1) && (product.quIDStock != -1) && (product.quIDPurchase != -1)
            && (product.quIDConsume != -1) && (product.quIDPrice != -1) && isBarcodeCorrect
            && (product.quickConsumeAmount ?? 1) > 0 && (product.quickOpenAmount ?? 1) > 0 && (product.tareWeight ?? 0) >= 0
    }

    /// Grocy requires a location for every product. Without location tracking it can't be chosen, so the first one is used.
    private func useFirstLocationWithoutLocationTracking() {
        if !features.locationTracking, product.locationID == -1, let firstLocation = mdLocations.first {
            product.locationID = firstLocation.id
        }
    }

    private func saveProduct() async {
        useFirstLocationWithoutLocationTracking()
        if product.id == -1 {
            do {
                product.id = try grocyVM.findNextID(.products)
            } catch {
                GrocyLogger.error("Failed to get next ID: \(error)")
                return
            }
        }
        isProcessing = true
        isSuccessful = nil
        do {
            try product.modelContext?.save()
            if existingProduct == nil {
                _ = try await grocyVM.postMDObject(object: .products, content: product)
                try await grocyVM.saveUserfields(entity: ObjectEntities.products.rawValue, objectID: product.id, changes: userfieldChanges)
                await grocyVM.requestData(objects: [.products])
                createdProductID = product.id
                if createBarcode == true && !queuedBarcode.isEmpty {
                    do {
                        let newBarcode = MDProductBarcode(
                            id: try grocyVM.findNextID(.product_barcodes),
                            productID: product.id,
                            barcode: queuedBarcode
                        )
                        let _ = try await grocyVM.postMDObject(object: .product_barcodes, content: newBarcode)
                        GrocyLogger.info("Barcode add successful.")
                        await grocyVM.requestData(objects: [.product_barcodes])
                    } catch {
                        GrocyLogger.error("Barcode add failed. \(error)")
                    }
                }
                GrocyLogger.info("Product \(product.name) successful.")
                isSuccessful = true
            } else {
                try await grocyVM.putMDObjectWithID(object: .products, id: product.id, content: product)
                try await grocyVM.saveUserfields(entity: ObjectEntities.products.rawValue, objectID: product.id, changes: userfieldChanges)
                GrocyLogger.info("Product \(product.name) successful.")
                await grocyVM.requestData(objects: [.products])
                isSuccessful = true
            }
        } catch {
            GrocyLogger.error("Product \(product.name) failed. \(error)")
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
            isSuccessful = false
        }
        isProcessing = false
    }

    // MARK: - Apple Intelligence

    private var activeSuggester: ProductPropertySuggester {
        suggester ?? ownSuggester
    }

    /// The properties that are still empty, which Apple Intelligence can fill in.
    private var stepsToSuggest: Set<ProductPropertySuggester.Step> {
        var steps: Set<ProductPropertySuggester.Step> = []
        if features.locationTracking, product.locationID == -1 { steps.insert(.location) }
        if product.productGroupID == nil { steps.insert(.productGroup) }
        if product.quIDStock == -1 { steps.insert(.quantityUnit) }
        return steps
    }

    private func suggestWithAppleIntelligence() {
        activeSuggester.start(
            productName: product.name,
            locations: mdLocations,
            productGroups: mdProductGroups,
            quantityUnits: mdQuantityUnits,
            products: mdProducts,
            skipping: Set<ProductPropertySuggester.Step>([.location, .productGroup, .quantityUnit]).subtracting(stepsToSuggest)
        )
    }

    /// Fills in the suggestions that arrived, for properties that are still empty. Choices of the person stay as they are.
    private func applySuggestions() {
        let suggester = activeSuggester
        guard suggester.productName == product.name.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        let suggestions = suggester.suggestions
        if product.locationID == -1, let locationID = suggestions.locationID {
            product.locationID = locationID
            appliedSuggestions[.location] = locationID
        }
        if product.productGroupID == nil, let productGroupID = suggestions.productGroupID {
            product.productGroupID = productGroupID
            appliedSuggestions[.productGroup] = productGroupID
        }
        if product.quIDStock == -1, let quantityUnitID = suggestions.quantityUnitID {
            product.quIDStock = quantityUnitID
            if product.quIDPurchase == -1 { product.quIDPurchase = quantityUnitID }
            if product.quIDConsume == -1 { product.quIDConsume = quantityUnitID }
            if product.quIDPrice == -1 { product.quIDPrice = quantityUnitID }
            appliedSuggestions[.quantityUnit] = quantityUnitID
        }
    }

    /// The names of the filled in properties, e.g. "Kühlschrank, Gemüse and Piece".
    private var appliedSuggestionNames: String {
        var names: [String] = []
        if appliedSuggestions[.location] == product.locationID, let location = mdLocations.first(where: { $0.id == product.locationID }) {
            names.append(location.name)
        }
        if let productGroupID = product.productGroupID, appliedSuggestions[.productGroup] == productGroupID,
            let productGroup = mdProductGroups.first(where: { $0.id == productGroupID })
        {
            names.append(productGroup.name)
        }
        if appliedSuggestions[.quantityUnit] == product.quIDStock, let quantityUnit = mdQuantityUnits.first(where: { $0.id == product.quIDStock }) {
            names.append(quantityUnit.name)
        }
        return names.formatted(.list(type: .and))
    }

    private func stepName(_ step: ProductPropertySuggester.Step?) -> Text {
        switch step {
        case .location: Text("Default location")
        case .productGroup: Text("Product group")
        case .quantityUnit: Text("Quantity unit stock")
        case nil: Text(verbatim: "")
        }
    }

    @ViewBuilder
    private var appleIntelligenceSection: some View {
        let suggester = activeSuggester
        Section {
            if suggester.isRunning {
                AppleIntelligenceProgressRow(
                    title: "Filling in with Apple Intelligence",
                    detail: stepName(suggester.currentStep),
                    completed: suggester.completedSteps,
                    total: suggester.steps.count,
                    onStop: { suggester.stop() }
                )
            } else {
                Button(
                    action: suggestWithAppleIntelligence,
                    label: {
                        Label {
                            Text("Fill in with Apple Intelligence")
                        } icon: {
                            AppleIntelligenceSymbol()
                        }
                    }
                )
                .foregroundStyle(.primary)
                .disabled(product.name.isEmpty || stepsToSuggest.isEmpty)
            }
        } footer: {
            if !appliedSuggestionNames.isEmpty {
                Text("Suggested by Apple Intelligence: \(appliedSuggestionNames). Check them before saving.")
            } else if !suggester.isRunning, existingProduct == nil {
                Text("Suggests the location, product group and quantity unit from the name and your other products.")
            }
        }
    }

    var body: some View {
        List {
            MyTextField(
                textToEdit: $product.name,
                description: "Name",
                isCorrect: $isNameCorrect,
                leadingIcon: "tag",
                emptyMessage: "A name is required",
                errorMessage: "Name already exists"
            )
            .onChange(of: product.name) {
                isNameCorrect = checkNameCorrect()
            }

            if useAppleIntelligence && AppleIntelligenceStatus.isAppleIntelligenceAvailable {
                appleIntelligenceSection
            }

            if !queuedBarcode.isEmpty && existingProduct == nil {
                Section("Barcode") {
                    MyTextField(
                        textToEdit: $queuedBarcode,
                        description: "Barcode",
                        isCorrect: $isBarcodeCorrect,
                        leadingIcon: MySymbols.barcode,
                        errorMessage: "The barcode is invalid or already in use."
                    )
                    .onChange(of: queuedBarcode) {
                        isBarcodeCorrect = checkBarcodeCorrect()
                    }
                    .disabled(true)
                    if foundExternalBarcode == nil && (externalBarcodeState == nil || externalBarcodeState == .error) {
                        Button(
                            action: {
                                Task {
                                    barcodeLookupApplied = false
                                    externalBarcodeState = .searching
                                    do {
                                        foundExternalBarcode = try await grocyVM.externalBarcodeLookup(barcode: queuedBarcode)
                                        if foundExternalBarcode != nil {
                                            externalBarcodeState = .success
                                        } else {
                                            externalBarcodeState = .notFound
                                        }
                                    } catch {
                                        GrocyLogger.error("\(error)")
                                        externalBarcodeState = .error
                                    }
                                }
                            },
                            label: {
                                Label("External barcode lookup", systemImage: MySymbols.search)
                            }
                        )
                    }
                    if !barcodeLookupApplied {
                        switch externalBarcodeState {
                        case .searching:
                            ProgressView()
                                .progressViewStyle(.circular)
                        case .success:
                            if let foundExternalBarcode {
                                DisclosureGroup(
                                    content: {
                                        if let locationID = foundExternalBarcode.locationID {
                                            LabeledContent(
                                                content: {
                                                    Text(mdLocations.first(where: { $0.id == locationID })?.name ?? String(locationID))
                                                },
                                                label: {
                                                    Label("Default location", systemImage: MySymbols.location)
                                                }
                                            )
                                            .foregroundStyle(.primary)
                                        }
                                        if let quIDStock = foundExternalBarcode.quIDStock {
                                            LabeledContent(
                                                content: {
                                                    Text(mdQuantityUnits.first(where: { $0.id == quIDStock })?.name ?? String(quIDStock))
                                                },
                                                label: {
                                                    Label("Quantity unit stock", systemImage: MySymbols.quantityUnit)
                                                }
                                            )
                                            .foregroundStyle(.primary)
                                        }
                                        if let quIDPurchase = foundExternalBarcode.quIDPurchase {
                                            LabeledContent(
                                                content: {
                                                    Text(mdQuantityUnits.first(where: { $0.id == quIDPurchase })?.name ?? String(quIDPurchase))
                                                },
                                                label: {
                                                    Label("Default quantity unit purchase", systemImage: MySymbols.quantityUnit)
                                                }
                                            )
                                            .foregroundStyle(.primary)
                                        }
                                        if let imageURL = foundExternalBarcode.imageURL {
                                            AsyncImage(url: URL(string: imageURL))
                                        }
                                    },
                                    label: {
                                        Text(foundExternalBarcode.name)
                                    }
                                )
                                Button(
                                    action: {
                                        barcodeLookupApplied = true
                                        product.name = foundExternalBarcode.name
                                        product.locationID = foundExternalBarcode.locationID ?? product.locationID
                                        product.quIDPurchase = foundExternalBarcode.quIDPurchase ?? product.quIDPurchase
                                        product.quIDStock = foundExternalBarcode.quIDStock ?? product.quIDStock
                                        product.quIDPrice = foundExternalBarcode.quIDStock ?? product.quIDPrice
                                        product.quIDConsume = foundExternalBarcode.quIDStock ?? product.quIDConsume
                                    },
                                    label: {
                                        Label("Apply", systemImage: MySymbols.save)
                                    }
                                )
                            }
                        case .error:
                            Text("Error while executing the barcode lookup plugin").foregroundStyle(.red)
                        case .notFound:
                            Text("Nothing was found for the given barcode").foregroundStyle(.red)
                        default: EmptyView()
                        }
                    }
                }
            }

            Section {
                NavigationLink(
                    value: MDProductFormPart.optional,
                    label: {
                        MyLabelWithSubtitle(
                            title: "Optional properties",
                            subTitle:
                                "\(Text("Status")), \(Text("Parent product")), \(Text("Description")), \(Text("Product group")), \(Text("Energy")), \(Text("Picture"))",
                            systemImage: MySymbols.description
                        )
                    }
                )
                NavigationLink(
                    value: MDProductFormPart.location,
                    label: {
                        if features.locationTracking {
                            MyLabelWithSubtitle(
                                title: "Default location",
                                subTitle: "\(Text("Location")), \(Text("Store"))",
                                systemImage: MySymbols.location,
                                isProblem: product.locationID == -1
                            )
                        } else {
                            MyLabelWithSubtitle(title: "Default store", systemImage: MySymbols.store)
                        }
                    }
                )
                if features.dueDateTracking || features.openedTracking || features.freezing {
                    NavigationLink(
                        value: MDProductFormPart.dueDate,
                        label: {
                            MyLabelWithSubtitle(title: "Due date", subTitle: "\(Text("Type")), \(Text("Default due days"))", systemImage: MySymbols.date)
                        }
                    )
                }
                NavigationLink(
                    value: MDProductFormPart.quantityUnit,
                    label: {
                        MyLabelWithSubtitle(
                            title: "Quantity units",
                            subTitle: "\(Text("Stock")), \(Text("Purchase"))",
                            systemImage: MySymbols.quantityUnit,
                            isProblem: (product.quIDStock == -1 || product.quIDPurchase == -1 || product.quIDConsume == -1 || product.quIDPrice == -1)
                        )
                    }
                )
                NavigationLink(
                    value: MDProductFormPart.amount,
                    label: {
                        MyLabelWithSubtitle(
                            title: "Amount",
                            subTitle: "\(Text("Min. stock amount")), \(Text("Quick consume amount")), \(Text("Factor")), \(Text("Tare weight"))",
                            systemImage: MySymbols.amount
                        )
                    }
                )
                if queuedBarcode.isEmpty || createBarcode == false {
                    NavigationLink(
                        value: MDProductFormPart.barcode,
                        label: {
                            MyLabelWithSubtitle(
                                title: "Barcodes",
                                subTitle: existingProduct == nil ? "Product is not on server" : "",
                                systemImage: MySymbols.barcode,
                                hideSubtitle: existingProduct != nil
                            )
                        }
                    )
                    .disabled(existingProduct == nil)
                } else {
                    MyLabelWithSubtitle(title: "\(Text("Barcode")): \(queuedBarcode)", systemImage: MySymbols.barcode)
                }
            }
            UserfieldsSection(entity: ObjectEntities.products.rawValue, objectID: existingProduct?.id, changes: $userfieldChanges)
        }
        .task {
            await updateData()
            useFirstLocationWithoutLocationTracking()
            self.isNameCorrect = checkNameCorrect()
            // Suggestions that were ready before the form opened
            applySuggestions()
        }
        .onChange(of: activeSuggester.suggestions) {
            applySuggestions()
        }

        .navigationTitle(existingProduct == nil ? "Create product" : "Edit product")
        .toolbar(content: {
            if existingProduct == nil {
                ToolbarItem(
                    placement: .cancellationAction,
                    content: {
                        Button(
                            role: .cancel,
                            action: {
                                finishForm()
                            }
                        )
                        .keyboardShortcut(.cancelAction)
                    }
                )
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(
                    role: .confirm,
                    action: {
                        Task {
                            await saveProduct()
                        }
                    },
                    label: {
                        // Label style is left to the system, so the confirm button gets the standard Liquid Glass look.
                        // While it runs, the icon becomes an animated progress symbol. It stays an image: with a ProgressView as its icon,
                        // the item loses its icon and leaves iPhone Duo's vertical bar for a text-only button at the bottom.
                        Label("Save", systemImage: isProcessing ? MySymbols.progress : MySymbols.save)
                            .symbolEffect(.variableColor.iterative, isActive: isProcessing)
                    }
                )
                .disabled(!isFormValid || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        })
        .navigationDestination(
            for: MDProductFormPart.self,
            destination: { formPart in
                switch formPart {
                case .optional:
                    optionalPropertiesView
                case .location:
                    locationPropertiesView
                case .dueDate:
                    dueDatePropertiesView
                case .quantityUnit:
                    quantityUnitPropertiesView
                case .amount:
                    amountPropertiesView
                case .barcode:
                    barcodePropertiesView
                case .productPicture:
                    MDProductPictureFormView(existingProduct: existingProduct, pictureFileName: $product.pictureFileName)
                }
            }
        )
        .onChange(of: isSuccessful) {
            if isSuccessful == true {
                finishForm()
            }
        }
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }

    var optionalPropertiesView: some View {
        Form {
            // Active
            MyToggle(isOn: $product.active, description: "Active", descriptionInfo: nil, icon: MySymbols.active)

            // Parent Product
            ProductField(productID: $product.parentProductID, description: "Parent product", icon: MySymbols.parentProduct)

            // Product Description
            MyTextField(
                textToEdit: $product.mdProductDescription,
                description: "Description",
                isCorrect: Binding.constant(true),
                leadingIcon: MySymbols.description
            )

            // Product group
            Picker(
                selection: $product.productGroupID,
                label: Label {
                    Text("Product group")
                } icon: {
                    Image(systemName: MySymbols.productGroup).foregroundStyle(.primary)
                },
                content: {
                    Text("").tag(nil as Int?)
                    ForEach(mdProductGroups.filter({ $0.active }), id: \.id) { grocyProductGroup in
                        Text(grocyProductGroup.name).tag(grocyProductGroup.id as Int?)
                    }
                }
            )

            // Energy
            MyDoubleStepperOptional(
                amount: $product.calories,
                description: "\(Text("Energy")) (kcal)",
                descriptionInfo: "Per stock quantity unit",
                minAmount: 0,
                amountStep: 1,
                amountName: "kcal",
                systemImage: MySymbols.energy
            )

            // Don't show on stock overview
            MyToggle(
                isOn: $product.hideOnStockOverview,
                description: "Never show on stock overview",
                descriptionInfo:
                    "The stock overview page lists all products which are currently in-stock or below their min. stock amount - enable this to hide this product there always",
                icon: MySymbols.stockOverview
            )

            // Disable own stock
            MyToggle(
                isOn: $product.noOwnStock,
                description: "Disable own stock",
                descriptionInfo:
                    "When enabled, this product can't have own stock, means it will not be selectable on purchase (useful for parent products which are just used as a summary/total view of the child products)",
                icon: MySymbols.stockOverview
            )

            // Product should not be frozen
            if features.freezing {
                MyToggle(
                    isOn: $product.shouldNotBeFrozen,
                    description: "Should not be frozen",
                    descriptionInfo: "When enabled, on moving this product to a freezer location (so when freezing it), a warning will be shown",
                    icon: MySymbols.freezing
                )
            }

            // Stock entry labels, printed by the server
            if features.labelPrinter {
                Picker(
                    selection: Binding(
                        get: { product.defaultStockLabelType ?? 0 },
                        set: { product.defaultStockLabelType = $0 }
                    ),
                    label: Label("Default stock entry label", systemImage: MySymbols.stockLabel)
                        .foregroundStyle(.primary),
                    content: {
                        Text("No label").tag(0)
                        Text("Single label").tag(1)
                        Text("Label per unit").tag(2)
                    }
                )

                MyToggle(
                    isOn: $product.autoReprintStockLabel,
                    description: "Auto reprint stock entry label",
                    descriptionInfo: "When enabled, a new stock entry label is printed when a stock entry of this product is changed",
                    icon: MySymbols.printLabel
                )
            }

            // Product picture
            NavigationLink(
                value: MDProductFormPart.productPicture,
                label: {
                    MyLabelWithSubtitle(
                        title: "Product picture",
                        subTitle: (product.pictureFileName ?? "").isEmpty ? "No product picture" : "Product picture found",
                        systemImage: MySymbols.picture
                    )
                }
            )
            .disabled(existingProduct == nil)
        }
        .formStyle(.grouped)
        .navigationTitle("Optional properties")
    }

    var locationPropertiesView: some View {
        Form {
            if features.locationTracking {
                // Default Location - REQUIRED
                Picker(
                    selection: $product.locationID,
                    content: {
                        Text("").tag(-1)
                        ForEach(mdLocations.filter({ $0.active }), id: \.id) { grocyLocation in
                            Text(grocyLocation.name).tag(grocyLocation.id)
                        }
                    },
                    label: {
                        Label("Default location", systemImage: MySymbols.location)
                            .foregroundStyle(.primary)
                        if product.locationID == -1 {
                            Text("A location is required")
                                .foregroundStyle(.red)
                        }
                    }
                )
                // Default consume location
                Picker(
                    selection: $product.defaultConsumeLocationID,
                    content: {
                        Text("").tag(nil as Int?)
                        ForEach(mdLocations.filter({ $0.active }), id: \.id) { grocyLocation in
                            Text(grocyLocation.name).tag(grocyLocation.id as Int?)
                        }
                    },
                    label: {
                        Label {
                            HStack {
                                Text("Default consume location")
                                FieldDescription(description: "Stock entries at this location will be consumed first")
                            }
                        } icon: {
                            Image(systemName: MySymbols.location)
                                .foregroundStyle(.primary)
                        }
                    }
                )

                .onChange(of: product.defaultConsumeLocationID) {
                    // Like Grocy's web form: moving on open needs a default consume location.
                    if product.defaultConsumeLocationID == nil { product.moveOnOpen = false }
                }

                // Move on open
                if features.openedTracking, product.defaultConsumeLocationID != nil {
                    MyToggle(
                        isOn: $product.moveOnOpen,
                        description: "Move on open",
                        descriptionInfo:
                            "When enabled, on marking this product as opened, the corresponding amount will be moved to the default consume location",
                        icon: MySymbols.transfer
                    )
                }
            }

            // Default Store
            Picker(
                selection: $product.storeID,
                content: {
                    Text("").tag(nil as Int?)
                    ForEach(mdStores.filter({ $0.active }), id: \.id) { grocyStore in
                        Text(grocyStore.name).tag(grocyStore.id as Int?)
                    }
                },
                label: {
                    Label("Default store", systemImage: MySymbols.store)
                        .foregroundStyle(.primary)
                }
            )

            // The price type the purchase form starts with
            Picker(
                selection: $product.defaultPurchasePriceType,
                content: {
                    Text("Unspecified").tag(PurchasePriceType.unspecified)
                    Text("Unit price").tag(PurchasePriceType.unitPrice)
                    Text("Total price").tag(PurchasePriceType.totalPrice)
                },
                label: {
                    Label("Default purchase price type", systemImage: MySymbols.price)
                        .foregroundStyle(.primary)
                }
            )
        }
        .formStyle(.grouped)
        .navigationTitle(features.locationTracking ? LocalizedStringKey("Default location") : LocalizedStringKey("Default store"))
    }

    var dueDatePropertiesView: some View {
        Form {
            if features.dueDateTracking {
                VStack(alignment: .leading) {
                    Text("Due date type")
                        .font(.headline)
                    // Due Type, default best before
                    Picker(
                        "",
                        selection: $product.dueType,
                        content: {
                            Text("Best before date")
                                .tag(DueType.bestBefore)
                            Text("Expiration date")
                                .tag(DueType.expires)
                        }
                    )
                    .pickerStyle(.segmented)
                }

                // Default due days
                MyIntStepper(
                    amount: $product.defaultDueDays,
                    description: "Default due days",
                    helpText:
                        "For purchases this amount of days will be added to today for the due date suggestion (-1 means that this product will be never overdue)",
                    minAmount: -1,
                    amountName: product.defaultDueDays == 1 ? "Day" : "Days",
                    systemImage: MySymbols.date
                )
            }

            // Default due days afer opening
            if features.openedTracking {
                MyIntStepper(
                    amount: $product.defaultDueDaysAfterOpen,
                    description: "Default due days after opened",
                    helpText:
                        "When this product was marked as opened, the due date will be replaced by today + this amount of days (a value of 0 disables this)",
                    minAmount: 0,
                    amountName: product.defaultDueDaysAfterOpen == 1 ? "Day" : "Days",
                    systemImage: MySymbols.date
                )
            }

            // Default due days after freezing
            if features.freezing {
                MyIntStepper(
                    amount: $product.defaultDueDaysAfterFreezing,
                    description: "Default due days after freezing",
                    helpText:
                        "On moving this product to a freezer location (so when freezing it), the due date will be replaced by today + this amount of days",
                    minAmount: -1,
                    amountName: product.defaultDueDaysAfterFreezing == 1 ? "Day" : "Days",
                    errorMessage:
                        "This cannot be lower than \(Double(-1.0).formatted(.number.precision(.fractionLength(0...4)))) and needs to be a valid number with max. \(Int(0)) decimal places",
                    systemImage: MySymbols.freezing
                )

                // Default due days after thawing
                MyIntStepper(
                    amount: $product.defaultDueDaysAfterThawing,
                    description: "Default due days after thawing",
                    helpText:
                        "On moving this product from a freezer location (so when thawing it), the due date will be replaced by today + this amount of days",
                    minAmount: 0,
                    amountName: product.defaultDueDaysAfterThawing == 1 ? "Day" : "Days",
                    errorMessage:
                        "This cannot be lower than \(Double(0.0).formatted(.number.precision(.fractionLength(0...4)))) and needs to be a valid number with max. \(Int(0)) decimal places",
                    systemImage: MySymbols.thawing
                )
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Due date")
    }

    var quantityUnitPropertiesView: some View {
        Form {
            // Default Quantity Unit Stock - REQUIRED
            Picker(
                selection: $product.quIDStock,
                content: {
                    Text("").tag(-1)
                    ForEach(mdQuantityUnits.filter({ $0.active }), id: \.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id)
                    }
                },
                label: {
                    Label {
                        HStack {
                            Text("Quantity unit stock")
                            FieldDescription(description: "Quantity unit stock cannot be changed after first purchase")
                        }
                    } icon: {
                        Image(systemName: MySymbols.quantityUnit).foregroundStyle(.primary)
                    }

                    if product.quIDStock == -1 {
                        Text("A quantity unit is required")
                            .foregroundStyle(.red)
                    }
                }
            )
            // Like Grocy's web form: the other units follow the stock unit while they're unset or still the same as it (#199).
            .onChange(of: product.quIDStock) { oldQuIDStock, newQuIDStock in
                guard newQuIDStock != -1 else { return }
                if product.quIDPurchase == -1 || product.quIDPurchase == oldQuIDStock {
                    product.quIDPurchase = newQuIDStock
                }
                if product.quIDConsume == -1 || product.quIDConsume == oldQuIDStock {
                    product.quIDConsume = newQuIDStock
                }
                if product.quIDPrice == -1 || product.quIDPrice == oldQuIDStock {
                    product.quIDPrice = newQuIDStock
                }
            }

            // Default Quantity Unit Purchase - REQUIRED
            Picker(
                selection: $product.quIDPurchase,
                content: {
                    Text("")
                        .tag(-1)
                    ForEach(mdQuantityUnits.filter({ $0.active }), id: \.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name)
                            .tag(grocyQuantityUnit.id)
                    }
                },
                label: {
                    Label {
                        HStack {
                            Text("Default quantity unit purchase")
                            FieldDescription(description: "This is the default quantity unit used when adding this product to the shopping list")
                        }
                    } icon: {
                        Image(systemName: MySymbols.quantityUnit).foregroundStyle(.primary)
                    }
                    if product.quIDPurchase == -1 {
                        Text("A quantity unit is required")
                            .foregroundStyle(.red)
                    }
                }
            )

            // Default Quantity Unit Consume - REQUIRED
            Picker(
                selection: $product.quIDConsume,
                content: {
                    Text("")
                        .tag(-1)
                    ForEach(mdQuantityUnits.filter({ $0.active }), id: \.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name)
                            .tag(grocyQuantityUnit.id)
                    }
                },
                label: {
                    Label {
                        HStack {
                            Text("Default quantity unit consume")
                            FieldDescription(description: "This is the default quantity unit used when consuming this product")
                        }
                    } icon: {
                        Image(systemName: MySymbols.quantityUnit).foregroundStyle(.primary)
                    }
                    if product.quIDConsume == -1 {
                        Text("A quantity unit is required")
                            .foregroundStyle(.red)
                    }
                }
            )

            // Default Quantity Unit Price - REQUIRED
            Picker(
                selection: $product.quIDPrice,
                content: {
                    Text("")
                        .tag(-1)
                    ForEach(mdQuantityUnits.filter({ $0.active }), id: \.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name)
                            .tag(grocyQuantityUnit.id)
                    }
                },
                label: {
                    Label {
                        HStack {
                            Text("Quantity unit for prices")
                            FieldDescription(description: "When displaying prices for this product, they will be related to this quantity unit")
                        }
                    } icon: {
                        Image(systemName: MySymbols.quantityUnit).foregroundStyle(.primary)
                    }
                    if product.quIDPrice == -1 {
                        Text("A quantity unit is required")
                            .foregroundStyle(.red)
                    }

                }
            )

        }
        .formStyle(.grouped)
        .navigationTitle("Quantity units")
    }

    var amountPropertiesView: some View {
        Form {
            // Min Stock amount
            MyDoubleStepper(
                amount: $product.minStockAmount,
                description: "Minimum stock amount",
                minAmount: 0,
                amountStep: 1,
                amountName: currentQUStock?.name ?? "QU",
                systemImage: MySymbols.amount
            )

            // Accumulate sub products min stock amount
            MyToggle(
                isOn: $product.cumulateMinStockAmountOfSubProducts,
                description: "Accumulate sub products min. stock amount",
                descriptionInfo:
                    "If enabled, the min. stock amount of sub products will be accumulated into this product, means the sub product will never be \"missing\", only this product",
                icon: MySymbols.accumulate
            )

            // Treat opened as out of stock
            if features.openedTracking {
                MyToggle(
                    isOn: $product.treatOpenedAsOutOfStock,
                    description: "Treat opened as out of stock",
                    descriptionInfo: "When enabled, opened items will be counted as missing for calculating if this product is below its minimum stock amount",
                    icon: MySymbols.stockOverview
                )
            }

            // Quick consume amount
            MyDoubleStepper(
                amount: requiredAmount(\.quickConsumeAmount, default: 1),
                description: "Quick consume amount",
                descriptionInfo: "This amount is used for the \"quick consume button\" on the stock overview page (related to quantity unit stock)",
                minAmount: 0.0001,
                amountStep: 1.0,
                amountName: nil,
                systemImage: MySymbols.consume
            )

            // Can't be opened
            if features.openedTracking {
                MyToggle(isOn: $product.disableOpen, description: "Can't be opened", icon: MySymbols.open)
            }

            // Quick open amount
            if features.openedTracking && !product.disableOpen {
                MyDoubleStepper(
                    amount: requiredAmount(\.quickOpenAmount, default: 1),
                    description: "Quick open amount",
                    descriptionInfo: "This amount is used for the \"quick open button\" on the stock overview page (related to quantity unit stock)",
                    minAmount: 0.0001,
                    amountStep: 1.0,
                    amountName: nil,
                    systemImage: MySymbols.open
                )
            }

            // Tare weight
            Group {
                MyToggle(
                    isOn: $product.enableTareWeightHandling,
                    description: "Enable tare weight handling",
                    descriptionInfo:
                        "This is useful e.g. for flour in jars - on purchase/consume/inventory you always weigh the whole jar, the amount to be posted is then automatically calculated based on what is in stock and the tare weight defined below",
                    icon: MySymbols.tareWeight
                )

                if product.enableTareWeightHandling {
                    MyDoubleStepper(
                        amount: requiredAmount(\.tareWeight, default: 0),
                        description: "Tare weight",
                        minAmount: 0,
                        amountStep: 1,
                        amountName: currentQUStock?.name ?? "QU",
                        systemImage: MySymbols.tareWeight
                    )
                }
            }

            // Check stock fulfillment for recipes
            MyToggle(
                isOn: $product.notCheckStockFulfillmentForRecipes,
                description: "Disable stock fulfillment checking for this ingredient",
                descriptionInfo: "This will be used as the default setting when adding this product as a recipe ingredient",
                icon: MySymbols.recipe
            )
        }
        .formStyle(.grouped)
        .navigationTitle("Amounts")
    }

    var barcodePropertiesView: some View {
        Group {
            if existingProduct != nil {
                MDBarcodesView(product: product)
            }
        }
    }
}

#Preview("Create", traits: .previewData) {
    NavigationStack {
        MDProductFormView()
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        MDProductFormView(existingProduct: MDProduct(name: "Product", locationID: 2, quIDPurchase: 2, quIDStock: 2, quIDConsume: 2, quIDPrice: 2))
    }
}
