//
//  QuickScanModeInputView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 06.01.21.
//

import SwiftUI

enum ConsumeAmountMode {
    case one, barcode, custom, all
}

struct QuickScanModeInputView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstOpen: Bool = true
    
    @Binding var quickScanMode: QuickScanMode
    @Binding var productBarcode: MDProductBarcode?
    
    @Binding var toastTypeSuccess: QSToastTypeSuccess?
    @State private var toastTypeFail: QSToastTypeFail?
    @Binding var infoString: String?
    
    @State private var consumeAmountMode: ConsumeAmountMode = .one
    
    @State private var isProcessingAction: Bool = false
    
    var barcode: MDProductBarcode {
        productBarcode ?? MDProductBarcode(id: 0, productID: 0, barcode: "", quID: nil, amount: nil, shoppingLocationID: nil, lastPrice: nil, rowCreatedTimestamp: "", note: nil)
    }
    
    var product: MDProduct? {
        grocyVM.mdProducts.first(where: {$0.id == productBarcode?.productID})
    }
    var stockElement: StockElement? {
        grocyVM.stock.first(where: {$0.productID == productBarcode?.productID})
    }
    var quantityUnit: MDQuantityUnit? {
        quickScanMode == .purchase ? grocyVM.mdQuantityUnits.first(where: {$0.id == product?.quIDPurchase}) : grocyVM.mdQuantityUnits.first(where: {$0.id == product?.quIDStock})
    }
    private func getAmountForLocation(lID: Int) -> Double {
        if let entries = grocyVM.stockProductEntries[productBarcode?.productID ?? 0] {
            var maxAmount: Double = 0
            let filtEntries = entries.filter{ $0.locationID == lID }
            for filtEntry in filtEntries {
                maxAmount += filtEntry.amount
            }
            return maxAmount
        }
        return 0.0
    }
    private func getQUString(amount: Double) -> String {
        return amount == 1 ? quantityUnit?.name ?? "" : quantityUnit?.namePlural ?? ""
    }
    
    // Consume
    @State private var consumeLocationID: Int?
    @State private var consumeAmount: Double = 1.0
    @Binding var lastConsumeLocationID: Int?
    @State private var consumeItemID: String?
    
    // Open
    @State private var markAsOpenItemID: String?
    
    // Purchase
    @State private var purchaseDueDate: Date = Date()
    @Binding var lastPurchaseDueDate: Date
    @State private var purchaseAmount: Double = 1.0
    @State private var purchasePrice: Double?
    @State private var purchaseShoppingLocationID: Int?
    @Binding var lastPurchaseShoppingLocationID: Int?
    @State private var purchaseLocationID: Int?
    @Binding var lastPurchaseLocationID: Int?
    
    var isValidForm: Bool {
        switch quickScanMode {
        case .consume:
            if let consumeLocationID = consumeLocationID {
                return (getAmountForLocation(lID: consumeLocationID) >= getConsumeAmount())
            } else {
                return (stockElement?.amount ?? 1.0 >= getConsumeAmount())
            }
        case .markAsOpened:
            return (stockElement?.amount ?? 0.0 >= 1.0)
        default:
            return true
        }
    }
    
    private func getConsumeAmount() -> Double {
        switch consumeAmountMode {
        case .one:
            return 1.0
        case .barcode:
            return productBarcode?.amount ?? 1.0
        case .custom:
            return consumeAmount
        case .all:
            return stockElement?.amount ?? 1.0
        }
    }
    
    private func consumeItem() {
        if let id = productBarcode?.productID {
            let amount = getConsumeAmount()
            let productConsume = ProductConsume(amount: amount, transactionType: .consume, spoiled: false, stockEntryID: consumeItemID, recipeID: nil, locationID: consumeLocationID, exactAmount: nil, allowSubproductSubstitution: nil)
            infoString = "\(formatAmount(amount)) \(getQUString(amount: amount)) \(product?.name ?? "")"
            isProcessingAction = true
            grocyVM.postStockObject(id: id, stockModePost: .consume, content: productConsume) { result in
                switch result {
                case let .success(prod):
                    grocyVM.postLog(message: "Consume successful. \(prod)", type: .info)
                    toastTypeSuccess = .successQSConsume
                    finalizeQuickInput()
                case let .failure(error):
                    grocyVM.postLog(message: "Consume failed. \(error)", type: .error)
                    toastTypeFail = .failQSConsume
                }
                isProcessingAction = false
            }
        }
    }
    
    private func markAsOpenedItem() {
        if let id = productBarcode?.productID {
            let productOpen = ProductOpen(amount: 1.0, stockEntryID: markAsOpenItemID, allowSubproductSubstitution: nil)
            infoString = "1 \(getQUString(amount: 1)) \(product?.name ?? "")"
            isProcessingAction = true
            grocyVM.postStockObject(id: id, stockModePost: .open, content: productOpen) { result in
                switch result {
                case let .success(prod):
                    grocyVM.postLog(message: "Open successful. \(prod)", type: .info)
                    toastTypeSuccess = .successQSOpen
                    finalizeQuickInput()
                case let .failure(error):
                    grocyVM.postLog(message: "Open failed. \(error)", type: .error)
                    toastTypeFail = .failQSOpen
                }
                isProcessingAction = false
            }
        }
    }
    
    private func purchaseItem() {
        if let id = productBarcode?.productID {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let productBuy = ProductBuy(amount: purchaseAmount, bestBeforeDate: dateFormatter.string(from: purchaseDueDate), transactionType: .purchase, price: purchasePrice, locationID: purchaseLocationID, shoppingLocationID: purchaseShoppingLocationID)
            infoString = "\(formatAmount(purchaseAmount)) \(getQUString(amount: purchaseAmount)) \(product?.name ?? "")"
            isProcessingAction = true
            grocyVM.postStockObject(id: id, stockModePost: .add, content: productBuy) { result in
                switch result {
                case let .success(prod):
                    grocyVM.postLog(message: "Purchase successful. \(prod)", type: .info)
                    toastTypeSuccess = .successQSPurchase
                    finalizeQuickInput()
                case let .failure(error):
                    grocyVM.postLog(message: "Purchase failed. \(error)", type: .error)
                    toastTypeFail = .failQSPurchase
                }
                isProcessingAction = false
            }
        }
    }
    
    private func finalizeQuickInput() {
        grocyVM.requestData(additionalObjects: [.stock], ignoreCached: true)
        switch quickScanMode {
        case .consume:
            lastConsumeLocationID = consumeLocationID
        case .markAsOpened:
            ()
        case .purchase:
            lastPurchaseDueDate = purchaseDueDate
            lastPurchaseShoppingLocationID = purchaseShoppingLocationID
            lastPurchaseLocationID = purchaseLocationID
        }
        self.dismiss()
    }
    
    private func restoreLastInput() {
        switch quickScanMode {
        case .consume:
            consumeLocationID = product?.locationID ?? lastConsumeLocationID
        case .markAsOpened:
            ()
        case .purchase:
            purchaseDueDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: product?.defaultBestBeforeDays ?? 0, to: Date()) ?? Calendar.current.startOfDay(for: lastPurchaseDueDate))
            purchaseShoppingLocationID = product?.shoppingLocationID ?? lastPurchaseShoppingLocationID
            purchaseLocationID = product?.locationID ?? lastPurchaseLocationID
        }
    }
    
    var body: some View {
        NavigationView{
            Form {
                if let productU = product {
                    Section() {
                        HStack{
                            if let pictureFileName = productU.pictureFileName,
                               let utf8str = pictureFileName.data(using: .utf8),
                               let base64Encoded = utf8str.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)),
                               let pictureURL = grocyVM.getPictureURL(groupName: "productpictures", fileName: base64Encoded),
                               let url = URL(string: pictureURL) {
                                AsyncImage(url: url, content: { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .background(Color.white)
                                }, placeholder: {
                                    ProgressView()
                                })
                                    .frame(width: 50, height: 50)
                            }
                            VStack(alignment: .leading) {
                                Text(productU.name).font(.title)
                                if let amount = stockElement?.amount {
                                    Text(LocalizedStringKey("str.quickScan.input.info.stockAmount \("\(formatAmount(amount)) \(getQUString(amount: amount))")"))
                                }
                            }
                        }
                    }
                }
                
                if quickScanMode == .consume {
                    Group {
                        VStack(alignment: .leading){
                            Text(LocalizedStringKey("str.quickScan.input.consume.amount"))
                            Picker(selection: $consumeAmountMode, label: Text(""), content: {
                                Text(LocalizedStringKey("str.quickScan.input.consume.default")).tag(ConsumeAmountMode.one)
                                if let amount = barcode.amount {
                                    if amount != 1.0 {
                                        Text(LocalizedStringKey("str.quickScan.input.consume.barcodeAmount \(formatAmount(amount))")).tag(ConsumeAmountMode.barcode)
                                    }
                                }
                                Text(LocalizedStringKey("str.quickScan.input.consume.custom")).tag(ConsumeAmountMode.custom)
                                Text(LocalizedStringKey("str.quickScan.input.consume.all \(formatAmount(stockElement?.amount ?? 1.0))")).tag(ConsumeAmountMode.all)
                            }).pickerStyle(SegmentedPickerStyle())
                            if consumeAmountMode == .custom {
                                MyDoubleStepper(amount: $consumeAmount, description: "str.stock.product.amount", minAmount: 0.0001, maxAmount: consumeLocationID != nil ? getAmountForLocation(lID: consumeLocationID!) : stockElement?.amount ?? 1.0, amountStep: 1.0, amountName: getQUString(amount: consumeAmount == 1.0 ? 1 : 2), errorMessage: "str.stock.product.amount.invalid", errorMessageMax: "str.stock.product.amount.locMax", systemImage: MySymbols.amount)
                            }
                        }
                        
                        Picker(selection: $consumeLocationID, label: Label(LocalizedStringKey("str.stock.consume.product.location"), systemImage: MySymbols.location), content: {
                            Text("").tag(nil as Int?)
                            ForEach(grocyVM.mdLocations, id:\.id) {location in
                                Text("\(location.name) (\(formatAmount(getAmountForLocation(lID: location.id))))").tag(location.id as Int?)
                            }
                        })
                        
                        Picker(selection: $consumeItemID, label: Label(LocalizedStringKey("str.stock.consume.product.stockEntry"), systemImage: "tag"), content: {
                            Text("").tag(nil as String?)
                            ForEach(grocyVM.stockProductEntries[barcode.productID] ?? [], id: \.stockID) { stockProduct in
                                Text(stockProduct.stockEntryOpen == false ?
                                     LocalizedStringKey("str.stock.entry.description.notOpened \(stockProduct.amount.formattedAmount) \(formatDateAsString(stockProduct.bestBeforeDate, localizationKey: localizationKey) ?? "best before error") \(formatDateAsString(stockProduct.purchasedDate, localizationKey: localizationKey) ?? "purchasedate error")")
                                     :
                                        LocalizedStringKey("str.stock.entry.description.opened \(stockProduct.amount.formattedAmount) \(formatDateAsString(stockProduct.bestBeforeDate, localizationKey: localizationKey) ?? "best before error") \(formatDateAsString(stockProduct.purchasedDate, localizationKey: localizationKey) ?? "purchasedate error")")
                                )
                                    .tag(stockProduct.stockID as String?)
                            }
                        })
                    }
                }
                
                if quickScanMode == .markAsOpened {
                    Group {
                        Picker(selection: $markAsOpenItemID, label: Label(LocalizedStringKey("str.stock.consume.product.stockEntry"), systemImage: "tag"), content: {
                            Text("").tag(nil as String?)
                            ForEach(grocyVM.stockProductEntries[barcode.productID] ?? [], id: \.stockID) { stockProduct in
                                Text(stockProduct.stockEntryOpen == false ?
                                     LocalizedStringKey("str.stock.entry.description.notOpened \(stockProduct.amount.formattedAmount) \(formatDateAsString(stockProduct.bestBeforeDate, localizationKey: localizationKey) ?? "best before error") \(formatDateAsString(stockProduct.purchasedDate, localizationKey: localizationKey) ?? "purchasedate error")")
                                     :
                                        LocalizedStringKey("str.stock.entry.description.opened \(stockProduct.amount.formattedAmount) \(formatDateAsString(stockProduct.bestBeforeDate, localizationKey: localizationKey) ?? "best before error") \(formatDateAsString(stockProduct.purchasedDate, localizationKey: localizationKey) ?? "purchasedate error")")
                                )
                                    .tag(stockProduct.stockID as String?)
                            }
                        })
                    }
                }
                
                if quickScanMode == .purchase {
                    Group {
                        HStack {
                            Image(systemName: MySymbols.date)
                            DatePicker(LocalizedStringKey("str.stock.buy.product.dueDate"), selection: $purchaseDueDate, displayedComponents: .date)
                        }
                        
                        MyDoubleStepper(amount: $purchaseAmount, description: "str.stock.product.amount", minAmount: 0.0001, amountStep: 1.0, amountName: getQUString(amount: purchaseAmount == 1.0 ? 1 : 2), errorMessage: "str.stock.product.amount.invalid", systemImage: MySymbols.amount)
                        
                        MyDoubleStepperOptional(amount: $purchasePrice, description: "str.stock.buy.product.price", minAmount: 0, amountStep: 1.0, amountName: "", errorMessage: "str.stock.buy.product.price.invalid", systemImage: MySymbols.price, isCurrency: true)
                        
                        Picker(selection: $purchaseShoppingLocationID, label: Label(LocalizedStringKey("str.stock.buy.product.shoppingLocation"), systemImage: MySymbols.shoppingLocation), content: {
                            Text("").tag(nil as Int?)
                            ForEach(grocyVM.mdShoppingLocations, id:\.id) { shoppingLocation in
                                Text(shoppingLocation.name).tag(shoppingLocation.id as Int?)
                            }
                        })
                        
                        Picker(selection: $purchaseLocationID, label: Label(LocalizedStringKey("str.stock.consume.product.location"), systemImage: MySymbols.location), content: {
                            Text("").tag(nil as Int?)
                            ForEach(grocyVM.mdLocations, id:\.id) { location in
                                Text(product?.locationID == location.id ? LocalizedStringKey("str.stock.consume.product.location.default \(location.name)") : LocalizedStringKey(location.name)).tag(location.id as Int?)
                            }
                        })
                    }
                }
            }
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button(LocalizedStringKey("str.cancel")) {
                        self.dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                })
                ToolbarItemGroup(placement: .automatic, content: {
                    switch quickScanMode {
                    case .consume:
                        Button(action: consumeItem, label: {
                            Label(LocalizedStringKey("str.stock.consume.product.consume"), systemImage: MySymbols.consume)
                                .labelStyle(.titleAndIcon)
                        })
                            .disabled(!isValidForm || isProcessingAction)
                            .keyboardShortcut(.defaultAction)
                    case .markAsOpened:
                        Button(action: markAsOpenedItem, label: {
                            Label(LocalizedStringKey("str.stock.consume.product.open"), systemImage: MySymbols.open)
                                .labelStyle(.titleAndIcon)
                        })
                            .disabled(!isValidForm || isProcessingAction)
                            .keyboardShortcut(.defaultAction)
                    case .purchase:
                        Button(action: purchaseItem, label: {
                            Label(LocalizedStringKey("str.stock.buy.product.buy"), systemImage: MySymbols.purchase)
                                .labelStyle(.titleAndIcon)
                        })
                            .disabled(!isValidForm || isProcessingAction)
                            .keyboardShortcut(.defaultAction)
                    }
                })
            })
        }
        .toast(item: $toastTypeFail, isSuccess: Binding.constant(false), content: { item in
            switch item {
            case .failQSConsume:
                Label(LocalizedStringKey("str.stock.consume.product.consume.fail"), systemImage: MySymbols.failure)
            case .failQSOpen:
                Label(LocalizedStringKey("str.stock.consume.product.open.fail"), systemImage: MySymbols.failure)
            case .failQSPurchase:
                Label(LocalizedStringKey("str.stock.buy.product.buy.fail"), systemImage: MySymbols.failure)
            default:
                EmptyView()
            }
        })
        .onAppear(perform: {
            if firstOpen {
                grocyVM.getStockProductEntries(productID: barcode.productID)
                restoreLastInput()
                firstOpen = false
            }
        })
    }
}

