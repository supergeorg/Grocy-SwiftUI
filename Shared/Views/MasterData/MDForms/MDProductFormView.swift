//
//  MDProductFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

struct MDProductFormOFFView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @StateObject var offVM: OpenFoodFactsViewModel
    
    @Binding var name: String
    @State private var barcode: String
    
    init(barcode: String, name: Binding<String>) {
        self._offVM = StateObject(wrappedValue: OpenFoodFactsViewModel(barcode: barcode))
        self.barcode = barcode
        self._name = name
    }
    
    var productNames: [String: String] {
        if let offData = offVM.offData {
            let allProductNames = [
                "generic": offData.product.productName,
                "en": offData.product.productNameEn,
                "de": offData.product.productNameDe,
                "fr": offData.product.productNameFr,
                "pl": offData.product.productNamePl
            ]
            
            return allProductNames.compactMapValues({ $0 }).filter({ !$0.value.isEmpty })
        } else {
            return [:]
        }
    }
    
    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundProduct = grocyVM.mdProducts.first(where: {$0.name == name})
        return !(name.isEmpty || foundProduct != nil)
    }
    
    var body: some View {
        Group {
            VStack {
                if let imageLink = offVM.offData?.product.imageThumbURL, let imageURL = URL(string: imageLink) {
                    AsyncImage(url: imageURL, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .background(Color.white)
                    }, placeholder: {
                        ProgressView()
                    })
                    .frame(maxWidth: 150.0, maxHeight: 150.0)
                }
                MyTextField(textToEdit: Binding.constant(barcode), description: "Barcode", isCorrect: Binding.constant(true), leadingIcon: MySymbols.barcode)
                    .disabled(true)
            }
            
            if productNames.isEmpty {
                MyTextField(textToEdit: $name, description: "Product name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "A name is required", errorMessage: "Name already exists")
                    .onChange(of: name) {
                        isNameCorrect = checkNameCorrect()
                    }
            } else {
                Picker(selection: $name, content: {
                    ForEach(productNames.sorted(by: >), id: \.key) { key, value in
                        Text("\(value) (\(key))").tag(value)
                    }
                }, label: {
                    HStack{
                        Image(systemName: "tag")
                        VStack(alignment: .leading){
                            Text("Product name")
                            if name.isEmpty {
                                Text("A name is required")
                                    .font(.caption)
                                    .foregroundStyle(Color.red)
                            } else if !isNameCorrect {
                                Text("Name already exists")
                                    .font(.caption)
                                    .foregroundStyle(Color.red)
                            }
                        }
                    }
                })
                .onChange(of: name) {
                    isNameCorrect = checkNameCorrect()
                }
            }
        }
    }
}

