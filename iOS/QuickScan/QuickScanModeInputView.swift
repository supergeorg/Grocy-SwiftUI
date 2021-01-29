//
//  QuickScanModeInputView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 06.01.21.
//

import SwiftUI
import URLImage

struct QuickScanModeInputView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstOpen: Bool = true
    
    @Binding var quickScanMode: QuickScanMode
    @Binding var productBarcode: MDProductBarcode?
    @Binding var firstInSession: Bool
    
    @Binding var toastType: QSToastType?
    @Binding var infoString: String?
    
    @State private var useBarcodeAmount: Bool = true
    
    var barcode: MDProductBarcode {
        productBarcode ?? MDProductBarcode(id: "", productID: "", barcode: "", quID: nil, amount: nil, shoppingLocationID: nil, lastPrice: nil, rowCreatedTimestamp: "", note: nil, userfields: nil)
    }
    
    var product: MDProduct? {
        grocyVM.mdProducts.first(where: {$0.id == productBarcode?.productID})
    }
    var quantityUnit: MDQuantityUnit? {
        quickScanMode == .purchase ? grocyVM.mdQuantityUnits.first(where: {$0.id == product?.quIDPurchase}) : grocyVM.mdQuantityUnits.first(where: {$0.id == product?.quIDStock})
    }
    private func getQUString(amount: Int) -> String {
        return amount == 1 ? quantityUnit?.name ?? "" : quantityUnit?.namePlural ?? ""
    }
    
    @AppStorage("quickScanConsumeAskLocation") var quickScanConsumeAskLocation: QuickScanAskMode = QuickScanAskMode.always
    @State private var consumeLocationID: String?
    @AppStorage("quickScanConsumeAskSpecificItem") var quickScanConsumeAskSpecificItem: QuickScanAskMode = QuickScanAskMode.always
    @State private var consumeItemID: String?
    @AppStorage("quickScanConsumeConsumeAll") var quickScanConsumeConsumeAll: Bool = false
    
    @AppStorage("quickScanMarkAsOpenedAskSpecificItem") var quickScanMarkAsOpenedAskSpecificItem: QuickScanAskMode = QuickScanAskMode.always
    @State private var markAsOpenItemID: String?
    
    @AppStorage("quickScanPurchaseAskDueDate") var quickScanPurchaseAskDueDate: QuickScanAskMode = QuickScanAskMode.always
    @State private var purchaseDueDate: Date = Date()
    @AppStorage("quickScanPurchaseAskPrice") var quickScanPurchaseAskPrice: QuickScanAskMode = QuickScanAskMode.always
    @State private var purchasePrice: Double?
    @AppStorage("quickScanPurchaseAskStore") var quickScanPurchaseAskStore: QuickScanAskMode = QuickScanAskMode.always
    @State private var purchaseShoppingLocationID: String?
    @AppStorage("quickScanPurchaseAskLocation") var quickScanPurchaseAskLocation: QuickScanAskMode = QuickScanAskMode.always
    @State private var purchaseLocationID: String?
    
    private func consumeItem() {
        if let id = productBarcode?.productID {
            let amount = useBarcodeAmount ? Double(productBarcode?.amount ?? "") ?? 1.0 : 1.0
            let productConsume = ProductConsume(amount: amount, transactionType: .consume, spoiled: false, stockEntryID: consumeItemID, recipeID: nil, locationID: Int(consumeLocationID ?? ""), exactAmount: nil, allowSubproductSubstitution: nil)
            infoString = "\(formatAmount(amount)) \(getQUString(amount: Int(amount))) \(product?.name ?? "")"
            grocyVM.postStockObject(id: id, stockModePost: .consume, content: productConsume) { result in
                switch result {
                case let .success(prod):
                    print(prod)
                    toastType = .successQSConsume
                    finalizeQuickInput()
                case let .failure(error):
                    print("\(error)")
                    toastType = .failQSConsume
                }
            }
        }
    }
    
    private func markAsOpenedItem() {
        if let id = productBarcode?.productID {
            let productOpen = ProductOpen(amount: 1.0, stockEntryID: markAsOpenItemID, allowSubproductSubstitution: nil)
            infoString = "1 \(getQUString(amount: 1)) \(product?.name ?? "")"
            grocyVM.postStockObject(id: id, stockModePost: .open, content: productOpen) { result in
                switch result {
                case let .success(prod):
                    print(prod)
                    toastType = .successQSOpen
                    finalizeQuickInput()
                case let .failure(error):
                    print("\(error)")
                    toastType = .failQSOpen
                }
            }
        }
    }
    
    private func purchaseItem() {
        if let id = productBarcode?.productID {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let priceStr = purchasePrice != nil ? String(purchasePrice ?? 0) : nil
            let productBuy = ProductBuy(amount: 1.0, bestBeforeDate: dateFormatter.string(from: purchaseDueDate), transactionType: .purchase, price: priceStr, locationID: Int(purchaseLocationID ?? ""), shoppingLocationID: Int(purchaseShoppingLocationID ?? ""))
            infoString = "1 \(getQUString(amount: 1)) \(product?.name ?? "")"
            grocyVM.postStockObject(id: id, stockModePost: .add, content: productBuy) { result in
                switch result {
                case let .success(prod):
                    print(prod)
                    toastType = .successQSPurchase
                    finalizeQuickInput()
                case let .failure(error):
                    print("\(error)")
                    toastType = .failQSPurchase
                }
            }
        }
    }
    
    private func finalizeQuickInput() {
        firstInSession = false
        self.presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        NavigationView{
            Form {
                if let productU = product {
                    Section() {
                        HStack{
                            if let pictureFileName = productU.pictureFileName {
                                let utf8str = pictureFileName.data(using: .utf8)
                                if let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
                                    if let pictureURL = grocyVM.getPictureURL(groupName: "productpictures", fileName: base64Encoded) {
                                        if let url = URL(string: pictureURL) {
                                            URLImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .background(Color.white)
                                            }
                                            .frame(width: 50, height: 50)
                                        }
                                    }
                                }
                            }
                            VStack(alignment: .leading) {
                                Text(productU.name).font(.title)
                                if let amount = barcode.amount {
                                    Text(LocalizedStringKey("str.quickScan.input.info.consumeAmount \("\(formatStringAmount(amount)) \(amount == "1.0" ? quantityUnit?.name ?? "" : quantityUnit?.namePlural ?? "")")"))
                                }
                            }
                        }
                    }
                }
                
                if quickScanMode == .consume {
                    Group {
                        if let amount = barcode.amount {
                            if amount != "1.0" {
                                VStack(alignment: .leading){
                                    Text(LocalizedStringKey("str.md.product.quickConsumeAmount"))
                                    Picker(selection: $useBarcodeAmount, label: Text(""), content: {
                                        Text("str.quickScan.input.consumeDefault").tag(false)
                                        Text("str.quickScan.input.consumeBarcodeAmount \(formatStringAmount(amount))").tag(true)
                                    }).pickerStyle(SegmentedPickerStyle())
                                }
                            }
                        }
                        
                        if quickScanConsumeAskLocation == .always {
                            Picker(selection: $consumeLocationID, label: Label(LocalizedStringKey("str.stock.consume.product.location"), systemImage: "location"), content: {
                                Text("").tag(nil as String?)
                                ForEach(grocyVM.mdLocations, id:\.id) {location in
                                    Text(location.name).tag(location.id as String?)
                                }
                            })
                        }
                        
                        if quickScanConsumeAskSpecificItem == .always {
                            Picker(selection: $consumeItemID, label: Label(LocalizedStringKey("str.stock.consume.product.stockEntry"), systemImage: "tag"), content: {
                                Text("").tag(nil as String?)
                                ForEach(grocyVM.stockProductEntries[barcode.productID] ?? [], id: \.stockID) { stockProduct in
                                    Text(LocalizedStringKey("str.stock.entry.description \(stockProduct.amount) \(formatDateOutput(stockProduct.bestBeforeDate) ?? "best before error") \(formatDateOutput(stockProduct.purchasedDate) ?? "purchasedate error") \(stockProduct.stockEntryOpen == "0" ? "str.stock.entry.status.notOpened" : "str.stock.entry.status.opened")"))
                                        .tag(stockProduct.stockID as String?)
                                }
                            })
                        }
                    }
                }
                
                if quickScanMode == .markAsOpened {
                    Group {
                        if quickScanMarkAsOpenedAskSpecificItem == .always {
                            Picker(selection: $markAsOpenItemID, label: Label(LocalizedStringKey("str.stock.consume.product.stockEntry"), systemImage: "tag"), content: {
                                Text("").tag(nil as String?)
                                ForEach(grocyVM.stockProductEntries[barcode.productID] ?? [], id: \.stockID) { stockProduct in
                                    Text(LocalizedStringKey("str.stock.entry.description \(stockProduct.amount) \(formatDateOutput(stockProduct.bestBeforeDate) ?? "best before error") \(formatDateOutput(stockProduct.purchasedDate) ?? "purchasedate error") \(stockProduct.stockEntryOpen == "0" ? "str.stock.entry.status.notOpened".localized : "str.stock.entry.status.opened".localized)"))
                                        .tag(stockProduct.stockID as String?)
                                }
                            })
                        }
                    }
                }
                
                if quickScanMode == .purchase {
                    Group {
                        if ((quickScanPurchaseAskDueDate == .always) || (quickScanPurchaseAskDueDate == .firstInSession && firstInSession)) {
                            HStack {
                                Image(systemName: "calendar")
                                DatePicker(LocalizedStringKey("str.stock.buy.product.dueDate"), selection: $purchaseDueDate, displayedComponents: .date)
                            }
                        }
                        
                        if (quickScanPurchaseAskPrice == .always || (quickScanPurchaseAskPrice == .firstInSession && firstInSession)) {
                            MyDoubleStepper(amount: $purchasePrice, description: "str.stock.buy.product.price", minAmount: 0, amountStep: 1.0, amountName: grocyVM.getCurrencySymbol(), errorMessage: "str.stock.buy.product.price.invalid", systemImage: "eurosign.circle")
                        }
                        
                        if (quickScanPurchaseAskStore == .always || (quickScanPurchaseAskStore == .firstInSession && firstInSession)) {
                            Picker(selection: $purchaseShoppingLocationID, label: Label(LocalizedStringKey("str.stock.buy.product.shoppingLocation"), systemImage: "cart"), content: {
                                Text("").tag(nil as String?)
                                ForEach(grocyVM.mdShoppingLocations, id:\.id) { shoppingLocation in
                                    Text(shoppingLocation.name).tag(shoppingLocation.id as String?)
                                }
                            })
                        }
                        
                        if (quickScanPurchaseAskLocation == .always || (quickScanPurchaseAskLocation == .firstInSession && firstInSession)) {
                            Picker(selection: $purchaseLocationID, label: Label(LocalizedStringKey("str.stock.consume.product.location"), systemImage: "location"), content: {
                                Text("").tag(nil as String?)
                                ForEach(grocyVM.mdLocations, id:\.id) { location in
                                    Text(location.name).tag(location.id as String?)
                                }
                            })
                        }
                    }
                }
            }
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button(LocalizedStringKey("str.cancel")) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                })
                ToolbarItem(placement: .automatic, content: {
                    switch quickScanMode {
                    case .consume:
                        Button(action: consumeItem, label: {
                            Label(LocalizedStringKey("str.stock.consume.product.consume"), systemImage: "tuningfork")
                                .labelStyle(TextIconLabelStyle())
                        })
                        .keyboardShortcut(.defaultAction)
                    case .markAsOpened:
                        Button(action: markAsOpenedItem, label: {
                            Label(LocalizedStringKey("str.stock.consume.product.open"), systemImage: "envelope.open")
                                .labelStyle(TextIconLabelStyle())
                        })
                        .keyboardShortcut(.defaultAction)
                    case .purchase:
                        Button(action: purchaseItem, label: {
                            Label(LocalizedStringKey("str.stock.buy.product.buy"), systemImage: "cart")
                                .labelStyle(TextIconLabelStyle())
                        })
                        .keyboardShortcut(.defaultAction)
                    }
                })
            })
        }
        .onAppear(perform: {
            if firstOpen {
                grocyVM.getStockProductEntries(productID: barcode.productID)
                firstOpen = false
            }
        })
    }
}