struct QuickScanModeInputView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            QuickScanModeInputView(quickScanMode: Binding.constant(QuickScanMode.consume), productBarcode: Binding.constant(MDProductBarcode(id: 1, productID: 1, barcode: "1234567891011", quID: 1, amount: 1.0, shoppingLocationID: 1, lastPrice: 1, rowCreatedTimestamp: "ts", note: "note")), toastTypeSuccess: Binding.constant(QSToastTypeSuccess.successQSConsume), infoString: Binding.constant(nil), lastConsumeLocationID: Binding.constant(nil), lastPurchaseDueDate: Binding.constant(Date()), lastPurchaseShoppingLocationID: Binding.constant(nil), lastPurchaseLocationID: Binding.constant(nil))
            
            QuickScanModeInputView(quickScanMode: Binding.constant(QuickScanMode.markAsOpened), productBarcode: Binding.constant(MDProductBarcode(id: 1, productID: 1, barcode: "1234567891011", quID: 1, amount: 1.0, shoppingLocationID: 1, lastPrice: 1, rowCreatedTimestamp: "ts", note: "note")), toastTypeSuccess: Binding.constant(QSToastTypeSuccess.successQSOpen), infoString: Binding.constant(nil), lastConsumeLocationID: Binding.constant(nil), lastPurchaseDueDate: Binding.constant(Date()), lastPurchaseShoppingLocationID: Binding.constant(nil), lastPurchaseLocationID: Binding.constant(nil))
            
            QuickScanModeInputView(quickScanMode: Binding.constant(QuickScanMode.purchase), productBarcode: Binding.constant(MDProductBarcode(id: 1, productID: 1, barcode: "1234567891011", quID: 1, amount: 1.0, shoppingLocationID: 1, lastPrice: 1, rowCreatedTimestamp: "ts", note: "note")), toastTypeSuccess: Binding.constant(QSToastTypeSuccess.successQSPurchase), infoString: Binding.constant(nil), lastConsumeLocationID: Binding.constant(nil), lastPurchaseDueDate: Binding.constant(Date()), lastPurchaseShoppingLocationID: Binding.constant(nil), lastPurchaseLocationID: Binding.constant(nil))
        }
    }
}