struct MDProductFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("devMode") private var devMode: Bool = false
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var name: String = "" // REQUIRED
    @State private var active: Bool = true
    @State private var parentProductID: Int?
    @State private var mdProductDescription: String = ""
    @State private var pictureFileName: String?
    
    @State private var locationID: Int? // REQUIRED
    @State private var defaultConsumeLocationID: Int?
    @State private var moveOnOpen: Bool = false
    @State private var storeID: Int?
    @State private var minStockAmount: Double = 0.0
    @State private var cumulateMinStockAmountOfSubProducts: Bool = false
    @State private var dueType: DueType = DueType.bestBefore
    @State private var defaultDueDays: Int = 0
    @State private var defaultDueDaysAfterOpen: Int = 0
    @State private var productGroupID: Int?
    @State private var quIDStock: Int? // REQUIRED
    @State private var quIDPurchase: Int? // REQUIRED
    @State private var quIDConsume: Int? // REQUIRED
    @State private var quIDPrice: Int? // REQUIRED
    @State private var enableTareWeightHandling: Bool = false
    @State private var tareWeight: Double = 0.0
    @State private var notCheckStockFulfillmentForRecipes: Bool = false
    @State private var calories: Double = 0.0
    @State private var defaultDueDaysAfterFreezing: Int = 0
    @State private var defaultDueDaysAfterThawing: Int = 0
    @State private var quickConsumeAmount: Double = 1.0
    @State private var quickOpenAmount: Double = 1.0
    @State private var hideOnStockOverview: Bool = false
    @State private var noOwnStock: Bool = false
    @State private var treatOpenedAsOutOfStock: Bool = false
    @State private var shouldNotBeFrozen: Bool = false
    
    @State private var queuedBarcode: String = ""
    
    @State private var showDeleteAlert: Bool = false
    @State private var showOFFResult: Bool = false
    
    var isNewProduct: Bool
    var product: MDProduct?
    
    var openFoodFactsBarcode: String?
    
    @Binding var showAddProduct: Bool
    
    
    var isPopup: Bool = false
    
    var mdBarcodeReturn: Binding<MDProductBarcode?>?
    
    @State private var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundProduct = grocyVM.mdProducts.first(where: {$0.name == name})
        return isNewProduct ? !(name.isEmpty || foundProduct != nil) : !(name.isEmpty || (foundProduct != nil && foundProduct!.id != product!.id))
    }
    
    @State private var isBarcodeCorrect: Bool = true
    private func checkBarcodeCorrect() -> Bool {
        let foundBarcode = grocyVM.mdProductBarcodes.first(where: { $0.barcode == queuedBarcode })
        return (queuedBarcode.isEmpty || (foundBarcode == nil))
    }
    
    private var currentQUPurchase: MDQuantityUnit? {
        return grocyVM.mdQuantityUnits.first(where: {$0.id == quIDPurchase})
    }
    private var currentQUStock: MDQuantityUnit? {
        return grocyVM.mdQuantityUnits.first(where: {$0.id == quIDStock})
    }
    
    private func resetForm() {
        name = product?.name ?? ""
        
        active = product?.active ?? true
        parentProductID = product?.parentProductID
        mdProductDescription = product?.mdProductDescription ?? ""
        productGroupID = product?.productGroupID ?? grocyVM.userSettings?.productPresetsProductGroupID
        calories = product?.calories ?? 0.0
        hideOnStockOverview = product?.hideOnStockOverview ?? false
        noOwnStock = product?.noOwnStock ?? false
        shouldNotBeFrozen = product?.shouldNotBeFrozen ?? false
        treatOpenedAsOutOfStock = (product?.treatOpenedAsOutOfStock != nil ? (product?.treatOpenedAsOutOfStock ?? false) : (grocyVM.userSettings?.productPresetsTreatOpenedAsOutOfStock)) ?? false
        pictureFileName = product?.pictureFileName
        
        locationID = product?.locationID ?? grocyVM.userSettings?.productPresetsLocationID
        defaultConsumeLocationID = product?.defaultConsumeLocationID
        moveOnOpen = product?.moveOnOpen ?? false
        storeID = product?.storeID
        
        dueType = (product?.dueType == DueType.bestBefore.rawValue) ? DueType.bestBefore : DueType.expires
        defaultDueDays = product?.defaultBestBeforeDays ?? grocyVM.userSettings?.productPresetsDefaultDueDays ?? 0
        defaultDueDaysAfterOpen = product?.defaultBestBeforeDaysAfterOpen ?? 0
        defaultDueDaysAfterFreezing = product?.defaultBestBeforeDaysAfterThawing ?? 0
        defaultDueDaysAfterThawing = product?.defaultBestBeforeDaysAfterThawing ?? 0
        
        quIDStock = product?.quIDStock ?? grocyVM.userSettings?.productPresetsQuID
        quIDPurchase = product?.quIDPurchase ?? grocyVM.userSettings?.productPresetsQuID
        quIDConsume = product?.quIDConsume ?? grocyVM.userSettings?.productPresetsQuID
        quIDPrice = product?.quIDPrice ?? grocyVM.userSettings?.productPresetsQuID
        
        minStockAmount = product?.minStockAmount ?? 0.0
        cumulateMinStockAmountOfSubProducts = product?.cumulateMinStockAmountOfSubProducts ?? false
        quickConsumeAmount = product?.quickConsumeAmount ?? 1.0
        quickOpenAmount = product?.quickOpenAmount ?? 1.0
        enableTareWeightHandling = product?.enableTareWeightHandling ?? false
        tareWeight = product?.tareWeight ?? 0.0
        notCheckStockFulfillmentForRecipes = product?.notCheckStockFulfillmentForRecipes ?? false
        
        isNameCorrect = checkNameCorrect()
    }
    
    private let dataToUpdate: [ObjectEntities] = [.products, .quantity_units, .locations, .shopping_locations, .product_barcodes]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }
    
    private func finishForm() {
#if os(iOS)
        self.dismiss()
#elseif os(macOS)
        if isNewProduct {
            showAddProduct = false
        }
#endif
    }
    
    private var isFormValid: Bool {
        !(name.isEmpty) && isNameCorrect && (locationID != nil) && (quIDStock != nil) && (quIDPurchase != nil) && (quIDConsume != nil) && (quIDPrice != nil) && isBarcodeCorrect
    }
    
    private func saveProduct() async {
        if let locationID = locationID, let quIDPurchase = quIDPurchase, let quIDStock = quIDStock, let quIDConsume = quIDConsume, let quIDPrice = quIDPrice {
            let id = isNewProduct ? grocyVM.findNextID(.products) : product!.id
            let timeStamp = isNewProduct ? Date().iso8601withFractionalSeconds : product!.rowCreatedTimestamp
            let productPOST = MDProduct(
                id: id,
                name: name,
                mdProductDescription: mdProductDescription,
                productGroupID: productGroupID,
                active: active,
                locationID: locationID,
                storeID: storeID,
                quIDPurchase: quIDPurchase,
                quIDStock: quIDStock,
                quIDConsume: quIDConsume,
                quIDPrice: quIDPrice,
                minStockAmount: minStockAmount,
                defaultBestBeforeDays: defaultDueDays,
                defaultBestBeforeDaysAfterOpen: defaultDueDaysAfterOpen,
                defaultBestBeforeDaysAfterFreezing: defaultDueDaysAfterFreezing,
                defaultBestBeforeDaysAfterThawing: defaultDueDaysAfterThawing,
                pictureFileName: product?.pictureFileName,
                enableTareWeightHandling: enableTareWeightHandling,
                tareWeight: tareWeight,
                notCheckStockFulfillmentForRecipes: notCheckStockFulfillmentForRecipes,
                parentProductID: parentProductID,
                calories: calories,
                cumulateMinStockAmountOfSubProducts: cumulateMinStockAmountOfSubProducts,
                dueType: dueType.rawValue,
                quickConsumeAmount: quickConsumeAmount,
                quickOpenAmount: quickOpenAmount,
                hideOnStockOverview: hideOnStockOverview,
                shouldNotBeFrozen: shouldNotBeFrozen,
                treatOpenedAsOutOfStock: treatOpenedAsOutOfStock,
                noOwnStock: noOwnStock,
                defaultConsumeLocationID: defaultConsumeLocationID,
                moveOnOpen: defaultConsumeLocationID != nil ? moveOnOpen : nil,
                rowCreatedTimestamp: timeStamp
            )
            isProcessing = true
            if isNewProduct {
                do {
                    _ = try await grocyVM.postMDObject(object: .products, content: productPOST)
                    grocyVM.postLog("Product added successfully.", type: .info)
                    await grocyVM.requestData(objects: [.products])
                    if (openFoodFactsBarcode != nil) || (!queuedBarcode.isEmpty) {
                        let barcodePOST = MDProductBarcode(id: grocyVM.findNextID(.product_barcodes), productID: id, barcode: openFoodFactsBarcode ?? queuedBarcode, rowCreatedTimestamp: Date().iso8601withFractionalSeconds)
                        let _ = try await grocyVM.postMDObject(object: .product_barcodes, content: barcodePOST)
                        grocyVM.postLog("Barcode add successful.", type: .info)
                        await grocyVM.requestData(objects: [.product_barcodes])
                        mdBarcodeReturn?.wrappedValue = barcodePOST
                    }
                    finishForm()
                } catch {
                    grocyVM.postLog("Product add failed. \(error)", type: .error)
                }
            } else {
                do {
                    try await grocyVM.putMDObjectWithID(object: .products, id: id, content: productPOST)
                    grocyVM.postLog("Product edit successful.", type: .info)
                    await updateData()
                    finishForm()
                } catch {
                    grocyVM.postLog("Product edit failed. \(error)", type: .error)
                }
            }
        }
        isProcessing = false
    }
    
    var body: some View {
        content
            .navigationTitle(isNewProduct ? "Create product" : "Edit product")
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { Task { await saveProduct() } }, label: {
                        Label("Save product", systemImage: MySymbols.save)
                            .labelStyle(.titleAndIcon)
                    })
                    .disabled(!isNameCorrect || isProcessing || !isBarcodeCorrect)
                    .keyboardShortcut(.defaultAction)
                }
            })
