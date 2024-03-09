//
//  MDProductFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

struct MDProductFormOFFView: View {
    @ObservedObject var grocyVM: GrocyViewModel = .shared
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
                MyTextField(textToEdit: Binding.constant(barcode), description: "str.md.barcode", isCorrect: Binding.constant(true), leadingIcon: MySymbols.barcode)
                    .disabled(true)
            }
            
            if productNames.isEmpty {
                MyTextField(textToEdit: $name, description: "str.md.product.name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "str.md.product.name.required", errorMessage: "str.md.product.name.exists")
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
            } else {
                Picker(selection: $name, content: {
                    ForEach(productNames.sorted(by: >), id: \.key) { key, value in
                        Text("\(value) (\(key))").tag(value)
                    }
                }, label: {
                    HStack{
                        Image(systemName: "tag")
                        VStack(alignment: .leading){
                            Text(LocalizedStringKey("str.md.product.name"))
                            if name.isEmpty {
                                Text(LocalizedStringKey("str.md.product.name.required"))
                                    .font(.caption)
                                    .foregroundColor(Color.red)
                            } else if !isNameCorrect {
                                Text("str.md.product.name.exists")
                                    .font(.caption)
                                    .foregroundColor(Color.red)
                            }
                        }
                    }
                })
                .onChange(of: name, perform: { value in
                    isNameCorrect = checkNameCorrect()
                })
            }
        }
    }
}

struct MDProductFormView: View {
    @ObservedObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("devMode") private var devMode: Bool = false
    
    @State private var firstAppear: Bool = true
    @State private var isProcessing: Bool = false
    
    @State private var name: String = "" // REQUIRED
    @State private var active: Bool = true
    @State private var parentProductID: Int?
    @State private var mdProductDescription: String = ""
    @State private var pictureFileName: String?
    @State private var defaultStockLabelType: DefaultStockLabelType = DefaultStockLabelType.none
    @State private var autoReprintStockLabel: Bool = false
    
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
    @Binding var toastType: ToastType?
    
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
        
