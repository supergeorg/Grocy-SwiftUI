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
    @State private var defaultBestBeforeDays: Int = 0
    @State private var defaultBestBeforeDaysAfterOpen: Int = 0
    @State private var productGroupID: String = "0"
    @State private var quIDStock: String = "" // REQUIRED
    @State private var quIDPurchase: String = "" // REQUIRED
    @State private var quFactorPurchaseToStock: Int = 1
    @State private var enableTareWeightHandling: String = "0"
    @State private var tareWeight: String = "0"
    @State private var notCheckStockFulfillmentForRecipes: String = "0"
    @State private var calories: Double = 0.0
    @State private var defaultBestBeforeDaysAfterFreezing: String = "0"
    @State private var defaultBestBeforeDaysAfterThawing: String = "0"
    @State private var quickConsumeAmount: Double = 1.0
    
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
                                                                           defaultBestBeforeDays: String(defaultBestBeforeDays),
                                                                           rowCreatedTimestamp: Date().iso8601withFractionalSeconds,
                                                                           productGroupID: productGroupID,
                                                                           pictureFileName: nil,
                                                                           defaultBestBeforeDaysAfterOpen: String(defaultBestBeforeDaysAfterOpen),
                                                                           allowPartialUnitsInStock: "0",
                                                                           enableTareWeightHandling: enableTareWeightHandling,
                                                                           tareWeight: tareWeight,
                                                                           notCheckStockFulfillmentForRecipes: notCheckStockFulfillmentForRecipes,
                                                                           parentProductID: nil,
                                                                           calories: "",
                                                                           cumulateMinStockAmountOfSubProducts: String(cumulateMinStockAmountOfSubProducts),
                                                                           defaultBestBeforeDaysAfterFreezing: defaultBestBeforeDaysAfterFreezing,
                                                                           defaultBestBeforeDaysAfterThawing: defaultBestBeforeDaysAfterThawing,
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
                                                                                                 defaultBestBeforeDays: String(defaultBestBeforeDays),
                                                                                                 rowCreatedTimestamp: product!.rowCreatedTimestamp,
                                                                                                 productGroupID: productGroupID,
                                                                                                 pictureFileName: nil,
                                                                                                 defaultBestBeforeDaysAfterOpen: String(defaultBestBeforeDaysAfterOpen),
                                                                                                 allowPartialUnitsInStock: "0",
                                                                                                 enableTareWeightHandling: enableTareWeightHandling,
                                                                                                 tareWeight: tareWeight,
                                                                                                 notCheckStockFulfillmentForRecipes: notCheckStockFulfillmentForRecipes,
                                                                                                 parentProductID: nil,
                                                                                                 calories: "",
                                                                                                 cumulateMinStockAmountOfSubProducts: String(cumulateMinStockAmountOfSubProducts),
                                                                                                 defaultBestBeforeDaysAfterFreezing: defaultBestBeforeDaysAfterFreezing,
                                                                                                 defaultBestBeforeDaysAfterThawing: defaultBestBeforeDaysAfterThawing,
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
        Form {
            //            @State private var quIDStock: String = "" // REQUIRED
            //            @State private var quIDPurchase: String = "" // REQUIRED
            //            @State private var quFactorPurchaseToStock: Int = 1
            //            @State private var enableTareWeightHandling: String = "0"
            //            @State private var tareWeight: String = "0"
            //            @State private var notCheckStockFulfillmentForRecipes: String = "0"
            //            @State private var calories: Double = 0.0
            //            @State private var defaultBestBeforeDaysAfterFreezing: String = "0"
            //            @State private var defaultBestBeforeDaysAfterThawing: String = "0"
            //            @State private var quickConsumeAmount: Double = 1.0
            Group {
                
                // Name - REQUIRED
                MyTextField(textToEdit: $name, description: "str.md.product.name", isCorrect: $isNameCorrect, leadingIcon: "tag", isEditing: true, errorMessage: "str.md.product.name.required")
                    .onChange(of: name, perform: { value in
                        isNameCorrect = checkNameCorrect()
                    })
                
                // Active
                Toggle("str.md.product.active", isOn: $active)
                
                // Parent Product
                Picker("str.md.product.parentProduct", selection: $parentProductID, content: {
                    ForEach(grocyVM.mdProducts, id:\.id) { grocyProduct in
                        Text(grocyProduct.name).tag(grocyProduct.id)
                    }
                })
                
                // Product Description
                MyTextField(textToEdit: $mdProductDescription, description: "str.md.description", isCorrect: Binding.constant(true), leadingIcon: "text.justifyleft", isEditing: true)
                
            }
            
            Group {
                
                VStack(alignment: .leading) {
                // Default Location - REQUIRED
                Picker("str.md.product.locationID", selection: $locationID, content: {
                    ForEach(grocyVM.mdLocations, id:\.id) { grocyLocation in
                        Text(grocyLocation.name).tag(grocyLocation.id)
                    }
                })
                if locationID.isEmpty { Text("str.md.product.locationID.required").foregroundColor(.red) }
                }
                
                // Default Shopping Location
                Picker("str.md.product.shoppingLocationID", selection: $shoppingLocationID, content: {
                    ForEach(grocyVM.mdShoppingLocations, id:\.id) { grocyShoppingLocation in
                        Text(grocyShoppingLocation.name).tag(grocyShoppingLocation.id)
                    }
                })
                
                // Min Stock amount
                MyIntStepper(amount: $minStockAmount, description: "str.md.product.minStockAmount", minAmount: 0)
                
                // Accumulate sub products min stock amount
                MyToggle(isOn: $cumulateMinStockAmountOfSubProducts, description: "str.md.product.cumulateMinStockAmountOfSubProducts", descriptionInfo: "str.md.product.cumulateMinStockAmountOfSubProducts.info")
                
            }
            
            Group {
                
                // Due Type, default best before
                Picker("str.md.product.dueType", selection: $dueType, content: {
                    Text("str.md.product.dueType.bestBefore").tag(DueType.bestBefore)
                    Text("str.md.product.dueType.expires").tag(DueType.expires)
                }).pickerStyle(SegmentedPickerStyle())
                
                // Default due days
                MyIntStepper(amount: $defaultBestBeforeDays, description: "str.md.product.defaultBestBeforeDays", helpText: "str.md.product.defaultBestBeforeDays.info", minAmount: 0, amountName: defaultBestBeforeDays == 1 ? "str.day" : "str.days")
                
                // Default due days afer opening
                MyIntStepper(amount: $defaultBestBeforeDaysAfterOpen, description: "str.md.product.defaultBestBeforeDaysAfterOpen", helpText: "str.md.product.defaultBestBeforeDaysAfterOpen.info", minAmount: 0, amountName: defaultBestBeforeDaysAfterOpen == 1 ? "str.day" : "str.days")
                
                // Product group
                Picker("str.md.product.productGroup", selection: $productGroupID, content: {
                    ForEach(grocyVM.mdProductGroups, id:\.id) { grocyProductGroup in
                        Text(grocyProductGroup.name).tag(grocyProductGroup.id)
                    }
                })
            }
            
            Group {
                // QU Stock - REQUIRED
                // Product group
                Picker("str.md.product.quIDStock", selection: $quIDStock, content: {
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id)
                    }
                })
                
                // QU Purchase - REQUIRED
                Picker("str.md.product.quIDPurchase", selection: $quIDPurchase, content: {
                    ForEach(grocyVM.mdQuantityUnits, id:\.id) { grocyQuantityUnit in
                        Text(grocyQuantityUnit.name).tag(grocyQuantityUnit.id)
                    }
                })
            }
            
            if !isNewProduct {
                MDBarcodesView(productID: product!.id)
            }
            
            #if os(macOS)
            HStack{
                Button("str.cancel") {
                    NSApp.sendAction(#selector(NSPopover.performClose(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("str.save") {
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
                    Label("str.md.delete \("str.md.product".localized)", systemImage: "trash")
                        .foregroundColor(.red)
                })
                .keyboardShortcut(.delete)
                .alert(isPresented: $showDeleteAlert) {
                    Alert(title: Text("str.md.product.delete.confirm"), message: Text(""), primaryButton: .destructive(Text("str.delete")) {
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
        .navigationTitle(isNewProduct ? "str.md.product.new" : "str.md.product.edit")
        .animation(.default)
        .onAppear(perform: {
            grocyVM.getMDProducts()
            grocyVM.getMDQuantityUnits()
            grocyVM.getMDLocations()
            grocyVM.getMDShoppingLocations()
            resetForm()
        })
        .toolbar(content: {
            #if os(iOS)
            ToolbarItem(placement: .cancellationAction) {
                if isNewProduct {
                    Button("str.cancel") {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("str.md.save \("str.md.location".localized)") {
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
            #endif
        })
    }
}

struct MDProductFormView_Previews: PreviewProvider {
    static var previews: some View {
        #if os(macOS)
        Group {
            MDProductFormView(isNewProduct: true)
            //            MDProductFormView(isNewProduct: false, product: MDProduct(id: "1", name: "Name", mdProductDescription: "Description", locationID: "locid", quIDPurchase: "quPurchase", quIDStock: <#T##String#>, quFactorPurchaseToStock: <#T##String#>, barcode: <#T##String?#>, minStockAmount: <#T##String#>, defaultBestBeforeDays: <#T##String#>, rowCreatedTimestamp: <#T##String#>, productGroupID: <#T##String?#>, pictureFileName: <#T##String?#>, defaultBestBeforeDaysAfterOpen: <#T##String#>, allowPartialUnitsInStock: <#T##String#>, enableTareWeightHandling: <#T##String#>, tareWeight: <#T##String#>, notCheckStockFulfillmentForRecipes: <#T##String#>, parentProductID: <#T##String?#>, calories: <#T##String?#>, cumulateMinStockAmountOfSubProducts: <#T##String#>, defaultBestBeforeDaysAfterFreezing: <#T##String#>, defaultBestBeforeDaysAfterThawing: <#T##String#>, shoppingLocationID: <#T##String?#>, userfields: <#T##Userfields?#>))
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