#if os(iOS)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    if isNewProduct || isPopup {
                        Button("Cancel") {
                            finishForm()
                        }
                    }
                }
            })
#endif
    }
    
    var content: some View {
        List {
            if (isNewProduct || devMode) && openFoodFactsBarcode == nil {
                Button(action: {
                    showOFFResult.toggle()
                }, label: {Label("Open Food Facts", systemImage: MySymbols.barcodeScan)})
                .onChange(of: queuedBarcode) {
                    isBarcodeCorrect = checkBarcodeCorrect()
                }
#if os(iOS)
                .sheet(isPresented: $showOFFResult, content: {
                    NavigationView {
                        OpenFoodFactsFillProductView(productName: $name, queuedBarcode: $queuedBarcode)
                    }
                })
#elseif os(macOS)
                .popover(isPresented: $showOFFResult, content: {
                    OpenFoodFactsFillProductView(productName: $name, queuedBarcode: $queuedBarcode)
                        .frame(width: 500, height: 500)
                })
#endif
            }
            
#if os(macOS)
            Text(isNewProduct ? "Create product" : "Edit product")
                .font(.title)
                .bold()
                .padding(.bottom, 20.0)
#endif
            
            if let openFoodFactsBarcode = openFoodFactsBarcode {
                MDProductFormOFFView(barcode: openFoodFactsBarcode, name: $name)
                    .onChange(of: name) {
                        isNameCorrect = checkNameCorrect()
                    }
            } else {
                MyTextField(textToEdit: $name, description: "Product name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "A name is required", errorMessage: "Name already exists")
                    .onChange(of: name) {
                        isNameCorrect = checkNameCorrect()
                    }
            }
            
            if !queuedBarcode.isEmpty && isNewProduct {
                MyTextField(textToEdit: $queuedBarcode, description: "Barcode", isCorrect: $isBarcodeCorrect, leadingIcon: MySymbols.barcode, errorMessage: "The barcode is invalid or already in use.")
                    .onChange(of: queuedBarcode) {
                        isBarcodeCorrect = checkBarcodeCorrect()
                    }
            }
            
#if os(macOS)
            DisclosureGroup(content: {
                optionalPropertiesView
            }, label: {
                MyLabelWithSubtitle(title: "Optional properties", subTitle: "State, Parent product, Description, Product group, Energy, Picture", systemImage: MySymbols.description)
            })
            
            DisclosureGroup(content: {
                locationPropertiesView
            }, label: {
                MyLabelWithSubtitle(title: "Default locations", subTitle: "Location, Store", systemImage: MySymbols.location, isProblem: locationID == nil)
            })
            
            DisclosureGroup(content: {
                dueDatePropertiesView
            }, label: {
                MyLabelWithSubtitle(title: "Due date", subTitle: "Type, Default days; after opening, freezing, thawing", systemImage: MySymbols.date)
            })
            
            DisclosureGroup(content: {
                quantityUnitPropertiesView
            }, label: {
                MyLabelWithSubtitle(title: "Quantity units", subTitle: "Stock, Purchase", systemImage: MySymbols.quantityUnit, isProblem: (quIDStock == nil || quIDPurchase == nil || quIDConsume == nil || quIDPrice == nil))
            })
            
            DisclosureGroup(content: {
                amountPropertiesView
            }, label: {
                MyLabelWithSubtitle(title: "Amounts", subTitle: "Min. stock, Quick consume, Factor, Tare weight", systemImage: MySymbols.amount)
            })
            
            DisclosureGroup(content: {
                barcodePropertiesView
            }, label: {
                MyLabelWithSubtitle(title: "Barcodes", subTitle: isNewProduct ? "Product is not on server" : "", systemImage: MySymbols.barcode, hideSubtitle: !isNewProduct)
            })
            .disabled(isNewProduct)
#else
            Section {
                NavigationLink(
                    destination: optionalPropertiesView,
                    label: {
                        MyLabelWithSubtitle(title: "Optional properties", subTitle: "State, Parent product, Description, Product group, Energy, Picture", systemImage: MySymbols.description)
                    })
                
                NavigationLink(
                    destination: locationPropertiesView,
                    label: {
                        MyLabelWithSubtitle(title: "Default locations", subTitle: "Location, Store", systemImage: MySymbols.location, isProblem: locationID == nil)
                    })
                
                NavigationLink(
                    destination: dueDatePropertiesView,
                    label: {
                        MyLabelWithSubtitle(title: "Due date", subTitle: "Type, Default days; after opening, freezing, thawing", systemImage: MySymbols.date)
                    })
                
                NavigationLink(
                    destination: quantityUnitPropertiesView,
                    label: {
                        MyLabelWithSubtitle(title: "Quantity units", subTitle: "Stock, Purchase", systemImage: MySymbols.quantityUnit, isProblem: (quIDStock == nil || quIDPurchase == nil || quIDConsume == nil || quIDPrice == nil))
                    })
                
                NavigationLink(
                    destination: amountPropertiesView,
                    label: {
                        MyLabelWithSubtitle(title: "Amounts", subTitle: "Min. stock, Quick consume, Factor, Tare weight", systemImage: MySymbols.amount)
                    })
                
                NavigationLink(
                    destination: barcodePropertiesView,
                    label: {
                        MyLabelWithSubtitle(title: "Barcodes", subTitle: isNewProduct ? "Product is not on server" : "", systemImage: MySymbols.barcode, hideSubtitle: !isNewProduct)
                    })
                .disabled(isNewProduct)
            }
#endif
        }
        .task {
            if firstAppear {
                await grocyVM.requestData(objects: dataToUpdate, additionalObjects: [.system_info])
                resetForm()
                firstAppear = false
            }
        }
    }
    
    var optionalPropertiesView: some View {
        Form {
            // Active
            MyToggle(isOn: $active, description: "Active", descriptionInfo: nil, icon: "checkmark.circle")
            
            // Parent Product
            ProductField(productID: $parentProductID, description: "Parent product ")
            
            // Product Description
            MyTextField(textToEdit: $mdProductDescription, description: "Description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
            
            // Product group
            Picker(selection: $productGroupID, label: Label("Product group", systemImage: MySymbols.productGroup).foregroundStyle(.primary), content: {
                Text("").tag(nil as Int?)
                ForEach(grocyVM.mdProductGroups.filter({$0.active}), id:\.id) { grocyProductGroup in
                    Text(grocyProductGroup.name).tag(grocyProductGroup.id as Int?)
                }
            })
            
            // Energy
            MyDoubleStepper(amount: $calories, description: "Energy (kcal)", descriptionInfo: "Per stock quantity unit", minAmount: 0, amountStep: 1, amountName: "kcal", systemImage: MySymbols.energy)
            
            // Don't show on stock overview
            MyToggle(isOn: $hideOnStockOverview, description: "Never show on stock overview ", descriptionInfo: "The stock overview page lists all products which are currently in-stock or below their min. stock amount - enable this to hide this product there always", icon: MySymbols.stockOverview)
            
            // Disable own stock
            MyToggle(isOn: $noOwnStock, description: "Disable own stock", descriptionInfo: "When enabled, this product can't have own stock, means it will not be selectable on purchase (useful for parent products which are just used as a summary/total view of the child products)", icon: MySymbols.stockOverview)
            
            // Product should not be frozen
            MyToggle(isOn: $shouldNotBeFrozen, description: "Should not be frozen", descriptionInfo: "When enabled, on moving this product to a freezer location (so when freezing it), a warning will be shown", icon: MySymbols.freezing)
            
            
            // Product picture
#if os(iOS)
            NavigationLink(destination: MDProductPictureFormView(product: product, pictureFileName: $pictureFileName), label: {
                MyLabelWithSubtitle(title: "Product picture", subTitle: (product?.pictureFileName ?? "").isEmpty ? "No product picture" : "Product picture found", systemImage: MySymbols.picture)
            })
            .disabled(isNewProduct)
#elseif os(macOS)
            DisclosureGroup(content: {
                MDProductPictureFormView(product: product, pictureFileName: $pictureFileName)
            }, label: {
                MyLabelWithSubtitle(title: "Product picture", subTitle: (product?.pictureFileName ?? "").isEmpty ? "No product picture" : "Product picture found", systemImage: MySymbols.picture)
            })
            .disabled(isNewProduct)
#endif
        }
#if os(iOS)
        .navigationTitle("Optional properties")
#endif
    }
    var locationPropertiesView: some View {
        Form {
            // Default Location - REQUIRED
            Picker(selection: $locationID, label: MyLabelWithSubtitle(title: "Default location", subTitle: "A location is required", systemImage: MySymbols.location, isSubtitleProblem: true, hideSubtitle: locationID != nil), content: {
                ForEach(grocyVM.mdLocations.filter({$0.active}), id:\.id) { grocyLocation in
                    Text(grocyLocation.name).tag(grocyLocation.id as Int?)
                }
            })
            // Default consume location
            HStack {
                Picker(selection: $defaultConsumeLocationID, label: MyLabelWithSubtitle(title: "Default consume location", systemImage: MySymbols.location, hideSubtitle: true), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdLocations.filter({$0.active}), id:\.id) { grocyLocation in
                        Text(grocyLocation.name).tag(grocyLocation.id as Int?)
                    }
                })
                FieldDescription(description: "Stock entries at this location will be consumed first")
            }
            
            // Move on open
            if defaultConsumeLocationID != nil {
                MyToggle(isOn: $moveOnOpen, description: "Move on open", descriptionInfo: "When enabled, on marking this product as opened, the corresponding amount will be moved to the default consume location", icon: MySymbols.transfer)
            }
            
            // Default Store
            Picker(selection: $storeID, label: MyLabelWithSubtitle(title: "Default store", systemImage: MySymbols.store, hideSubtitle: true), content: {
                Text("").tag(nil as Int?)
                ForEach(grocyVM.mdStores.filter({$0.active}), id:\.id) { grocyStore in
                    Text(grocyStore.name).tag(grocyStore.id as Int?)
                }
            })
        }
#if os(iOS)
        .navigationTitle("Default locations")
#endif
    }
    var dueDatePropertiesView: some View {
        Form {
            VStack(alignment: .leading){
                Text("Due date type")
                    .font(.headline)
                // Due Type, default best before
                Picker("", selection: $dueType, content: {
                    Text("Best before date").tag(DueType.bestBefore)
                    Text("Expiration date").tag(DueType.expires)
                })
                .pickerStyle(.segmented)
            }
            
            // Default due days
            MyIntStepper(amount: $defaultDueDays, description: "Default due days", helpText: "For purchases this amount of days will be added to today for the due date suggestion (-1 means that this product will be never overdue)", minAmount: -1, amountName: defaultDueDays == 1 ? "Day" : "Days", systemImage: MySymbols.date)
            
            // Default due days afer opening
            MyIntStepper(amount: $defaultDueDaysAfterOpen, description: "Default due days after opened", helpText: "When this product was marked as opened, the due date will be replaced by today + this amount of days (a value of 0 disables this)", minAmount: 0, amountName: defaultDueDaysAfterOpen == 1 ? "Day" : "Days", systemImage: MySymbols.date)
            
            // Default due days after freezing
            MyIntStepper(amount: $defaultDueDaysAfterFreezing, description: "Default due days after freezing", helpText: "On moving this product to a freezer location (so when freezing it), the due date will be replaced by today + this amount of days", minAmount: -1, amountName: defaultDueDaysAfterFreezing == 1 ? "Day" : "Days", errorMessage: "This cannot be lower than -1 and needs to be a valid number with max. 0 decimal places", systemImage: MySymbols.freezing)
            
            // Default due days after thawing
            MyIntStepper(amount: $defaultDueDaysAfterThawing, description: "Default due days after thawing", helpText: "On moving this product from a freezer location (so when thawing it), the due date will be replaced by today + this amount of days", minAmount: 0, amountName: defaultDueDaysAfterThawing == 1 ? "Day" : "Days", errorMessage: "This cannot be lower than 0 and needs to be a valid number with max. 0 decimal places", systemImage: MySymbols.thawing)
        }
#if os(iOS)
        .navigationTitle("Due date")
#endif
    }
    var quantityUnitPropertiesView: some View {
        Form {
            // Default Quantity Unit Stock - REQUIRED
            HStack{
                Picker(selection: $quIDStock, label: MyLabelWithSubtitle(title: "Quantity unit stock", subTitle: "A quantity unit is required", systemImage: MySymbols.quantityUnit, isSubtitleProblem: true, hideSubtitle: quIDStock != nil), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdQuantityUnits.filter({$0.active}), id:\.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id as Int?)
                    }
                })
                .onChange(of: quIDStock) {
                    if quIDPurchase == nil {
                        quIDPurchase = quIDStock
                        quIDConsume = quIDStock
                        quIDPrice = quIDPrice
                    }
                }
                
                FieldDescription(description: "Quantity unit stock cannot be changed after first purchase")
            }
            
            // Default Quantity Unit Purchase - REQUIRED
            HStack{
                Picker(selection: $quIDPurchase, label: MyLabelWithSubtitle(title: "Default quantity unit purchase", subTitle: "A quantity unit is required", systemImage: MySymbols.quantityUnit, isSubtitleProblem: true, hideSubtitle: quIDPurchase != nil), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdQuantityUnits.filter({$0.active}), id:\.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id as Int?)
                    }
                })
                FieldDescription(description: "This is the default quantity unit used when adding this product to the shopping list")
            }
            
            // Default Quantity Unit Consume - REQUIRED
            HStack{
                Picker(selection: $quIDConsume, label: MyLabelWithSubtitle(title: "Default quantity unit consume", subTitle: "A quantity unit is required", systemImage: MySymbols.quantityUnit, isSubtitleProblem: true, hideSubtitle: quIDConsume != nil), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdQuantityUnits.filter({$0.active}), id:\.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id as Int?)
                    }
                })
                FieldDescription(description: "This is the default quantity unit used when consuming this product")
            }
            
            // Default Quantity Unit Price - REQUIRED
            HStack{
                Picker(selection: $quIDPrice, label: MyLabelWithSubtitle(title: "Quantity unit for prices", subTitle: "A quantity unit is required", systemImage: MySymbols.quantityUnit, isSubtitleProblem: true, hideSubtitle: quIDPrice != nil), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdQuantityUnits.filter({$0.active}), id:\.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id as Int?)
                    }
                })
                FieldDescription(description: "When displaying prices for this product, they will be related to this quantity unit")
            }
        }
