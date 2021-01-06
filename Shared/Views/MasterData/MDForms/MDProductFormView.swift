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
    @State private var minStockAmount: Int = 0
    @State private var cumulateMinStockAmountOfSubProducts: Bool = false
    @State private var dueType: DueType = DueType.bestBefore
    @State private var defaultDueDays: Int = 0
    @State private var defaultDueDaysAfterOpen: Int = 0
    @State private var productGroupID: String = "0"
    @State private var quIDStock: String = "" // REQUIRED
    @State private var quIDPurchase: String = "" // REQUIRED
    @State private var quFactorPurchaseToStock: Int = 1
    @State private var enableTareWeightHandling: String = "0"
    @State private var tareWeight: String = "0"
    @State private var notCheckStockFulfillmentForRecipes: String = "0"
    @State private var calories: Double = 0.0
    @State private var defaultDueDaysAfterFreezing: String = "0"
    @State private var defaultDueDaysAfterThawing: String = "0"
    @State private var quickConsumeAmount: Double = 1.0
    @State private var neverShowOnStockOverview: Bool = false
    
    @State private var barcodes: MDProductBarcodes = [] // wie läuft das denn ab?
    
    @State private var showDeleteAlert: Bool = false
    
    var isNewProduct: Bool
    var product: MDProduct?
    
    @State var isNameCorrect: Bool = false
    private func checkNameCorrect() -> Bool {
        let foundProduct = grocyVM.mdProducts.first(where: {$0.name == name})
        return isNewProduct ? !(name.isEmpty || foundProduct != nil) : !(name.isEmpty || (foundProduct != nil && foundProduct!.id != product!.id))
    }
    
    private func resetForm() {
        if isNewProduct {
            self.name = ""
            self.mdProductDescription = ""
        } else {
            self.name = product!.name
            self.mdProductDescription = product!.mdProductDescription ?? ""
        }
        isNameCorrect = checkNameCorrect()
    }
    
    private func saveProduct() {
        if isNewProduct {
            grocyVM.postMDObject(object: .products, content: MDProductPOST(id: grocyVM.findNextID(.products),
                                                                           name: name,
                                                                           mdProductDescription: mdProductDescription,
                                                                           locationID: locationID,
                                                                           quIDPurchase: quIDPurchase,
                                                                           quIDStock: quIDStock,
                                                                           quFactorPurchaseToStock: String(quFactorPurchaseToStock),
                                                                           barcode: "",
                                                                           minStockAmount: String(minStockAmount),
                                                                           defaultBestBeforeDays: String(defaultDueDays),
                                                                           rowCreatedTimestamp: Date().iso8601withFractionalSeconds,
                                                                           productGroupID: productGroupID,
                                                                           pictureFileName: nil,
                                                                           defaultBestBeforeDaysAfterOpen: String(defaultDueDaysAfterOpen),
                                                                           allowPartialUnitsInStock: "0",
                                                                           enableTareWeightHandling: enableTareWeightHandling,
                                                                           tareWeight: tareWeight,
                                                                           notCheckStockFulfillmentForRecipes: notCheckStockFulfillmentForRecipes,
                                                                           parentProductID: nil,
                                                                           calories: "",
                                                                           cumulateMinStockAmountOfSubProducts: String(cumulateMinStockAmountOfSubProducts),
                                                                           defaultBestBeforeDaysAfterFreezing: defaultDueDaysAfterFreezing,
                                                                           defaultBestBeforeDaysAfterThawing: defaultDueDaysAfterThawing,
                                                                           shoppingLocationID: shoppingLocationID,
                                                                           userfields: nil))
        } else {
            grocyVM.putMDObjectWithID(object: .products, id: product!.id, content: MDProductPOST(id: Int(product!.id)!,
                                                                                                 name: name,
                                                                                                 mdProductDescription: mdProductDescription,
                                                                                                 locationID: locationID,
                                                                                                 quIDPurchase: quIDPurchase,
                                                                                                 quIDStock: quIDStock,
                                                                                                 quFactorPurchaseToStock: String(quFactorPurchaseToStock),
                                                                                                 barcode: "",
                                                                                                 minStockAmount: String(minStockAmount),
                                                                                                 defaultBestBeforeDays: String(defaultDueDays),
                                                                                                 rowCreatedTimestamp: product!.rowCreatedTimestamp,
                                                                                                 productGroupID: productGroupID,
                                                                                                 pictureFileName: nil,
                                                                                                 defaultBestBeforeDaysAfterOpen: String(defaultDueDaysAfterOpen),
                                                                                                 allowPartialUnitsInStock: "0",
                                                                                                 enableTareWeightHandling: enableTareWeightHandling,
                                                                                                 tareWeight: tareWeight,
                                                                                                 notCheckStockFulfillmentForRecipes: notCheckStockFulfillmentForRecipes,
                                                                                                 parentProductID: nil,
                                                                                                 calories: "",
                                                                                                 cumulateMinStockAmountOfSubProducts: String(cumulateMinStockAmountOfSubProducts),
                                                                                                 defaultBestBeforeDaysAfterFreezing: defaultDueDaysAfterFreezing,
                                                                                                 defaultBestBeforeDaysAfterThawing: defaultDueDaysAfterThawing,
                                                                                                 shoppingLocationID: shoppingLocationID,
                                                                                                 userfields: nil))
        }
        grocyVM.getMDLocations()
    }
    
    private func deleteLocation() {
        grocyVM.deleteMDObject(object: .products, id: product!.id)
        grocyVM.getMDProducts()
    }
    
    var body: some View {
        #if os(macOS)
        content
            .padding()
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
                    }.disabled(!isNameCorrect)
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
                VStack(alignment: .leading) {
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
                MyIntStepper(amount: $minStockAmount, description: "str.md.product.minStockAmount", minAmount: 0)
                
                // Accumulate sub products min stock amount
                MyToggle(isOn: $cumulateMinStockAmountOfSubProducts, description: "str.md.product.cumulateMinStockAmountOfSubProducts", descriptionInfo: "str.md.product.cumulateMinStockAmountOfSubProducts.info")
                
            }
            
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
                // Product group
                Picker(LocalizedStringKey("str.md.product.quStock"), selection: $quIDStock, content: {
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id)
                    }
                })
                
                // QU Purchase - REQUIRED
                Picker(LocalizedStringKey("str.md.product.quPurchase"), selection: $quIDPurchase, content: {
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id)
                    }
                })
            }
            
            Section(header: Text(LocalizedStringKey("str.stock.stockOverview")).font(.headline)) {
                MyDoubleStepper(amount: $quickConsumeAmount, description: "str.md.product.quickConsumeAmount", descriptionInfo: "str.md.product.quickConsumeAmount.info", minAmount: 0.0001, amountStep: 1.0, amountName: nil, errorMessage: "str.md.product.quickConsumeAmount.invalid", systemImage: "tuningfork")
                
                MyToggle(isOn: $neverShowOnStockOverview, description: "str.md.product.dontShowOnStockOverview", descriptionInfo: "str.md.product.dontShowOnStockOverview.info", icon: "tablecells")
            }
            
            if !isNewProduct {
                MDBarcodesView(productID: product!.id)
            }
            
            #if os(macOS)
            HStack{
                Button(LocalizedStringKey("str.cancel")) {
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button(LocalizedStringKey("str.save")) {
                    saveProduct()
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.defaultAction)
            }
            #endif
            if !isNewProduct {
                Button(action: {
                    showDeleteAlert.toggle()
                }, label: {
                    Label(LocalizedStringKey("str.md.product.delete"), systemImage: "trash")
                        .foregroundColor(.red)
                })
                .keyboardShortcut(.delete)
                .alert(isPresented: $showDeleteAlert) {
                    Alert(title: Text(LocalizedStringKey("str.md.product.delete.confirm")), message: Text(""), primaryButton: .destructive(Text("str.delete")) {
                        deleteLocation()
                        #if os(macOS)
                        NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                        #else
                        presentationMode.wrappedValue.dismiss()
                        #endif
                    }, secondaryButton: .cancel())
                }
            }
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
