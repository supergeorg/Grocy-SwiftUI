//
//  MDProductFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.11.20.
//

import SwiftUI

struct MDProductFormView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstAppear: Bool = true
    
    @State private var name: String = "" // REQUIRED
    @State private var active: Bool = true
    @State private var parentProductID: String?
    @State private var mdProductDescription: String = ""
    @State private var locationID: String? // REQUIRED
    @State private var shoppingLocationID: String?
    @State private var minStockAmount: Double?
    @State private var cumulateMinStockAmountOfSubProducts: Bool = false
    @State private var dueType: DueType = DueType.bestBefore
    @State private var defaultDueDays: Int?
    @State private var defaultDueDaysAfterOpen: Int?
    @State private var productGroupID: String?
    @State private var quIDStock: String? // REQUIRED
    @State private var quIDPurchase: String? // REQUIRED
    @State private var quFactorPurchaseToStock: Double? = 1.0
    @State private var enableTareWeightHandling: Bool = false
    @State private var tareWeight: Double?
    @State private var notCheckStockFulfillmentForRecipes: Bool = false
    @State private var calories: Double?
    @State private var defaultDueDaysAfterFreezing: Int?
    @State private var defaultDueDaysAfterThawing: Int?
    @State private var quickConsumeAmount: Double? = 1.0
    @State private var hideOnStockOverview: Bool = false
    
    @State private var showDeleteAlert: Bool = false
    @State private var showOFFResult: Bool = false
    
    var isNewProduct: Bool
    var product: MDProduct?
    
    @Binding var toastType: MDToastType?
    
    @State var isNameCorrect: Bool = true
    private func checkNameCorrect() -> Bool {
        let foundProduct = grocyVM.mdProducts.first(where: {$0.name == name})
        return isNewProduct ? !(name.isEmpty || foundProduct != nil) : !(name.isEmpty || (foundProduct != nil && foundProduct!.id != product!.id))
    }
    
    private var currentQUPurchase: MDQuantityUnit? {
        return grocyVM.mdQuantityUnits.first(where: {$0.id == quIDPurchase})
    }
    private var currentQUStock: MDQuantityUnit? {
        return grocyVM.mdQuantityUnits.first(where: {$0.id == quIDStock})
    }
    
    private func resetForm() {
        name = product?.name ?? ""
        active = (product?.active ?? "1") == "1"
        parentProductID = product?.parentProductID
        mdProductDescription = product?.mdProductDescription ?? ""
        locationID = product?.locationID
        shoppingLocationID = product?.shoppingLocationID
        minStockAmount = Double(product?.minStockAmount ?? "")
        cumulateMinStockAmountOfSubProducts = Bool(product?.cumulateMinStockAmountOfSubProducts ?? "") ?? false
        dueType = product?.dueType == DueType.bestBefore.rawValue ? DueType.bestBefore : DueType.expires
        defaultDueDays = Int(product?.defaultBestBeforeDays ?? "")
        defaultDueDaysAfterOpen = Int(product?.defaultBestBeforeDaysAfterOpen ?? "")
        productGroupID = product?.productGroupID
        quIDStock = product?.quIDStock
        quIDPurchase = product?.quIDPurchase
        quFactorPurchaseToStock = Double(product?.quFactorPurchaseToStock ?? "") ?? 1.0
        enableTareWeightHandling = (product?.enableTareWeightHandling ?? "0") == "1"
        tareWeight = Double(product?.tareWeight ?? "")
        notCheckStockFulfillmentForRecipes = (product?.notCheckStockFulfillmentForRecipes ?? "0") == "1"
        calories = Double(product?.calories ?? "")
        defaultDueDaysAfterFreezing = Int(product?.defaultBestBeforeDaysAfterThawing ?? "")
        defaultDueDaysAfterThawing = Int(product?.defaultBestBeforeDaysAfterThawing ?? "")
        quickConsumeAmount = Double(product?.quickConsumeAmount ?? "") ?? 1.0
        hideOnStockOverview = (product?.hideOnStockOverview ?? "0") == "1"
        isNameCorrect = checkNameCorrect()
    }
    
    private func updateData() {
        grocyVM.requestData(objects: [.products, .quantity_units, .locations, .shopping_locations])
    }
    
    private func finishForm() {
        #if os(iOS)
        presentationMode.wrappedValue.dismiss()
        #elseif os(macOS)
        if isNewProduct {
            NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
        }
        #endif
    }
    
    private var isFormValid: Bool {
        !(name.isEmpty) && isNameCorrect && (locationID != nil) && (quIDStock != nil) && (quIDPurchase != nil)
    }
    
    private func saveProduct() {
        if let locationID = locationID {
            if let quIDPurchase = quIDPurchase {
                if let quIDStock = quIDStock {
                    let productPOST = MDProductPOST(id: isNewProduct ? grocyVM.findNextID(.products) : Int(product!.id)!, name: name, mdProductDescription: mdProductDescription, productGroupID: productGroupID, active: active ? "1" : "0", locationID: locationID, shoppingLocationID: shoppingLocationID, quIDPurchase: quIDPurchase, quIDStock: quIDStock, quFactorPurchaseToStock: quFactorPurchaseToStock, minStockAmount: minStockAmount, defaultBestBeforeDays: defaultDueDays, defaultBestBeforeDaysAfterOpen: defaultDueDaysAfterOpen, defaultBestBeforeDaysAfterFreezing: defaultDueDaysAfterFreezing, defaultBestBeforeDaysAfterThawing: defaultDueDaysAfterThawing, pictureFileName: nil, enableTareWeightHandling: enableTareWeightHandling ? "1" : "0", tareWeight: tareWeight, notCheckStockFulfillmentForRecipes: notCheckStockFulfillmentForRecipes ? "1" : "0", parentProductID: parentProductID, calories: calories, cumulateMinStockAmountOfSubProducts: cumulateMinStockAmountOfSubProducts ? "1" : "0", dueType: dueType.rawValue, quickConsumeAmount: quickConsumeAmount, rowCreatedTimestamp: isNewProduct ? Date().iso8601withFractionalSeconds : product!.rowCreatedTimestamp, hideOnStockOverview: hideOnStockOverview ? "1" : "0", userfields: nil)
                    if isNewProduct {
                        grocyVM.postMDObject(object: .products, content: productPOST, completion: { result in
                            switch result {
                            case let .success(message):
                                print(message)
                                toastType = .successAdd
                                updateData()
                                finishForm()
                            case let .failure(error):
                                print("\(error)")
                                toastType = .failAdd
                            }
                        })
                    } else {
                        grocyVM.putMDObjectWithID(object: .products, id: product!.id, content: productPOST, completion: { result in
                            switch result {
                            case let .success(message):
                                print(message)
                                toastType = .successEdit
                                updateData()
                                finishForm()
                            case let .failure(error):
                                print("\(error)")
                                toastType = .failEdit
                            }
                        })
                    }
                }
            }
        }
    }
    
    var body: some View {
        #if os(macOS)
        ScrollView{
            content
                .padding()
        }
        .padding()
        #elseif os(iOS)
        content
            .navigationTitle(isNewProduct ? LocalizedStringKey("str.md.product.new") : LocalizedStringKey("str.md.product.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    if isNewProduct {
                        Button(LocalizedStringKey("str.cancel")) {
                            finishForm()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("str.md.product.save")) {
                        saveProduct()
                    }.disabled(!isFormValid)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    // Back not shown without it
                    if !isNewProduct{
                        Text("")
                    }
                }
            })
        #endif
    }
    
    var content: some View {
        Form {
            #if os(iOS)
            Button(action: {
                showOFFResult.toggle()
            }, label: {Label("FILL WITH OFF", systemImage: "plus")})
            .popover(isPresented: $showOFFResult, content: {
                OpenFoodFactsScannerView()
                    .frame(width: 500, height: 500)
            })
            #endif
            
            Group{
                Section(header: Text(LocalizedStringKey("str.md.product")).font(.headline)) {
                    // Name - REQUIRED
                    MyTextField(textToEdit: $name, description: "str.md.product.name", isCorrect: $isNameCorrect, leadingIcon: "tag", isEditing: true, emptyMessage: "str.md.product.name.required", errorMessage: "str.md.product.name.exists")
                        .onChange(of: name, perform: { value in
                            isNameCorrect = checkNameCorrect()
                        })
                    
                    // Active
                    MyToggle(isOn: $active, description: "str.md.product.active", descriptionInfo: nil, icon: "checkmark.circle")
                    
                    // Parent Product
                    ProductField(productID: $parentProductID, description: "str.md.product.parentProduct")
                    
                    // Product Description
                    MyTextField(textToEdit: $mdProductDescription, description: "str.md.product.description", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description, isEditing: true)
                }
                
                Section(header: Text(LocalizedStringKey("str.md.product.location")).font(.headline)) {
                    // Default Location - REQUIRED
                    VStack(alignment: .trailing) {
                        Picker(LocalizedStringKey("str.md.product.location"), selection: $locationID, content: {
                            ForEach(grocyVM.mdLocations, id:\.id) { grocyLocation in
                                Text(grocyLocation.name).tag(grocyLocation.id as String?)
                            }
                        })
                        if locationID == nil { Text(LocalizedStringKey("str.md.product.location.required")).foregroundColor(.red) }
                    }
                    
                    // Default Shopping Location
                    Picker(LocalizedStringKey("str.md.product.shoppingLocation"), selection: $shoppingLocationID, content: {
                        Text("").tag(nil as String?)
                        ForEach(grocyVM.mdShoppingLocations, id:\.id) { grocyShoppingLocation in
                            Text(grocyShoppingLocation.name).tag(grocyShoppingLocation.id as String?)
                        }
                    })
                }
                
                Section(header: Text(LocalizedStringKey("str.md.product.minStockAmount")).font(.headline)) {
                    
                    // Min Stock amount
                    MyDoubleStepper(amount: $minStockAmount, description: "str.md.product.minStockAmount", minAmount: 0, amountStep: 1, amountName: currentQUStock?.name ?? "QU", errorMessage: "str.md.product.minStockAmount.invalid", systemImage: "tag")
                    
                    // Accumulate sub products min stock amount
                    MyToggle(isOn: $cumulateMinStockAmountOfSubProducts, description: "str.md.product.cumulateMinStockAmountOfSubProducts", descriptionInfo: "str.md.product.cumulateMinStockAmountOfSubProducts.info")
                    
                }
            }
            
            Group{
                Section(header: Text(LocalizedStringKey("str.md.product.dueType")).font(.headline)) {
                    
                    HStack{
                        // Due Type, default best before
                        Picker(LocalizedStringKey("str.md.product.dueType"), selection: $dueType, content: {
                            Text("str.md.product.dueType.bestBefore").tag(DueType.bestBefore)
                            Text("str.md.product.dueType.expires").tag(DueType.expires)
                        }).pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Default due days
                    MyIntStepper(amount: $defaultDueDays, description: "str.md.product.defaultDueDays", helpText: "str.md.product.defaultDueDays.info", minAmount: 0, amountName: defaultDueDays == 1 ? "str.day" : "str.days")
                    
                    // Default due days afer opening
                    MyIntStepper(amount: $defaultDueDaysAfterOpen, description: "str.md.product.defaultDueDaysAfterOpen", helpText: "str.md.product.defaultDueDaysAfterOpen.info", minAmount: 0, amountName: defaultDueDaysAfterOpen == 1 ? "str.day" : "str.days")
                    
                }
                
                // Product group
                Picker(LocalizedStringKey("str.md.product.productGroup"), selection: $productGroupID, content: {
                    Text("").tag(nil as String?)
                    ForEach(grocyVM.mdProductGroups, id:\.id) { grocyProductGroup in
                        Text(grocyProductGroup.name).tag(grocyProductGroup.id as String?)
                    }
                })
                
                Section(header: Text(LocalizedStringKey("str.md.quantityUnits")).font(.headline)) {
                    // QU Stock - REQUIRED
                    VStack(alignment: .trailing){
                        HStack{
                            Picker(LocalizedStringKey("str.md.product.quStock"), selection: $quIDStock, content: {
                                ForEach(grocyVM.mdQuantityUnits, id:\.id) { grocyQuantityUnit in
                                    Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id as String?)
                                }
                            })
                            .onChange(of: quIDStock, perform: { newValue in
                                if quIDPurchase == nil { quIDPurchase = quIDStock }
                            })
                            FieldDescription(description: "str.md.product.quStock.info")
                        }
                        if quIDStock == nil { Text(LocalizedStringKey("str.md.product.quStock.required")).foregroundColor(.red) }
                    }
                    
                    // QU Purchase - REQUIRED
                    VStack(alignment: .trailing){
                        HStack{
                            Picker(LocalizedStringKey("str.md.product.quPurchase"), selection: $quIDPurchase, content: {
                                ForEach(grocyVM.mdQuantityUnits, id:\.id) { grocyQuantityUnit in
                                    Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id as String?)
                                }
                            })
                            FieldDescription(description: "str.md.product.quPurchase.info")
                        }
                        if quIDPurchase == nil { Text(LocalizedStringKey("str.md.product.quPurchase.required")).foregroundColor(.red) }
                    }
                    
                    VStack(alignment: .trailing) {
                        MyDoubleStepper(amount: $quFactorPurchaseToStock, description: "str.md.product.quFactorPurchaseToStock", minAmount: 0.0001, amountStep: 1.0, amountName: "", errorMessage: "str.md.product.quFactorPurchaseToStock.invalid", systemImage: "tag")
                        if quFactorPurchaseToStock != 1 { Text(LocalizedStringKey("str.md.product.quFactorPurchaseToStock.description \(currentQUPurchase?.name ?? "QU ERROR") \(String(format: "%.f", quFactorPurchaseToStock ?? 1.0)) \(currentQUStock?.namePlural ?? "QU ERROR")")) }
                    }
                }
            }
            
            Group{
                Section(header: Text(LocalizedStringKey("str.md.product.tareWeight")).font(.headline)) {
                    MyToggle(isOn: $enableTareWeightHandling, description: "str.md.product.enableTareWeightHandling", descriptionInfo: "str.md.product.enableTareWeightHandling.info", icon: "tag")
                    
                    if enableTareWeightHandling {
                        MyDoubleStepper(amount: $tareWeight, description: "str.md.product.tareWeight", minAmount: 0, amountStep: 1, amountName: currentQUStock?.name ?? "QU", errorMessage: "str.md.product.tareWeight.invalid", systemImage: "tag")
                    }
                }
                
                Section(header: Text(LocalizedStringKey("str.misc")).font(.headline)) {
                    MyToggle(isOn: $notCheckStockFulfillmentForRecipes, description: "str.md.product.notCheckStockFulfillmentForRecipes", descriptionInfo: "str.md.product.notCheckStockFulfillmentForRecipes.info", icon: "tag")
                    
                    MyDoubleStepper(amount: $calories, description: "str.md.product.calories", descriptionInfo: "str.md.product.calories.info", minAmount: 0, amountStep: 1, amountName: "kcal", errorMessage: "str.md.product.calories.invalid", systemImage: "tag")
                    
                    MyIntStepper(amount: $defaultDueDaysAfterFreezing, description: "str.md.product.defaultDueDaysAfterFreezing", helpText: "str.md.product.defaultDueDaysAfterFreezing.info", minAmount: -1, amountName: defaultDueDaysAfterFreezing == 1 ? "str.day" : "str.days", errorMessage: "str.md.product.defaultDueDaysAfterFreezing.invalid", systemImage: "thermometer.snowflake")
                    
                    MyIntStepper(amount: $defaultDueDaysAfterThawing, description: "str.md.product.defaultDueDaysAfterThawing", helpText: "str.md.product.defaultDueDaysAfterThawing.info", minAmount: 0, amountName: defaultDueDaysAfterThawing == 1 ? "str.day" : "str.days", errorMessage: "str.md.product.defaultDueDaysAfterThawing.invalid", systemImage: "thermometer.snowflake")
                }
                
                Section(header: Text(LocalizedStringKey("str.stock.stockOverview")).font(.headline)) {
                    MyDoubleStepper(amount: $quickConsumeAmount, description: "str.md.product.quickConsumeAmount", descriptionInfo: "str.md.product.quickConsumeAmount.info", minAmount: 0.0001, amountStep: 1.0, amountName: nil, errorMessage: "str.md.product.quickConsumeAmount.invalid", systemImage: MySymbols.consume)
                    
                    MyToggle(isOn: $hideOnStockOverview, description: "str.md.product.dontShowOnStockOverview", descriptionInfo: "str.md.product.dontShowOnStockOverview.info", icon: "tablecells")
                }
                
                if !isNewProduct {
                    if let product = product {
                        MDBarcodesView(productID: product.id, toastType: $toastType)
                    }
                }
            }
            
            #if os(macOS)
            HStack{
                Button(LocalizedStringKey("str.cancel")) {
                    if isNewProduct{
                        finishForm()
                    } else {
                        resetForm()
                    }
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button(LocalizedStringKey("str.save")) {
                    saveProduct()
                }
                .disabled(!isFormValid)
                .keyboardShortcut(.defaultAction)
            }
            #endif
        }
        .animation(.default)
        .onAppear(perform: {
            if firstAppear {
                grocyVM.requestData(objects: [.products, .quantity_units, .locations, .shopping_locations], ignoreCached: false)
                resetForm()
                firstAppear = false
            }
        })
    }
}