        defaultStockLabelType = DefaultStockLabelType(rawValue: product?.defaultStockLabelType ?? 0) ?? DefaultStockLabelType.none
        autoReprintStockLabel = product?.autoReprintStockLabel ?? false
        
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
                defaultStockLabelType: defaultStockLabelType.rawValue,
                shouldNotBeFrozen: shouldNotBeFrozen,
                treatOpenedAsOutOfStock: treatOpenedAsOutOfStock,
                noOwnStock: noOwnStock,
                defaultConsumeLocationID: defaultConsumeLocationID,
                moveOnOpen: defaultConsumeLocationID != nil ? moveOnOpen : nil,
                autoReprintStockLabel: autoReprintStockLabel,
                rowCreatedTimestamp: timeStamp
            )
            isProcessing = true
            if isNewProduct {
                do {
                    _ = try await grocyVM.postMDObject(object: .products, content: productPOST)
                    grocyVM.postLog("Product added successfully.", type: .info)
                    toastType = .successAdd
                    await grocyVM.requestData(objects: [.products])
                    if (openFoodFactsBarcode != nil) || (!queuedBarcode.isEmpty) {
                        let barcodePOST = MDProductBarcode(id: grocyVM.findNextID(.product_barcodes), productID: id, barcode: openFoodFactsBarcode ?? queuedBarcode, rowCreatedTimestamp: Date().iso8601withFractionalSeconds)
                        let _ = try await grocyVM.postMDObject(object: .product_barcodes, content: barcodePOST)
                        grocyVM.postLog("Barcode add successful.", type: .info)
                        await grocyVM.requestData(objects: [.product_barcodes])
                        mdBarcodeReturn?.wrappedValue = barcodePOST
                        toastType = .successAdd
                    }
                    finishForm()
                } catch {
                    grocyVM.postLog("Product add failed. \(error)", type: .error)
                    toastType = .failAdd
                }
            } else {
                do {
                    try await grocyVM.putMDObjectWithID(object: .products, id: id, content: productPOST)
                    grocyVM.postLog("Product edit successful.", type: .info)
                    toastType = .successEdit
                    await updateData()
                    finishForm()
                } catch {
                    grocyVM.postLog("Product edit failed. \(error)", type: .error)
                    toastType = .failEdit
                }
            }
        }
        isProcessing = false
    }
    
    var body: some View {
        content
            .navigationTitle(isNewProduct ? LocalizedStringKey("str.md.product.new") : LocalizedStringKey("str.md.product.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { Task { await saveProduct() } }, label: {
                        Label(LocalizedStringKey("str.md.product.save"), systemImage: MySymbols.save)
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
                        Button(LocalizedStringKey("str.cancel")) {
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
                .onChange(of: queuedBarcode, perform: { newBarcode in
                    isBarcodeCorrect = checkBarcodeCorrect()
                })
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
            Text(isNewProduct ? LocalizedStringKey("str.md.product.new") : LocalizedStringKey("str.md.product.edit"))
                .font(.title)
                .bold()
                .padding(.bottom, 20.0)
#endif
            
            if let openFoodFactsBarcode = openFoodFactsBarcode {
                MDProductFormOFFView(barcode: openFoodFactsBarcode, name: $name)
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
            } else {
                MyTextField(textToEdit: $name, description: "str.md.product.name", isCorrect: $isNameCorrect, leadingIcon: "tag", emptyMessage: "str.md.product.name.required", errorMessage: "str.md.product.name.exists")
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
            }
            
            if !queuedBarcode.isEmpty && isNewProduct {
                MyTextField(textToEdit: $queuedBarcode, description: "str.md.barcode", isCorrect: $isBarcodeCorrect, leadingIcon: MySymbols.barcode, errorMessage: "str.md.barcode.barcode.invalid")
                    .onChange(of: queuedBarcode, perform: { newBarcode in
                        isBarcodeCorrect = checkBarcodeCorrect()
                    })
            }
            
#if os(macOS)
            DisclosureGroup(content: {
                optionalPropertiesView
            }, label: {
                MyLabelWithSubtitle(title: "str.md.product.category.optionalProperties", subTitle: "str.md.product.category.optionalProperties.description", systemImage: MySymbols.description)
            })
            
            DisclosureGroup(content: {
                locationPropertiesView
            }, label: {
                MyLabelWithSubtitle(title: "str.md.product.category.defaultLocations", subTitle: "str.md.product.category.defaultLocations.description", systemImage: MySymbols.location, isProblem: locationID == nil)
            })
            
            DisclosureGroup(content: {
                dueDatePropertiesView
            }, label: {
                MyLabelWithSubtitle(title: "str.md.product.category.dueDate", subTitle: "str.md.product.category.dueDate.description", systemImage: MySymbols.date)
            })
            
            DisclosureGroup(content: {
                quantityUnitPropertiesView
            }, label: {
                MyLabelWithSubtitle(title: "str.md.product.category.quantityUnits", subTitle: "str.md.product.category.quantityUnits.description", systemImage: MySymbols.quantityUnit, isProblem: (quIDStock == nil || quIDPurchase == nil || quIDConsume == nil || quIDPrice == nil))
            })
            
            DisclosureGroup(content: {
                amountPropertiesView
            }, label: {
                MyLabelWithSubtitle(title: "str.md.product.category.amount", subTitle: "str.md.product.category.amount.description", systemImage: MySymbols.amount)
            })
            
            DisclosureGroup(content: {
                barcodePropertiesView
            }, label: {
                MyLabelWithSubtitle(title: "str.md.barcodes", subTitle: isNewProduct ? "str.md.product.notOnServer" : "", systemImage: MySymbols.barcode, hideSubtitle: !isNewProduct)
            })
            .disabled(isNewProduct)
#else
            Section {
                NavigationLink(
                    destination: optionalPropertiesView,
                    label: {
                        MyLabelWithSubtitle(title: "str.md.product.category.optionalProperties", subTitle: "str.md.product.category.optionalProperties.description", systemImage: MySymbols.description)
                    })
                
                NavigationLink(
                    destination: locationPropertiesView,
                    label: {
                        MyLabelWithSubtitle(title: "str.md.product.category.defaultLocations", subTitle: "str.md.product.category.defaultLocations.description", systemImage: MySymbols.location, isProblem: locationID == nil)
                    })
                
                NavigationLink(
                    destination: dueDatePropertiesView,
                    label: {
                        MyLabelWithSubtitle(title: "str.md.product.category.dueDate", subTitle: "str.md.product.category.dueDate.description", systemImage: MySymbols.date)
                    })
                
                NavigationLink(
                    destination: quantityUnitPropertiesView,
                    label: {
                        MyLabelWithSubtitle(title: "str.md.product.category.quantityUnits", subTitle: "str.md.product.category.quantityUnits.description", systemImage: MySymbols.quantityUnit, isProblem: (quIDStock == nil || quIDPurchase == nil || quIDConsume == nil || quIDPrice == nil))
                    })
                
                NavigationLink(
                    destination: amountPropertiesView,
                    label: {
                        MyLabelWithSubtitle(title: "str.md.product.category.amount", subTitle: "str.md.product.category.amount.description", systemImage: MySymbols.amount)
                    })
                
                NavigationLink(
                    destination: barcodePropertiesView,
                    label: {
                        MyLabelWithSubtitle(title: "str.md.barcodes", subTitle: isNewProduct ? "str.md.product.notOnServer" : "", systemImage: MySymbols.barcode, hideSubtitle: !isNewProduct)
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
            MyToggle(isOn: $active, description: "str.md.product.active", descriptionInfo: nil, icon: "checkmark.circle")
            
            // Parent Product
            ProductField(productID: $parentProductID, description: "str.md.product.parentProduct")
            
            // Product Description
            MyTextField(textToEdit: $mdProductDescription, description: "str.md.product.description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
            
            // Product group
            Picker(selection: $productGroupID, label: Label(LocalizedStringKey("str.md.product.productGroup"), systemImage: MySymbols.productGroup).foregroundColor(.primary), content: {
                Text("").tag(nil as Int?)
                ForEach(grocyVM.mdProductGroups.filter({$0.active}), id:\.id) { grocyProductGroup in
                    Text(grocyProductGroup.name).tag(grocyProductGroup.id as Int?)
                }
            })
            
            // Energy
            MyDoubleStepper(amount: $calories, description: "str.md.product.calories", descriptionInfo: "str.md.product.calories.info", minAmount: 0, amountStep: 1, amountName: "kcal", systemImage: MySymbols.energy)
            
            // Don't show on stock overview
            MyToggle(isOn: $hideOnStockOverview, description: "str.md.product.dontShowOnStockOverview", descriptionInfo: "str.md.product.dontShowOnStockOverview.info", icon: MySymbols.stockOverview)
            
            // Disable own stock
            MyToggle(isOn: $noOwnStock, description: "str.md.product.noOwnStock", descriptionInfo: "str.md.product.noOwnStock.hint", icon: MySymbols.stockOverview)
            
            // Product should not be frozen
            MyToggle(isOn: $shouldNotBeFrozen, description: "str.md.product.shouldNotBeFrozen", descriptionInfo: "str.md.product.shouldNotBeFrozen.hint", icon: MySymbols.freezing)
            
            // Default stock entry label
            HStack{
                Picker(selection: $defaultStockLabelType, label: MyLabelWithSubtitle(title: "Default stock entry label", systemImage: "tag", isSubtitleProblem: false, hideSubtitle: true), content: {
                    Text("No label").tag(DefaultStockLabelType.none)
                    Text("Single label").tag(DefaultStockLabelType.singleLabel)
                    Text("Label per unit").tag(DefaultStockLabelType.labelPerUnit)
                })
                FieldDescription(description: "This is the default which will be prefilled on purchase")
            }
            
            // Auto reprint stock entry label
            MyToggle(isOn: $autoReprintStockLabel, description: "Auto reprint stock entry label", descriptionInfo: "When enabled, auto-changing the due date of a stock entry (by opening/freezing/thawing and having corresponding default due days set) will reprint its label", icon: "printer")
            
            
            // Product picture
#if os(iOS)
            NavigationLink(destination: MDProductPictureFormView(product: product, pictureFileName: $pictureFileName), label: {
                MyLabelWithSubtitle(title: "str.md.product.picture", subTitle: (product?.pictureFileName ?? "").isEmpty ? "str.md.product.picture.none" : "str.md.product.picture.saved", systemImage: MySymbols.picture)
            })
            .disabled(isNewProduct)
#elseif os(macOS)
            DisclosureGroup(content: {
                MDProductPictureFormView(product: product, pictureFileName: $pictureFileName)
            }, label: {
                MyLabelWithSubtitle(title: "str.md.product.picture", subTitle: (product?.pictureFileName ?? "").isEmpty ? "str.md.product.picture.none" : "str.md.product.picture.saved", systemImage: MySymbols.picture)
            })
            .disabled(isNewProduct)
#endif
        }
#if os(iOS)
        .navigationTitle(LocalizedStringKey("str.md.product.category.optionalProperties"))
#endif
    }
    var locationPropertiesView: some View {
        Form {
            // Default Location - REQUIRED
            Picker(selection: $locationID, label: MyLabelWithSubtitle(title: "str.md.product.location", subTitle: "str.md.product.location.required", systemImage: MySymbols.location, isSubtitleProblem: true, hideSubtitle: locationID != nil), content: {
                ForEach(grocyVM.mdLocations.filter({$0.active}), id:\.id) { grocyLocation in
                    Text(grocyLocation.name).tag(grocyLocation.id as Int?)
                }
            })
            // Default consume location
            HStack {
                Picker(selection: $defaultConsumeLocationID, label: MyLabelWithSubtitle(title: "str.md.product.location.consume", systemImage: MySymbols.location, hideSubtitle: true), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdLocations.filter({$0.active}), id:\.id) { grocyLocation in
                        Text(grocyLocation.name).tag(grocyLocation.id as Int?)
                    }
                })
                FieldDescription(description: "str.md.product.location.consume.info")
            }
            
            // Move on open
            if defaultConsumeLocationID != nil {
                MyToggle(isOn: $moveOnOpen, description: "str.md.product.location.consume.moveOnOpen", descriptionInfo: "str.md.product.location.consume.moveOnOpen.info", icon: MySymbols.transfer)
            }
            
            // Default Store
            Picker(selection: $storeID, label: MyLabelWithSubtitle(title: "str.md.product.store", systemImage: MySymbols.store, hideSubtitle: true), content: {
                Text("").tag(nil as Int?)
                ForEach(grocyVM.mdStores.filter({$0.active}), id:\.id) { grocyStore in
                    Text(grocyStore.name).tag(grocyStore.id as Int?)
                }
            })
        }
#if os(iOS)
        .navigationTitle(LocalizedStringKey("str.md.product.category.defaultLocations"))
#endif
    }
    var dueDatePropertiesView: some View {
        Form {
            VStack(alignment: .leading){
                Text(LocalizedStringKey("str.md.product.dueType"))
                    .font(.headline)
                // Due Type, default best before
                Picker("", selection: $dueType, content: {
                    Text("str.md.product.dueType.bestBefore").tag(DueType.bestBefore)
                    Text("str.md.product.dueType.expires").tag(DueType.expires)
                })
                .pickerStyle(.segmented)
            }
            
            // Default due days
            MyIntStepper(amount: $defaultDueDays, description: "str.md.product.defaultDueDays", helpText: "str.md.product.defaultDueDays.info", minAmount: -1, amountName: defaultDueDays == 1 ? "str.day" : "str.days", systemImage: MySymbols.date)
            
            // Default due days afer opening
            MyIntStepper(amount: $defaultDueDaysAfterOpen, description: "str.md.product.defaultDueDaysAfterOpen", helpText: "str.md.product.defaultDueDaysAfterOpen.info", minAmount: 0, amountName: defaultDueDaysAfterOpen == 1 ? "str.day" : "str.days", systemImage: MySymbols.date)
            
            // Default due days after freezing
            MyIntStepper(amount: $defaultDueDaysAfterFreezing, description: "str.md.product.defaultDueDaysAfterFreezing", helpText: "str.md.product.defaultDueDaysAfterFreezing.info", minAmount: -1, amountName: defaultDueDaysAfterFreezing == 1 ? "str.day" : "str.days", errorMessage: "str.md.product.defaultDueDaysAfterFreezing.invalid", systemImage: MySymbols.freezing)
            
            // Default due days after thawing
            MyIntStepper(amount: $defaultDueDaysAfterThawing, description: "str.md.product.defaultDueDaysAfterThawing", helpText: "str.md.product.defaultDueDaysAfterThawing.info", minAmount: 0, amountName: defaultDueDaysAfterThawing == 1 ? "str.day" : "str.days", errorMessage: "str.md.product.defaultDueDaysAfterThawing.invalid", systemImage: MySymbols.thawing)
        }
#if os(iOS)
        .navigationTitle(LocalizedStringKey("str.md.product.category.dueDate"))
#endif
    }
    var quantityUnitPropertiesView: some View {
        Form {
            // Default Quantity Unit Stock - REQUIRED
            HStack{
                Picker(selection: $quIDStock, label: MyLabelWithSubtitle(title: "str.md.product.quStock", subTitle: "str.md.product.quStock.required", systemImage: MySymbols.quantityUnit, isSubtitleProblem: true, hideSubtitle: quIDStock != nil), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdQuantityUnits.filter({$0.active}), id:\.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id as Int?)
                    }
                })
                .onChange(of: quIDStock, perform: { newValue in
                    if quIDPurchase == nil {
                        quIDPurchase = quIDStock
                        quIDConsume = quIDStock
                        quIDPrice = quIDPrice
                    }
                })
                
                FieldDescription(description: "str.md.product.quStock.info")
            }
            
            // Default Quantity Unit Purchase - REQUIRED
            HStack{
                Picker(selection: $quIDPurchase, label: MyLabelWithSubtitle(title: "str.md.product.quPurchase", subTitle: "str.md.product.quPurchase.required", systemImage: MySymbols.quantityUnit, isSubtitleProblem: true, hideSubtitle: quIDPurchase != nil), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdQuantityUnits.filter({$0.active}), id:\.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id as Int?)
                    }
                })
                FieldDescription(description: "str.md.product.quPurchase.info")
            }
            
            // Default Quantity Unit Consume - REQUIRED
            HStack{
                Picker(selection: $quIDConsume, label: MyLabelWithSubtitle(title: "str.md.product.quConsume", subTitle: "str.md.product.quConsume.required", systemImage: MySymbols.quantityUnit, isSubtitleProblem: true, hideSubtitle: quIDConsume != nil), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdQuantityUnits.filter({$0.active}), id:\.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id as Int?)
                    }
                })
                FieldDescription(description: "str.md.product.quConsume.info")
            }
            
            // Default Quantity Unit Price - REQUIRED
            HStack{
                Picker(selection: $quIDPrice, label: MyLabelWithSubtitle(title: "str.md.product.quPrice", subTitle: "str.md.product.quPrice.required", systemImage: MySymbols.quantityUnit, isSubtitleProblem: true, hideSubtitle: quIDPrice != nil), content: {
                    Text("").tag(nil as Int?)
                    ForEach(grocyVM.mdQuantityUnits.filter({$0.active}), id:\.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id as Int?)
                    }
                })
                FieldDescription(description: "str.md.product.quPrice.info")
            }
        }
