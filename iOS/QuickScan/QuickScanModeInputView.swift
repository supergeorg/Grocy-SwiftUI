//
//  QuickScanModeInputView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 06.01.21.
//

import SwiftUI

enum ConsumeAmountMode {
    case standard, barcode, custom, all
}

struct QuickScanModeInputView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstOpen: Bool = true
    @State private var firstClose: Bool = true
    
    @Binding var quickScanMode: QuickScanMode
    var productBarcode: MDProductBarcode?
    var grocyCode: GrocyCode?
    
    @Binding var toastTypeSuccess: QSToastTypeSuccess?
    @State private var toastTypeFail: QSToastTypeFail?
    @Binding var infoString: String?
    
    @State private var consumeAmountMode: ConsumeAmountMode = .standard
    
    @State private var isProcessingAction: Bool = false
    
    var product: MDProduct? {
        if let grocyCode = grocyCode {
            return grocyVM.mdProducts.first(where: { $0.id == grocyCode.entityID })
        } else if let productBarcode = productBarcode {
            return grocyVM.mdProducts.first(where: { $0.id == productBarcode.productID })
        }
        return nil
    }

    var stockElement: StockElement? {
        grocyVM.stock.first(where: { $0.productID == product?.id })
    }
    
    var quantityUnitPurchase: MDQuantityUnit? {
        grocyVM.mdQuantityUnits.first(where: { $0.id == product?.quIDPurchase })
    }

    var quantityUnitStock: MDQuantityUnit? {
        grocyVM.mdQuantityUnits.first(where: { $0.id == product?.quIDStock })
    }
    
    private var quantityUnitConversions: [MDQuantityUnitConversion] {
        return grocyVM.mdQuantityUnitConversions.filter { $0.toQuID == product?.quIDStock }
    }

    private var purchaseAmountFactored: Double {
        return purchaseAmount * (quantityUnitConversions.first(where: { $0.fromQuID == purchaseQuantityUnitID })?.factor ?? 1)
    }

    private var purchaseStockAmountFactored: Double {
        return purchaseAmountFactored * (product?.quFactorPurchaseToStock ?? 1.0)
    }
    
    private var purchaseUnitPrice: Double? {
        if purchaseIsTotalPrice {
            return ((purchasePrice ?? 0.0) / purchaseAmountFactored)
        } else {
            return purchasePrice
        }
    }
    
    private func getAmountForLocation(lID: Int) -> Double {
        if let entries = grocyVM.stockProductEntries[product?.id ?? 0] {
            var maxAmount: Double = 0
            let filtEntries = entries.filter { $0.locationID == lID }
            for filtEntry in filtEntries {
                maxAmount += filtEntry.amount
            }
            return maxAmount
        }
        return 0.0
    }

    private func getQUString(amount: Double, purchase: Bool = false) -> String {
        if purchase {
            return amount == 1 ? quantityUnitPurchase?.name ?? "" : quantityUnitPurchase?.namePlural ?? quantityUnitPurchase?.name ?? ""
        } else {
            return amount == 1 ? quantityUnitStock?.name ?? "" : quantityUnitStock?.namePlural ?? quantityUnitStock?.name ?? ""
        }
    }
    
    // Consume
    @State private var consumeLocationID: Int?
    @State private var consumeAmount: Double = 1.0
    @Binding var lastConsumeLocationID: Int?
    @State private var consumeItemID: String?
    
    // Open
    @State private var markAsOpenItemID: String?
    
    // Purchase
    @State private var purchaseDueDate: Date = .init()
    @State private var purchaseDoesntSpoil: Bool = false
    @Binding var lastPurchaseDueDate: Date
    @State private var purchaseAmount: Double = 1.0
    @State private var purchaseQuantityUnitID: Int?
    @State private var purchasePrice: Double?
    @State private var purchaseIsTotalPrice: Bool = false
    @State private var purchaseShoppingLocationID: Int?
    @Binding var lastPurchaseShoppingLocationID: Int?
    @State private var purchaseLocationID: Int?
    @Binding var lastPurchaseLocationID: Int?
    @State private var note: String = ""
    
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
    
    private func getStandardConsumeAmount() -> Double {
        if grocyVM.userSettings?.stockDefaultConsumeAmountUseQuickConsumeAmount == true {
            return product?.quickConsumeAmount ?? 1.0
        } else {
            return grocyVM.userSettings?.stockDefaultConsumeAmount ?? 1
        }
    }
    
    private func getConsumeAmount() -> Double {
        switch consumeAmountMode {
        case .standard:
            return getStandardConsumeAmount()
        case .barcode:
            return productBarcode?.amount ?? 1.0
        case .custom:
            return consumeAmount
        case .all:
            return stockElement?.amount ?? 1.0
        }
    }
    
    private func consumeItem() {
        if let id = product?.id {
            let amount = getConsumeAmount()
            let productConsume = ProductConsume(
                amount: amount,
                transactionType: .consume,
                spoiled: false,
                stockEntryID: consumeItemID,
                recipeID: nil,
                locationID: consumeLocationID,
                exactAmount: nil,
                allowSubproductSubstitution: nil
            )
            infoString = "\(amount.formattedAmount) \(getQUString(amount: amount)) \(product?.name ?? "")"
            isProcessingAction = true
            grocyVM.postStockObject(id: id, stockModePost: .consume, content: productConsume) { result in
                switch result {
                case let .success(prod):
                    grocyVM.postLog("Consume successful. \(prod)", type: .info)
                    if let autoAddBelowMinStock = grocyVM.userSettings?.shoppingListAutoAddBelowMinStockAmount, autoAddBelowMinStock == true, let shlID = grocyVM.userSettings?.shoppingListAutoAddBelowMinStockAmountListID {
                        grocyVM.shoppingListAction(content: ShoppingListAction(listID: shlID), actionType: .addMissing, completion: { result in
                            switch result {
                            case let .success(message):
                                grocyVM.postLog("SHLAction successful. \(message)", type: .info)
                                grocyVM.requestData(objects: [.shopping_list])
                            case let .failure(error):
                                grocyVM.postLog("SHLAction failed. \(error)", type: .error)
                            }
                        })
                    }
                    toastTypeSuccess = .successQSConsume
                    finalizeQuickInput()
                case let .failure(error):
                    grocyVM.postLog("Consume failed. \(error)", type: .error)
                    toastTypeFail = .failQSConsume
                }
                isProcessingAction = false
            }
        }
    }
    
    private func markAsOpenedItem() {
        if let id = product?.id {
            let productOpen = ProductOpen(amount: 1.0, stockEntryID: markAsOpenItemID, allowSubproductSubstitution: nil)
            infoString = "1 \(getQUString(amount: 1)) \(product?.name ?? "")"
            isProcessingAction = true
            grocyVM.postStockObject(id: id, stockModePost: .open, content: productOpen) { result in
                switch result {
                case let .success(prod):
                    grocyVM.postLog("Open successful. \(prod)", type: .info)
                    toastTypeSuccess = .successQSOpen
                    finalizeQuickInput()
                case let .failure(error):
                    grocyVM.postLog("Open failed. \(error)", type: .error)
                    toastTypeFail = .failQSOpen
                }
                isProcessingAction = false
            }
        }
    }
    
    private func purchaseItem() {
        if let id = product?.id {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let strDueDate = purchaseDoesntSpoil ? "2999-12-31" : dateFormatter.string(from: purchaseDueDate)
            let noteText = (grocyVM.systemInfo?.grocyVersion.version ?? "").starts(with: "3.3") ? (note.isEmpty ? nil : note) : nil
            let productBuy = ProductBuy(
                amount: purchaseStockAmountFactored,
                bestBeforeDate: strDueDate,
                transactionType: .purchase,
                price: purchaseUnitPrice,
                locationID: purchaseLocationID,
                shoppingLocationID: purchaseShoppingLocationID,
                note: noteText
            )
            infoString = "\(purchaseAmount.formattedAmount) \(getQUString(amount: purchaseAmount, purchase: true)) \(product?.name ?? "")"
            isProcessingAction = true
            grocyVM.postStockObject(id: id, stockModePost: .add, content: productBuy) { result in
                switch result {
                case let .success(prod):
                    grocyVM.postLog("Purchase successful. \(prod)", type: .info)
                    toastTypeSuccess = .successQSPurchase
                    finalizeQuickInput()
                case let .failure(error):
                    grocyVM.postLog("Purchase failed. \(error)", type: .error)
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
        dismiss()
    }
    
    private func restoreLastInput() {
        switch quickScanMode {
        case .consume:
            consumeLocationID = product?.locationID ?? lastConsumeLocationID
            consumeItemID = (grocyVM.stockProductEntries[product?.id ?? 0])?.first(where: { $0.stockID == grocyCode?.stockID }) != nil ? grocyCode?.stockID : nil
        case .markAsOpened:
            markAsOpenItemID = (grocyVM.stockProductEntries[product?.id ?? 0])?.first(where: { $0.stockID == grocyCode?.stockID }) != nil ? grocyCode?.stockID : nil
        case .purchase:
            purchaseAmount = grocyVM.userSettings?.stockDefaultPurchaseAmount ?? 1.0
            if product?.defaultBestBeforeDays == -1 {
                purchaseDoesntSpoil = true
                purchaseDueDate = Calendar.current.startOfDay(for: lastPurchaseDueDate)
            } else {
                purchaseDoesntSpoil = false
                purchaseDueDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: product?.defaultBestBeforeDays ?? 0, to: Date()) ?? lastPurchaseDueDate)
            }
            purchaseShoppingLocationID = product?.shoppingLocationID ?? lastPurchaseShoppingLocationID
            purchaseLocationID = product?.locationID ?? lastPurchaseLocationID
            purchaseQuantityUnitID = quantityUnitPurchase?.id
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                if let product = product {
                    Section {
                        HStack {
                            if let pictureFileName = product.pictureFileName,
                               !pictureFileName.isEmpty,
                               let utf8str = pictureFileName.data(using: .utf8),
                               let base64Encoded = utf8str.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)),
                               let pictureURL = grocyVM.getPictureURL(groupName: "productpictures", fileName: base64Encoded),
                               let url = URL(string: pictureURL)
                            {
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
                                Text(product.name).font(.title)
                                if let amount = stockElement?.amount {
                                    Text(LocalizedStringKey("str.quickScan.input.info.stockAmount \("\(amount.formattedAmount) \(getQUString(amount: amount))")"))
                                }
                            }
                        }
                    }
                }
                
                if quickScanMode == .consume {
                    Group {
                        VStack(alignment: .leading) {
                            Text(LocalizedStringKey("str.quickScan.input.consume.amount"))
                            Picker(selection: $consumeAmountMode, label: Text(""), content: {
                                Text(LocalizedStringKey("str.quickScan.input.consume.default \(getStandardConsumeAmount().formattedAmount)")).tag(ConsumeAmountMode.standard)
                                if let amount = productBarcode?.amount {
                                    if amount != 1.0 {
                                        Text(LocalizedStringKey("str.quickScan.input.consume.barcodeAmount \(amount.formattedAmount)")).tag(ConsumeAmountMode.barcode)
                                    }
                                }
                                Text(LocalizedStringKey("str.quickScan.input.consume.custom")).tag(ConsumeAmountMode.custom)
                                Text(LocalizedStringKey("str.quickScan.input.consume.all \((stockElement?.amount ?? 1.0).formattedAmount)")).tag(ConsumeAmountMode.all)
                            })
                            .pickerStyle(.segmented)
                            if consumeAmountMode == .custom {
                                MyDoubleStepper(amount: $consumeAmount, description: "str.stock.product.amount", minAmount: 0.0001, maxAmount: consumeLocationID != nil ? getAmountForLocation(lID: consumeLocationID!) : stockElement?.amount ?? 1.0, amountStep: 1.0, amountName: getQUString(amount: consumeAmount == 1.0 ? 1 : 2), errorMessage: "str.stock.product.amount.invalid", errorMessageMax: "str.stock.product.amount.locMax", systemImage: MySymbols.amount)
                            }
                        }
                        
                        Picker(selection: $consumeLocationID, label: Label(LocalizedStringKey("str.stock.consume.product.location"), systemImage: MySymbols.location), content: {
                            Text("").tag(nil as Int?)
                            ForEach(grocyVM.mdLocations, id: \.id) { location in
                                Text("\(location.name) (\(getAmountForLocation(lID: location.id).formattedAmount))").tag(location.id as Int?)
                            }
                        })
                        
                        Picker(selection: $consumeItemID, label: Label(LocalizedStringKey("str.stock.consume.product.stockEntry"), systemImage: "tag"), content: {
                            Text("").tag(nil as String?)
                            ForEach(grocyVM.stockProductEntries[product?.id ?? 0] ?? [], id: \.stockID) { stockProduct in
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
                            ForEach(grocyVM.stockProductEntries[product?.id ?? 0] ?? [], id: \.stockID) { stockProduct in
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
                        Section(header: Text(LocalizedStringKey("str.stock.buy.product.dueDate")).font(.headline)) {
                            VStack(alignment: .trailing) {
                                HStack {
                                    Image(systemName: MySymbols.date)
                                    DatePicker(LocalizedStringKey("str.stock.buy.product.dueDate"), selection: $purchaseDueDate, displayedComponents: .date)
                                        .disabled(purchaseDoesntSpoil)
                                }
                                Text(getRelativeDateAsText(purchaseDueDate, localizationKey: localizationKey) ?? "")
                                    .foregroundColor(.gray)
                                    .italic()
                            }
                            
                            MyToggle(isOn: $purchaseDoesntSpoil, description: "str.stock.buy.product.doesntSpoil", descriptionInfo: nil, icon: MySymbols.doesntSpoil)
                        }
                        
                        AmountSelectionView(productID: Binding.constant(product?.id), amount: $purchaseAmount, quantityUnitID: $purchaseQuantityUnitID)
                        
                        Section(header: Text(LocalizedStringKey("str.stock.buy.product.price")).font(.headline)) {
                            VStack(alignment: .leading) {
                                MyDoubleStepperOptional(amount: $purchasePrice, description: "str.stock.buy.product.price", minAmount: 0, amountStep: 1.0, amountName: "", errorMessage: "str.stock.buy.product.price.invalid", systemImage: MySymbols.price, currencySymbol: grocyVM.getCurrencySymbol())
                                
                                if purchaseIsTotalPrice && product != nil {
                                    Text(LocalizedStringKey("str.stock.buy.product.price.relation \(grocyVM.getFormattedCurrency(amount: purchaseUnitPrice ?? 0)) \(quantityUnitPurchase?.name ?? "")"))
                                        .font(.caption)
                                        .foregroundColor(Color.grocyGray)
                                }
                            }
                            
                            if purchasePrice != nil {
                                Picker("", selection: $purchaseIsTotalPrice, content: {
                                    Text(quantityUnitPurchase?.name != nil ? LocalizedStringKey("str.stock.buy.product.price.unitPrice \(quantityUnitPurchase!.name)") : LocalizedStringKey("str.stock.buy.product.price.unitPrice")).tag(false)
                                    Text(LocalizedStringKey("str.stock.buy.product.price.totalPrice")).tag(true)
                                })
                                .pickerStyle(.segmented)
                            }
                        }
                        
                        Picker(selection: $purchaseShoppingLocationID, label: Label(LocalizedStringKey("str.stock.buy.product.shoppingLocation"), systemImage: MySymbols.shoppingLocation), content: {
                            Text("").tag(nil as Int?)
                            ForEach(grocyVM.mdShoppingLocations, id: \.id) { shoppingLocation in
                                Text(shoppingLocation.name).tag(shoppingLocation.id as Int?)
                            }
                        })
                        
                        Picker(selection: $purchaseLocationID, label: Label(LocalizedStringKey("str.stock.consume.product.location"), systemImage: MySymbols.location), content: {
                            Text("").tag(nil as Int?)
                            ForEach(grocyVM.mdLocations, id: \.id) { location in
                                Text(product?.locationID == location.id ? LocalizedStringKey("str.stock.consume.product.location.default \(location.name)") : LocalizedStringKey(location.name)).tag(location.id as Int?)
                            }
                        })
                        
                        if (grocyVM.systemInfo?.grocyVersion.version ?? "").starts(with: "3.3") {
                            MyTextField(textToEdit: $note, description: "str.stock.buy.product.note", isCorrect: Binding.constant(true), leadingIcon: MySymbols.description)
                        }
                    }
                }
            }
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button(LocalizedStringKey("str.cancel")) {
                        self.dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    .disabled(grocyVM.loadingObjectEntities.count > 0)
                })
                ToolbarItemGroup(placement: .automatic, content: {
                    switch quickScanMode {
                    case .consume:
                        Button(action: consumeItem, label: {
                            Label(LocalizedStringKey("str.stock.consume.product.consume"), systemImage: MySymbols.consume)
                                .labelStyle(.titleAndIcon)
                        })
                        .disabled(!isValidForm || isProcessingAction || (grocyVM.loadingObjectEntities.count > 0))
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
        .interactiveDismissDisabled(grocyVM.loadingObjectEntities.count > 0)
        .toast(item: $toastTypeFail, isSuccess: Binding.constant(false), text: { item in
            switch item {
            case .failQSConsume:
                return LocalizedStringKey("str.stock.consume.product.consume.fail")
            case .failQSOpen:
                return LocalizedStringKey("str.stock.consume.product.open.fail")
            case .failQSPurchase:
                return LocalizedStringKey("str.stock.buy.product.buy.fail")
            default:
                return LocalizedStringKey("")
            }
        })
        .onAppear(perform: {
            if firstOpen {
                if let productID = product?.id {
                    grocyVM.getStockProductEntries(productID: productID)
                }
                restoreLastInput()
                firstOpen = false
            }
        })
    }
}

struct QuickScanModeInputView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            QuickScanModeInputView(
                quickScanMode: Binding.constant(QuickScanMode.consume),
                productBarcode: MDProductBarcode(id: 1, productID: 1, barcode: "1234567891011", quID: 1, amount: 1.0, shoppingLocationID: 1, lastPrice: 1, rowCreatedTimestamp: "ts", note: "note"),
                grocyCode: nil,
                toastTypeSuccess: Binding.constant(QSToastTypeSuccess.successQSConsume),
                infoString: Binding.constant(nil),
                lastConsumeLocationID: Binding.constant(nil),
                lastPurchaseDueDate: Binding.constant(Date()),
                lastPurchaseShoppingLocationID: Binding.constant(nil),
                lastPurchaseLocationID: Binding.constant(nil)
            )
            
            QuickScanModeInputView(
                quickScanMode: Binding.constant(QuickScanMode.markAsOpened),
                productBarcode: MDProductBarcode(id: 1, productID: 1, barcode: "1234567891011", quID: 1, amount: 1.0, shoppingLocationID: 1, lastPrice: 1, rowCreatedTimestamp: "ts", note: "note"),
                grocyCode: nil,
                toastTypeSuccess: Binding.constant(QSToastTypeSuccess.successQSOpen),
                infoString: Binding.constant(nil),
                lastConsumeLocationID: Binding.constant(nil),
                lastPurchaseDueDate: Binding.constant(Date()),
                lastPurchaseShoppingLocationID: Binding.constant(nil),
                lastPurchaseLocationID: Binding.constant(nil)
            )
            
            QuickScanModeInputView(
                quickScanMode: Binding.constant(QuickScanMode.purchase),
                productBarcode: MDProductBarcode(id: 1, productID: 1, barcode: "1234567891011", quID: 1, amount: 1.0, shoppingLocationID: 1, lastPrice: 1, rowCreatedTimestamp: "ts", note: "note"),
                grocyCode: nil,
                toastTypeSuccess: Binding.constant(QSToastTypeSuccess.successQSPurchase),
                infoString: Binding.constant(nil),
                lastConsumeLocationID: Binding.constant(nil),
                lastPurchaseDueDate: Binding.constant(Date()),
                lastPurchaseShoppingLocationID: Binding.constant(nil),
                lastPurchaseLocationID: Binding.constant(nil)
            )
        }
    }
}
