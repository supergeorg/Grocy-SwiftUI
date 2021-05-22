//
//  QuickScanModeInputView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 06.01.21.
//

import SwiftUI
import URLImage

enum ConsumeAmount {
    case one, barcode, all
}

struct QuickScanModeInputView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstOpen: Bool = true
    
    @Binding var quickScanMode: QuickScanMode
    @Binding var productBarcode: MDProductBarcode?
    
    @Binding var toastTypeSuccess: QSToastTypeSuccess?
    @State private var toastTypeFail: QSToastTypeFail?
    @Binding var infoString: String?
    
    @State private var consumeAmount: ConsumeAmount = .one
    
    var barcode: MDProductBarcode {
        productBarcode ?? MDProductBarcode(id: "", productID: "", barcode: "", quID: nil, amount: nil, shoppingLocationID: nil, lastPrice: nil, rowCreatedTimestamp: "", note: nil, userfields: nil)
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
    private func getAmountForLocation(lID: String) -> Double {
        if let entries = grocyVM.stockProductEntries[productBarcode?.productID ?? ""] {
            var maxAmount: Double = 0
            let filtEntries = entries.filter{ $0.locationID == lID }
            for filtEntry in filtEntries {
                maxAmount += Double(filtEntry.amount) ?? 0
            }
            return maxAmount
        }
        return 0.0
    }
    private func getQUString(amount: Int) -> String {
        return amount == 1 ? quantityUnit?.name ?? "" : quantityUnit?.namePlural ?? ""
    }
    
    // Consume
    @State private var consumeLocationID: String?
    @Binding var lastConsumeLocationID: String?
    @State private var consumeItemID: String?
    
    // Open
    @State private var markAsOpenItemID: String?
    
    // Purchase
    @State private var purchaseDueDate: Date = Date()
    @Binding var lastPurchaseDueDate: Date
    @State private var purchaseAmount: Double = 1.0
    @State private var purchasePrice: Double?
    @State private var purchaseShoppingLocationID: String?
    @Binding var lastPurchaseShoppingLocationID: String?
    @State private var purchaseLocationID: String?
    @Binding var lastPurchaseLocationID: String?
    
    var isValidForm: Bool {
        switch quickScanMode {
        case .consume:
            if consumeLocationID != nil {
                return (getAmountForLocation(lID: consumeLocationID!) > 0)
            } else { return (Double(stockElement?.amount ?? "") ?? 1.0 >= 1.0) }
        case .markAsOpened:
            return (Double(stockElement?.amount ?? "") ?? 1.0 >= 1.0)
        default:
            return true
        }
    }

    private func getConsumeAmount() -> Double {
        switch consumeAmount {
        case .one:
            return 1.0
        case .barcode:
            return Double(productBarcode?.amount ?? "") ?? 1.0
        case .all:
            return Double(stockElement?.amount ?? "") ?? 1.0
        }
    }
    
    private func consumeItem() {
        if let id = productBarcode?.productID {
            let amount = getConsumeAmount()
            let productConsume = ProductConsume(amount: amount, transactionType: .consume, spoiled: false, stockEntryID: consumeItemID, recipeID: nil, locationID: Int(consumeLocationID ?? ""), exactAmount: nil, allowSubproductSubstitution: nil)
            infoString = "\(formatAmount(amount)) \(getQUString(amount: Int(amount))) \(product?.name ?? "")"
            grocyVM.postStockObject(id: id, stockModePost: .consume, content: productConsume) { result in
                switch result {
                case let .success(prod):
                    print(prod)
                    toastTypeSuccess = .successQSConsume
                    finalizeQuickInput()
                case let .failure(error):
                    print("\(error)")
                    toastTypeFail = .failQSConsume
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
                    toastTypeSuccess = .successQSOpen
                    finalizeQuickInput()
                case let .failure(error):
                    print("\(error)")
                    toastTypeFail = .failQSOpen
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
                    toastTypeSuccess = .successQSPurchase
                    finalizeQuickInput()
                case let .failure(error):
                    print("\(error)")
                    toastTypeFail = .failQSPurchase
                }
            }
        }
    }
    
    private func finalizeQuickInput() {
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
        self.presentationMode.wrappedValue.dismiss()
    }
    
    private func restoreLastInput() {
        switch quickScanMode {
        case .consume:
             consumeLocationID = lastConsumeLocationID
        case .markAsOpened:
            ()
        case .purchase:
            purchaseDueDate = lastPurchaseDueDate
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
                                if let amount = stockElement?.amount {
                                    Text(LocalizedStringKey("str.quickScan.input.info.stockAmount \(amount)"))
                                }
                            }
                        }
                    }
                }
                
                if quickScanMode == .consume {
                    Group {
                        VStack(alignment: .leading){
                            Text(LocalizedStringKey("str.quickScan.input.consume.amount"))
                            Picker(selection: $consumeAmount, label: Text(""), content: {
                                Text(LocalizedStringKey("str.quickScan.input.consume.default")).tag(ConsumeAmount.one)
                                if let amount = barcode.amount {
                                    if amount != "1.0" {
                                        Text(LocalizedStringKey("str.quickScan.input.consume.barcodeAmount \(formatStringAmount(amount))")).tag(ConsumeAmount.barcode)
                                    }
                                }
                                Text(LocalizedStringKey("str.quickScan.input.consume.all")).tag(ConsumeAmount.all)
                            }).pickerStyle(SegmentedPickerStyle())
                        }
                        
                        Picker(selection: $consumeLocationID, label: Label(LocalizedStringKey("str.stock.consume.product.location"), systemImage: MySymbols.location), content: {
                            Text("").tag(nil as String?)
                            ForEach(grocyVM.mdLocations, id:\.id) {location in
                                Text("\(location.name) (\(formatAmount(getAmountForLocation(lID: location.id))))").tag(location.id as String?)
                            }
                        })
                        
                        Picker(selection: $consumeItemID, label: Label(LocalizedStringKey("str.stock.consume.product.stockEntry"), systemImage: "tag"), content: {
                            Text("").tag(nil as String?)
                            ForEach(grocyVM.stockProductEntries[barcode.productID] ?? [], id: \.stockID) { stockProduct in
                                Text(stockProduct.stockEntryOpen == "0" ? LocalizedStringKey("str.stock.entry.description.notOpened \(stockProduct.amount) \(formatDateOutput(stockProduct.bestBeforeDate) ?? "best before error") \(formatDateOutput(stockProduct.purchasedDate) ?? "purchasedate error")") : LocalizedStringKey("str.stock.entry.description.opened \(stockProduct.amount) \(formatDateOutput(stockProduct.bestBeforeDate) ?? "best before error") \(formatDateOutput(stockProduct.purchasedDate) ?? "purchasedate error")"))
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
                                Text(stockProduct.stockEntryOpen == "0" ? LocalizedStringKey("str.stock.entry.description.notOpened \(stockProduct.amount) \(formatDateOutput(stockProduct.bestBeforeDate) ?? "best before error") \(formatDateOutput(stockProduct.purchasedDate) ?? "purchasedate error")") : LocalizedStringKey("str.stock.entry.description.opened \(stockProduct.amount) \(formatDateOutput(stockProduct.bestBeforeDate) ?? "best before error") \(formatDateOutput(stockProduct.purchasedDate) ?? "purchasedate error")"))
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
                        
                        MyDoubleStepper(amount: $purchaseAmount, description: "str.stock.buy.product.amount", minAmount: 0.0001, amountStep: 1.0, amountName: getQUString(amount: purchaseAmount == 1.0 ? 1 : 2), errorMessage: "str.stock.buy.product.amount.invalid", systemImage: MySymbols.amount)
                        
                        MyDoubleStepperOptional(amount: $purchasePrice, description: "str.stock.buy.product.price", minAmount: 0, amountStep: 1.0, amountName: "", errorMessage: "str.stock.buy.product.price.invalid", systemImage: MySymbols.price, currencySymbol: grocyVM.getCurrencySymbol())
                        
                        Picker(selection: $purchaseShoppingLocationID, label: Label(LocalizedStringKey("str.stock.buy.product.shoppingLocation"), systemImage: MySymbols.shoppingLocation), content: {
                            Text("").tag(nil as String?)
                            ForEach(grocyVM.mdShoppingLocations, id:\.id) { shoppingLocation in
                                Text(shoppingLocation.name).tag(shoppingLocation.id as String?)
                            }
                        })
                        
                        Picker(selection: $purchaseLocationID, label: Label(LocalizedStringKey("str.stock.consume.product.location"), systemImage: MySymbols.location), content: {
                            Text("").tag(nil as String?)
                            ForEach(grocyVM.mdLocations, id:\.id) { location in
                                Text(product?.locationID == location.id ? LocalizedStringKey("str.stock.consume.product.location.default \(location.name)") : LocalizedStringKey(location.name)).tag(location.id as String?)
                            }
                        })
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
                            Label(LocalizedStringKey("str.stock.consume.product.consume"), systemImage: MySymbols.consume)
                                .labelStyle(TextIconLabelStyle())
                        })
                        .disabled(!isValidForm)
                        .keyboardShortcut(.defaultAction)
                    case .markAsOpened:
                        Button(action: markAsOpenedItem, label: {
                            Label(LocalizedStringKey("str.stock.consume.product.open"), systemImage: MySymbols.open)
                                .labelStyle(TextIconLabelStyle())
                        })
                        .disabled(!isValidForm)
                        .keyboardShortcut(.defaultAction)
                    case .purchase:
                        Button(action: purchaseItem, label: {
                            Label(LocalizedStringKey("str.stock.buy.product.buy"), systemImage: MySymbols.purchase)
                                .labelStyle(TextIconLabelStyle())
                        })
                        .disabled(!isValidForm)
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
//            QuickScanModeInputView(quickScanMode: Binding.constant(QuickScanMode.consume), productBarcode: Binding.constant(MDProductBarcode(id: "1", productID: "1", barcode: "1234567891011", quID: "1", amount: "1.0", shoppingLocationID: "1", lastPrice: "1", rowCreatedTimestamp: "ts", note: "note", userfields: nil)), toastType: .constant(.successQSConsume), infoString: Binding.constant(""))
//            
//            QuickScanModeInputView(quickScanMode: Binding.constant(QuickScanMode.consume), productBarcode: Binding.constant(MDProductBarcode(id: "1", productID: "1", barcode: "1234567891011", quID: "1", amount: "3.0", shoppingLocationID: "1", lastPrice: "1", rowCreatedTimestamp: "ts", note: "note", userfields: nil)), toastType: .constant(.successQSConsume), infoString: Binding.constant(""))
//            
//            QuickScanModeInputView(quickScanMode: Binding.constant(QuickScanMode.markAsOpened), productBarcode: Binding.constant(MDProductBarcode(id: "1", productID: "1", barcode: "1234567891011", quID: "1", amount: "1.0", shoppingLocationID: "1", lastPrice: "1", rowCreatedTimestamp: "ts", note: "note", userfields: nil)), toastType: .constant(.successQSOpen), infoString: Binding.constant(""))
//            
//            QuickScanModeInputView(quickScanMode: Binding.constant(QuickScanMode.purchase), productBarcode: Binding.constant(MDProductBarcode(id: "1", productID: "1", barcode: "1234567891011", quID: "1", amount: "1.0", shoppingLocationID: "1", lastPrice: "1", rowCreatedTimestamp: "ts", note: "note", userfields: nil)), toastType: .constant(.successQSPurchase), infoString: Binding.constant(""))
        }
    }
}
