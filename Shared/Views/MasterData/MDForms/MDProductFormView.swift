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
    
    @State private var name: String = "" // REQUIRED
    @State private var active: Bool = true
    @State private var parentProductID: String = ""
    @State private var mdProductDescription: String = ""
    @State private var locationID: String = "" // REQUIRED
    @State private var shoppingLocationID: String = ""
    @State private var minStockAmount: Double = 0.0
    @State private var cumulateMinStockAmountOfSubProducts: Bool = false
    @State private var dueType: DueType = DueType.bestBefore
    @State private var defaultDueDays: Int = 0
    @State private var defaultDueDaysAfterOpen: Int = 0
    @State private var productGroupID: String = "0"
    @State private var quIDStock: String = "" // REQUIRED
    @State private var quIDPurchase: String = "" // REQUIRED
    @State private var quFactorPurchaseToStock: Double = 1.0
    @State private var enableTareWeightHandling: Bool = false
    @State private var tareWeight: Double = 0.0
    @State private var notCheckStockFulfillmentForRecipes: Bool = false
    @State private var calories: Double = 0.0
    @State private var defaultDueDaysAfterFreezing: Int = 0
    @State private var defaultDueDaysAfterThawing: Int = 0
    @State private var quickConsumeAmount: Double = 1.0
    @State private var hideOnStockOverview: Bool = false
    
    @State private var barcodes: MDProductBarcodes = [] // wie läuft das denn ab?
    
    @State private var showDeleteAlert: Bool = false
    
    var isNewProduct: Bool
    var product: MDProduct?
    
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
    
    //    {"name":"Test1234567","active":"1","description":"<p>Asdf<br></p>","location_id":"2","shopping_location_id":"1","min_stock_amount":"1","cumulate_min_stock_amount_of_sub_products":"1","due_type":"2","default_best_before_days":"1","default_best_before_days_after_open":"2","product_group_id":"3","qu_id_stock":"2","qu_id_purchase":"11","qu_factor_purchase_to_stock":"3.1","enable_tare_weight_handling":"1","tare_weight":"2.2","not_check_stock_fulfillment_for_recipes":"1","calories":"3.2","default_best_before_days_after_freezing":"1","default_best_before_days_after_thawing":"5","quick_consume_amount":"1.2","hide_on_stock_overview":"1","parent_product_id":"27"}
    private func resetForm() {
        name = product?.name ?? ""
        active = (product?.active ?? "1") == "1"
        parentProductID = product?.parentProductID ?? ""
        mdProductDescription = product?.mdProductDescription ?? ""
        locationID = product?.locationID ?? ""
        shoppingLocationID = product?.shoppingLocationID ?? ""
        minStockAmount = Double(product?.minStockAmount ?? "") ?? 0.0
        cumulateMinStockAmountOfSubProducts = Bool(product?.cumulateMinStockAmountOfSubProducts ?? "") ?? false
        dueType = product?.dueType == DueType.bestBefore.rawValue ? DueType.bestBefore : DueType.expires
        defaultDueDays = Int(product?.defaultBestBeforeDays ?? "") ?? 0
        defaultDueDaysAfterOpen = Int(product?.defaultBestBeforeDaysAfterOpen ?? "") ?? 0
        productGroupID = product?.productGroupID ?? "0"
        quIDStock = product?.quIDStock ?? ""
        quIDPurchase = product?.quIDPurchase ?? ""
        quFactorPurchaseToStock = Double(product?.quFactorPurchaseToStock ?? "") ?? 1.0
        enableTareWeightHandling = (product?.enableTareWeightHandling ?? "0") == "1"
        tareWeight = Double(product?.tareWeight ?? "") ?? 0.0
        notCheckStockFulfillmentForRecipes = (product?.notCheckStockFulfillmentForRecipes ?? "0") == "1"
        calories = Double(product?.calories ?? "") ?? 0.0
        defaultDueDaysAfterFreezing = Int(product?.defaultBestBeforeDaysAfterThawing ?? "") ?? 0
        defaultDueDaysAfterThawing = Int(product?.defaultBestBeforeDaysAfterThawing ?? "") ?? 0
        quickConsumeAmount = Double(product?.quickConsumeAmount ?? "") ?? 1.0
        hideOnStockOverview = (product?.hideOnStockOverview ?? "0") == "1"
        isNameCorrect = checkNameCorrect()
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && isNameCorrect && !locationID.isEmpty && !quIDStock.isEmpty && !quIDPurchase.isEmpty
    }
    
    private func saveProduct() {
        let productPOST = MDProductPOST(id: isNewProduct ? grocyVM.findNextID(.products) : Int(product!.id)!, name: name, mdProductDescription: mdProductDescription, productGroupID: productGroupID, active: active ? "1" : "0", locationID: locationID, shoppingLocationID: shoppingLocationID, quIDPurchase: quIDPurchase, quIDStock: quIDStock, quFactorPurchaseToStock: quFactorPurchaseToStock, minStockAmount: minStockAmount, defaultBestBeforeDays: defaultDueDays, defaultBestBeforeDaysAfterOpen: defaultDueDaysAfterOpen, defaultBestBeforeDaysAfterFreezing: defaultDueDaysAfterFreezing, defaultBestBeforeDaysAfterThawing: defaultDueDaysAfterThawing, pictureFileName: nil, enableTareWeightHandling: enableTareWeightHandling ? "1" : "0", tareWeight: tareWeight, notCheckStockFulfillmentForRecipes: notCheckStockFulfillmentForRecipes ? "1" : "0", parentProductID: parentProductID, calories: calories, cumulateMinStockAmountOfSubProducts: cumulateMinStockAmountOfSubProducts ? "1" : "0", dueType: dueType.rawValue, quickConsumeAmount: quickConsumeAmount, rowCreatedTimestamp: isNewProduct ? Date().iso8601withFractionalSeconds : product!.rowCreatedTimestamp, hideOnStockOverview: hideOnStockOverview ? "1" : "0", userfields: nil)
        if isNewProduct {
            grocyVM.postMDObject(object: .products, content: productPOST)
        } else {
            grocyVM.putMDObjectWithID(object: .products, id: product!.id, content: productPOST)
        }
        grocyVM.getMDLocations()
    }
    
    private func deleteLocation() {
        grocyVM.deleteMDObject(object: .products, id: product!.id)
        grocyVM.getMDProducts()
    }
    
    var body: some View {
        #if os(macOS)
        ScrollView{
            content
                .padding()
        }
        #elseif os(iOS)
        content
            .navigationTitle(isNewProduct ? LocalizedStringKey("str.md.product.new") : LocalizedStringKey("str.md.product.edit"))
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    if isNewProduct {
                        Button(LocalizedStringKey("str.cancel")) {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("str.md.save \("str.md.product".localized)")) {
                        saveProduct()
                        presentationMode.wrappedValue.dismiss()
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
                    Picker(LocalizedStringKey("str.md.product.parentProduct"), selection: $parentProductID, content: {
                        ForEach(grocyVM.mdProducts, id:\.id) { grocyProduct in
                            Text(grocyProduct.name).tag(grocyProduct.id)
                        }
                    })
                    
                    // Product Description
                    MyTextField(textToEdit: $mdProductDescription, description: "str.md.product.description", isCorrect: Binding.constant(true), leadingIcon: "text.justifyleft", isEditing: true)
                }
                
                Section(header: Text(LocalizedStringKey("str.md.product.location")).font(.headline)) {
                    // Default Location - REQUIRED
                    VStack(alignment: .trailing) {
                        Picker(LocalizedStringKey("str.md.product.location"), selection: $locationID, content: {
                            ForEach(grocyVM.mdLocations, id:\.id) { grocyLocation in
                                Text(grocyLocation.name).tag(grocyLocation.id)
                            }
                        })
                        if locationID.isEmpty { Text(LocalizedStringKey("str.md.product.location.required")).foregroundColor(.red) }
                    }
                    
                    // Default Shopping Location
                    Picker(LocalizedStringKey("str.md.product.shoppingLocation"), selection: $shoppingLocationID, content: {
                        ForEach(grocyVM.mdShoppingLocations, id:\.id) { grocyShoppingLocation in
                            Text(grocyShoppingLocation.name).tag(grocyShoppingLocation.id)
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
                    ForEach(grocyVM.mdProductGroups, id:\.id) { grocyProductGroup in
                        Text(grocyProductGroup.name).tag(grocyProductGroup.id)
                    }
                })
                
                Section(header: Text(LocalizedStringKey("str.md.quantityUnits")).font(.headline)) {
                    // QU Stock - REQUIRED
                    VStack(alignment: .trailing){
                        HStack{
                            Picker(LocalizedStringKey("str.md.product.quStock"), selection: $quIDStock, content: {
                                ForEach(grocyVM.mdQuantityUnits, id:\.id) { grocyQuantityUnit in
                                    Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id)
                                }
                            })
                            .onChange(of: quIDStock, perform: { newValue in
                                if quIDPurchase.isEmpty {
                                    quIDPurchase = quIDStock
                                }
                            })
                            FieldDescription(description: "str.md.product.quStock.info")
                        }
                        if quIDStock.isEmpty { Text(LocalizedStringKey("str.md.product.quStock.required")).foregroundColor(.red) }
                    }
                    
                    // QU Purchase - REQUIRED
                    VStack(alignment: .trailing){
                        HStack{
                            Picker(LocalizedStringKey("str.md.product.quPurchase"), selection: $quIDPurchase, content: {
                                ForEach(grocyVM.mdQuantityUnits, id:\.id) { grocyQuantityUnit in
                                    Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id)
                                }
                            })
                            FieldDescription(description: "str.md.product.quPurchase.info")
                        }
                        if quIDPurchase.isEmpty { Text(LocalizedStringKey("str.md.product.quPurchase.required")).foregroundColor(.red) }
                    }
                    
                    VStack(alignment: .trailing) {
                        MyDoubleStepper(amount: $quFactorPurchaseToStock, description: "str.md.product.quFactorPurchaseToStock", minAmount: 0.0001, amountStep: 1.0, amountName: "", errorMessage: "str.md.product.quFactorPurchaseToStock.invalid", systemImage: "tag")
                        if quFactorPurchaseToStock != 1 { Text(LocalizedStringKey("str.md.product.quFactorPurchaseToStock.description \(currentQUPurchase?.name ?? "QU ERROR") \(String(format: "%.f", quFactorPurchaseToStock)) \(currentQUStock?.namePlural ?? "QU ERROR")")) }
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
                    MyDoubleStepper(amount: $quickConsumeAmount, description: "str.md.product.quickConsumeAmount", descriptionInfo: "str.md.product.quickConsumeAmount.info", minAmount: 0.0001, amountStep: 1.0, amountName: nil, errorMessage: "str.md.product.quickConsumeAmount.invalid", systemImage: "tuningfork")
                    
                    MyToggle(isOn: $hideOnStockOverview, description: "str.md.product.dontShowOnStockOverview", descriptionInfo: "str.md.product.dontShowOnStockOverview.info", icon: "tablecells")
                }
                
                if !isNewProduct {
                    MDBarcodesView(productID: product!.id)
                }
            }
            
            #if os(macOS)
            HStack{
                Button(LocalizedStringKey("str.cancel")) {
                    if isNewProduct{
                        NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                    } else {
                        resetForm()
                    }
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button(LocalizedStringKey("str.save")) {
                    saveProduct()
                    if isNewProduct{
                        NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                    }
                }
                .disabled(!isFormValid)
                .keyboardShortcut(.defaultAction)
            }
            #endif
        }
        .animation(.default)
        .onAppear(perform: {
            grocyVM.getMDProducts()
            grocyVM.getMDQuantityUnits()
            grocyVM.getMDLocations()
            grocyVM.getMDShoppingLocations()
            resetForm()
        })
    }
}

