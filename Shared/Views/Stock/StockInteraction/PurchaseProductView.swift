//
//  PurchaseProductView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.11.20.
//

import SwiftUI
import SwiftData

struct PurchaseProductView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(filter: #Predicate<MDProduct>{$0.active}, sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(filter: #Predicate<MDQuantityUnit>{$0.active}, sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \MDQuantityUnitConversion.id, order: .forward) var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query(filter: #Predicate<MDStore>{$0.active}, sort: \MDStore.id, order: .forward) var mdStores: MDStores
    @Query(filter: #Predicate<MDLocation>{$0.active}, sort: \MDLocation.id, order: .forward) var mdLocations: MDLocations
    @Query() var detailsList: [StockProductDetails]
    var productDetails: StockProductDetails? {
        return detailsList.first(where: { $0.productID == stockElement?.productID })
    }
    
    @Environment(\.dismiss) var dismiss
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    @State private var firstAppear: Bool = true
    @State private var isProcessingAction: Bool = false
    
    var stockElement: StockElement? = nil
    var directProductToPurchaseID: Int? = nil
    var productToPurchaseID: Int? {
        return directProductToPurchaseID ?? stockElement?.productID
    }
    
    var productToPurchaseAmount: Double?
    var autoPurchase: Bool = false
    var barcode: MDProductBarcode? = nil
    var quickScan: Bool = false
    var actionFinished: Binding<Bool>? = nil
    
    @State private var productID: Int?
    @State private var amount: Double = 0.0
    @State private var quantityUnitID: Int?
    @State private var dueDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var productDoesntSpoil: Bool = false
    @State private var price: Double?
    @State private var isTotalPrice: Bool = false
    @State private var storeID: Int?
    @State private var locationID: Int?
    @State private var note: String = ""
    @State private var selfProduction: Bool = false
    
    private let dataToUpdate: [ObjectEntities] = [.products, .quantity_units, .quantity_unit_conversions, .locations, .shopping_locations, .product_barcodes]
    private let additionalDataToUpdate: [AdditionalEntities] = [.system_config, .system_info]
    
    
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }
    
    private var product: MDProduct? {
        mdProducts.first(where: { $0.id == productID })
    }
    
    private var currentQuantityUnit: MDQuantityUnit? {
        return mdQuantityUnits.first(where: { $0.id == quantityUnitID })
    }
    
    private var stockQuantityUnit: MDQuantityUnit? {
        return mdQuantityUnits.first(where: { $0.id == product?.quIDStock })
    }
    
    private var quantityUnitConversions: [MDQuantityUnitConversion] {
        if let quIDStock = product?.quIDStock {
            return mdQuantityUnitConversions.filter { $0.toQuID == quIDStock }
        } else { return [] }
    }
    
    private var factoredAmount: Double {
        return amount * (quantityUnitConversions.first(where: { $0.fromQuID == quantityUnitID })?.factor ?? 1)
    }
    
    private var unitPrice: Double? {
        if isTotalPrice {
            return ((price ?? 0.0) / factoredAmount)
        } else {
            return price
        }
    }
    
    var isFormValid: Bool {
        (productID != nil) && (amount > 0) && (quantityUnitID != nil)
    }
    
    private func resetForm() {
        self.productID = firstAppear ? productToPurchaseID : nil
//        self.amount = firstAppear ? (productToPurchaseAmount ?? barcode?.amount ?? grocyVM.userSettings?.stockDefaultPurchaseAmount ?? 1.0) : (grocyVM.userSettings?.stockDefaultPurchaseAmount ?? 1.0)
        self.amount = 1.0
        self.quantityUnitID = barcode?.quID ?? (firstAppear ? product?.quIDPurchase : nil)
        if product?.defaultDueDays ?? 0 == -1 {
            self.productDoesntSpoil = true
            self.dueDate = Calendar.current.startOfDay(for: Date())
        } else {
            self.productDoesntSpoil = false
            let dateComponents = DateComponents(day: product?.defaultDueDays ?? 0)
            self.dueDate = Calendar.current.date(byAdding: dateComponents, to: Calendar.current.startOfDay(for: Date())) ?? Calendar.current.startOfDay(for: Date())
        }
        self.price = nil
        self.isTotalPrice = false
        self.storeID = barcode?.storeID
        self.locationID = nil
        self.note = ""
        if autoPurchase, firstAppear, product?.defaultDueDays != nil, let productID = productID, isFormValid {
            self.price = productDetails?.lastPrice
            Task {
                await purchaseProduct()
            }
        }
    }
    
    private func purchaseProduct() async {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let strDueDate = productDoesntSpoil ? "2999-12-31" : dateFormatter.string(from: dueDate)
        let noteText = note.isEmpty ? nil : note
        let purchasePrice = selfProduction ? nil : unitPrice
        let purchaseStoreID = selfProduction ? nil : storeID
        let purchaseInfo = ProductBuy(amount: amount, bestBeforeDate: strDueDate, transactionType: selfProduction ? .selfProduction : .purchase, price: purchasePrice, locationID: locationID, storeID: purchaseStoreID, note: noteText)
        if let productID = productID {
            isProcessingAction = true
            do {
                try await grocyVM.postStockObject(id: productID, stockModePost: .add, content: purchaseInfo)
                await grocyVM.postLog("Purchase \(product?.name ?? String(productID)) successful.", type: .info)
                await grocyVM.requestData(additionalObjects: [.stock, .volatileStock])
                resetForm()
                if autoPurchase {
                    self.dismiss()
                }
                if self.actionFinished != nil {
                    self.actionFinished?.wrappedValue = true
                }
            } catch {
                await grocyVM.postLog("Purchase failed: \(error)", type: .error)
            }
            isProcessingAction = false
        }
    }
    
    var body: some View {
        Form {
            if grocyVM.failedToLoadObjects.filter({ dataToUpdate.contains($0) }).count > 0 || grocyVM.failedToLoadAdditionalObjects.filter({ additionalDataToUpdate.contains($0) }).count > 0 {
                Section {
                    ServerProblemView(isCompact: true)
                }
            }
            
            if !quickScan {
//                ProductField(productID: $productID, description: "Product")
                ProductFieldNew(productID: $productID, description: "Product")
                    .onChange(of: productID) {
                        if let selectedProduct = mdProducts.first(where: { $0.id == productID }) {
                            if locationID == nil { locationID = selectedProduct.locationID }
                            if storeID == nil { storeID = selectedProduct.storeID }
                            quantityUnitID = selectedProduct.quIDPurchase
                            if product?.defaultDueDays == -1 {
                                productDoesntSpoil = true
                                dueDate = Calendar.current.startOfDay(for: Date())
                            } else {
                                productDoesntSpoil = false
                                dueDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: product?.defaultDueDays ?? 0, to: Date()) ?? Date())
                            }
                        }
                    }
            }
            
            if productID != nil {
                
                AmountSelectionView(productID: $productID, amount: $amount, quantityUnitID: $quantityUnitID)
                
                Section("Due date") {
                    DatePicker(selection: $dueDate, displayedComponents: .date, label: {
                        Label {
                            Text("Due date")
                            if !productDoesntSpoil {
                                Text(getRelativeDateAsText(dueDate, localizationKey: localizationKey) ?? "")
                                    .foregroundStyle(.secondary)
                                    .italic()
                            }
                        } icon: {
                            Image(systemName: MySymbols.date)
                        }
                    })
                    .foregroundStyle(.primary)
                    .disabled(productDoesntSpoil)
                    
                    MyToggle(isOn: $productDoesntSpoil, description: "Never overdue", descriptionInfo: nil, icon: MySymbols.doesntSpoil)
                }
                
                if !selfProduction {
                    Section("Price") {
                        VStack(alignment: .leading) {
                            MyDoubleStepperOptional(amount: $price, description: "Price", minAmount: 0, amountStep: 1.0, amountName: "", systemImage: MySymbols.price, currencySymbol: getCurrencySymbol())
                            
                            if isTotalPrice && productID != nil {
                                Text("means \(grocyVM.getFormattedCurrency(amount: unitPrice ?? 0)) per \(currentQuantityUnit?.name ?? "")")
                                    .font(.caption)
                                    .foregroundStyle(Color(.GrocyColors.grocyGray))
                            }
                        }
                        
                        if price != nil {
                            Picker("", selection: $isTotalPrice, content: {
                                Text("\(currentQuantityUnit?.name ?? "Unit") price")
                                    .tag(false)
                                Text("Total price")
                                    .tag(true)
                            })
                            .pickerStyle(.segmented)
                        }
                    }
                }
                
                Section("Location") {
                    if !selfProduction {
                        Picker(selection: $storeID,
                               label: Label("Store", systemImage: MySymbols.store).foregroundStyle(.primary),
                               content: {
                            Text("").tag(nil as Int?)
                            ForEach(mdStores, id: \.id) { store in
                                Text(store.name).tag(store.id as Int?)
                            }
                        })
                    }
                    
                    Picker(selection: $locationID,
                           label: Label("Location", systemImage: MySymbols.location).foregroundStyle(.primary),
                           content: {
                        Text("").tag(nil as Int?)
                        ForEach(mdLocations, id: \.id) { location in
                            Text(location.id == product?.locationID ? "\(location.name) (Default location)" : location.name)
                                .tag(location.id as Int?)
                        }
                    })
                }
                MyTextField(textToEdit: $note, description: "Note", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
                
                MyToggle(isOn: $selfProduction, description: "Self-production", icon: MySymbols.selfProduction)
            }
        }
        .navigationTitle("Purchase")
        .formStyle(.grouped)
        .task {
            if firstAppear {
                await updateData()
                resetForm()
                firstAppear = false
            }
        }
        .toolbar(content: {
            ToolbarItemGroup(placement: .automatic, content: {
                Group {
                    if !quickScan {
                        if isProcessingAction {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Button(action: resetForm, label: {
                                Label("Clear", systemImage: MySymbols.cancel)
                                    .help("Clear")
                            })
                            .keyboardShortcut("r", modifiers: [.command])
                        }
                    }
                    Button(action: {
                        Task {
                            await purchaseProduct()
                        }
                    }, label: {
                        Label("Purchase product", systemImage: MySymbols.purchase)
                            .labelStyle(.titleAndIcon)
                    })
                    .disabled(!isFormValid || isProcessingAction)
                    .keyboardShortcut("s", modifiers: [.command])
                }
            })
        })
    }
}

#Preview {
    PurchaseProductView()
}