#if os(iOS)
        .navigationTitle("Quantity units")
#endif
    }
    var amountPropertiesView: some View {
        Form {
            // Min Stock amount
            MyDoubleStepper(amount: $minStockAmount, description: "Minimum stock amount ", minAmount: 0, amountStep: 1, amountName: currentQUStock?.name ?? "QU", systemImage: MySymbols.amount)
            
            // Accumulate sub products min stock amount
            MyToggle(isOn: $cumulateMinStockAmountOfSubProducts, description: "Accumulate sub products min. stock amount ", descriptionInfo: "If enabled, the min. stock amount of sub products will be accumulated into this product, means the sub product will never be "missing", only this product", icon: MySymbols.accumulate)
            
            // Treat opened as out of stock
            MyToggle(isOn: $treatOpenedAsOutOfStock, description: "Treat opened as out of stock", descriptionInfo: "When enabled, opened items will be counted as missing for calculating if this product is below its minimum stock amount", icon: MySymbols.stockOverview)
            
            // Quick consume amount
            MyDoubleStepper(amount: $quickConsumeAmount, description: "Quick consume amount", descriptionInfo: "This amount is used for the "quick consume button" on the stock overview page (related to quantity unit stock)", minAmount: 0.0001, amountStep: 1.0, amountName: nil, systemImage: MySymbols.consume)
            
            // Quick open amount
            MyDoubleStepper(amount: $quickOpenAmount, description: "Quick open amount", descriptionInfo: "This amount is used for the "quick open button" on the stock overview page (related to quantity unit stock)", minAmount: 0.0001, amountStep: 1.0, amountName: nil, systemImage: MySymbols.open)
            
            // Tare weight
            Group {
                MyToggle(isOn: $enableTareWeightHandling, description: "Enable tare weight handling", descriptionInfo: "This is useful e.g. for flour in jars - on purchase/consume/inventory you always weigh the whole jar, the amount to be posted is then automatically calculated based on what is in stock and the tare weight defined below", icon: MySymbols.tareWeight)
                
                if enableTareWeightHandling {
                    MyDoubleStepper(amount: $tareWeight, description: "Tare weight", minAmount: 0, amountStep: 1, amountName: currentQUStock?.name ?? "QU", systemImage: MySymbols.tareWeight)
                }
            }
            
            // Check stock fulfillment for recipes
            MyToggle(isOn: $notCheckStockFulfillmentForRecipes, description: "Disable stock fulfillment checking for this ingredient", descriptionInfo: "This will be used as the default setting when adding this product as a recipe ingredient", icon: MySymbols.recipe)
        }
#if os(iOS)
        .navigationTitle("Amounts")
#endif
    }
    var barcodePropertiesView: some View {
        Group {
            if let product = product {
                MDBarcodesView(productID: product.id)
            }
        }
    }
}

struct MDProductFormView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MDProductFormView(isNewProduct: true, showAddProduct: Binding.constant(true))
        }
    }
}