struct QuickScanModeInputView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            QuickScanModeInputView(quickScanMode: Binding.constant(QuickScanMode.consume), productBarcode: Binding.constant(MDProductBarcode(id: "1", productID: "1", barcode: "1234567891011", quID: "1", amount: "1.0", shoppingLocationID: "1", lastPrice: "1", rowCreatedTimestamp: "ts", note: "note", userfields: nil)), firstInSession: Binding.constant(true), toastType: .constant(.successQSConsume), infoString: Binding.constant(""))
            
            QuickScanModeInputView(quickScanMode: Binding.constant(QuickScanMode.consume), productBarcode: Binding.constant(MDProductBarcode(id: "1", productID: "1", barcode: "1234567891011", quID: "1", amount: "3.0", shoppingLocationID: "1", lastPrice: "1", rowCreatedTimestamp: "ts", note: "note", userfields: nil)), firstInSession: Binding.constant(true), toastType: .constant(.successQSConsume), infoString: Binding.constant(""))
            
            QuickScanModeInputView(quickScanMode: Binding.constant(QuickScanMode.markAsOpened), productBarcode: Binding.constant(MDProductBarcode(id: "1", productID: "1", barcode: "1234567891011", quID: "1", amount: "1.0", shoppingLocationID: "1", lastPrice: "1", rowCreatedTimestamp: "ts", note: "note", userfields: nil)), firstInSession: Binding.constant(true), toastType: .constant(.successQSOpen), infoString: Binding.constant(""))
            
            QuickScanModeInputView(quickScanMode: Binding.constant(QuickScanMode.purchase), productBarcode: Binding.constant(MDProductBarcode(id: "1", productID: "1", barcode: "1234567891011", quID: "1", amount: "1.0", shoppingLocationID: "1", lastPrice: "1", rowCreatedTimestamp: "ts", note: "note", userfields: nil)), firstInSession: Binding.constant(true), toastType: .constant(.successQSPurchase), infoString: Binding.constant(""))
        }
    }
}