#if os(iOS)
        .navigationTitle(LocalizedStringKey("str.md.product.category.quantityUnits"))
#endif
    }
    var amountPropertiesView: some View {
        Form {
            // Min Stock amount
            MyDoubleStepper(amount: $minStockAmount, description: "str.md.product.minStockAmount", minAmount: 0, amountStep: 1, amountName: currentQUStock?.name ?? "QU", systemImage: MySymbols.amount)
            
            // Accumulate sub products min stock amount
            MyToggle(isOn: $cumulateMinStockAmountOfSubProducts, description: "str.md.product.cumulateMinStockAmountOfSubProducts", descriptionInfo: "str.md.product.cumulateMinStockAmountOfSubProducts.info", icon: MySymbols.accumulate)
            
            // Treat opened as out of stock
            MyToggle(isOn: $treatOpenedAsOutOfStock, description: "str.md.product.treatOpenedAsOutOfStock", descriptionInfo: "str.md.product.treatOpenedAsOutOfStock.hint", icon: MySymbols.stockOverview)
            
            // Quick consume amount
            MyDoubleStepper(amount: $quickConsumeAmount, description: "str.md.product.quickConsumeAmount", descriptionInfo: "str.md.product.quickConsumeAmount.info", minAmount: 0.0001, amountStep: 1.0, amountName: nil, systemImage: MySymbols.consume)
            
            // Quick open amount
            MyDoubleStepper(amount: $quickOpenAmount, description: "str.md.product.quickOpenAmount", descriptionInfo: "str.md.product.quickOpenAmount.info", minAmount: 0.0001, amountStep: 1.0, amountName: nil, systemImage: MySymbols.open)
            
            // Tare weight
            Group {
                MyToggle(isOn: $enableTareWeightHandling, description: "str.md.product.enableTareWeightHandling", descriptionInfo: "str.md.product.enableTareWeightHandling.info", icon: MySymbols.tareWeight)
                
                if enableTareWeightHandling {
                    MyDoubleStepper(amount: $tareWeight, description: "str.md.product.tareWeight", minAmount: 0, amountStep: 1, amountName: currentQUStock?.name ?? "QU", systemImage: MySymbols.tareWeight)
                }
            }
            
            // Check stock fulfillment for recipes
            MyToggle(isOn: $notCheckStockFulfillmentForRecipes, description: "str.md.product.notCheckStockFulfillmentForRecipes", descriptionInfo: "str.md.product.notCheckStockFulfillmentForRecipes.info", icon: MySymbols.recipe)
        }
#if os(iOS)
        .navigationTitle(LocalizedStringKey("str.md.product.category.amount"))
#endif
    }
    var barcodePropertiesView: some View {
        Group {
            if let product = product {
                MDBarcodesView(productID: product.id, toastType: $toastType)
            }
        }
    }
}

struct MDProductFormView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MDProductFormView(isNewProduct: true, showAddProduct: Binding.constant(true), toastType: Binding.constant(nil))
        }
    }
}