struct MDProductFormView_Previews: PreviewProvider {
    static var previews: some View {
        #if os(macOS)
        Group {
            MDProductFormView(isNewProduct: true)
            //            MDProductFormView(isNewProduct: false, product: MDProduct(id: "1", name: "Name", mdProductDescription: "Description", locationID: "locid", quIDPurchase: "quPurchase", quIDStock: <#T##String#>, quFactorPurchaseToStock: <#T##String#>, barcode: <#T##String?#>, minStockAmount: <#T##String#>, defaultDueDays: <#T##String#>, rowCreatedTimestamp: <#T##String#>, productGroupID: <#T##String?#>, pictureFileName: <#T##String?#>, defaultDueDaysAfterOpen: <#T##String#>, allowPartialUnitsInStock: <#T##String#>, enableTareWeightHandling: <#T##String#>, tareWeight: <#T##String#>, notCheckStockFulfillmentForRecipes: <#T##String#>, parentProductID: <#T##String?#>, calories: <#T##String?#>, cumulateMinStockAmountOfSubProducts: <#T##String#>, defaultDueDaysAfterFreezing: <#T##String#>, defaultDueDaysAfterThawing: <#T##String#>, shoppingLocationID: <#T##String?#>, userfields: <#T##Userfields?#>))
        }
        #else
        Group {
            NavigationView {
                MDProductFormView(isNewProduct: true)
            }
            //            NavigationView {
            //                MDProductFormView(isNewProduct: false, location: MDLocation(id: "1", name: "Loc", mdLocationDescription: "descr", rowCreatedTimestamp: "", isFreezer: "1", userfields: nil))
            //            }
        }
        #endif
    }
}