struct MDProductFormView_Previews: PreviewProvider {
    static var previews: some View {
        #if os(macOS)
        Group {
            MDProductFormView(isNewProduct: true, toastType: Binding.constant(nil))
            //            MDProductFormView(isNewProduct: false, product: MDProduct(id: "1", name: "Name", mdProductDescription: "Description", locationID: "locid", quIDPurchase: "quPurchase", quIDStock: <#T##String#>, quFactorPurchaseToStock: <#T##String#>, barcode: <#T##String?#>, minStockAmount: <#T##String#>, defaultDueDays: <#T##String#>, rowCreatedTimestamp: <#T##String#>, productGroupID: <#T##String?#>, pictureFileName: <#T##String?#>, defaultDueDaysAfterOpen: <#T##String#>, allowPartialUnitsInStock: <#T##String#>, enableTareWeightHandling: <#T##String#>, tareWeight: <#T##String#>, notCheckStockFulfillmentForRecipes: <#T##String#>, parentProductID: <#T##String?#>, calories: <#T##String?#>, cumulateMinStockAmountOfSubProducts: <#T##String#>, defaultDueDaysAfterFreezing: <#T##String#>, defaultDueDaysAfterThawing: <#T##String#>, shoppingLocationID: <#T##String?#>, userfields: <#T##Userfields?#>))
        }
        #else
        Group {
            NavigationView {
                MDProductFormView(isNewProduct: true, toastType: Binding.constant(nil))
            }
            //            NavigationView {
            //                MDProductFormView(isNewProduct: false, location: MDLocation(id: "1", name: "Loc", mdLocationDescription: "descr", rowCreatedTimestamp: "", isFreezer: "1", userfields: nil))
            //            }
        }
        #endif
    }
}
