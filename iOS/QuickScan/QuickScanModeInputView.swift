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
    
    @Binding var toastType: ToastType?
    @Binding var infoString: String?
    
    @State private var consumeAmountMode: ConsumeAmountMode = .standard
    
    @State private var isProcessingAction: Bool = false
    
    @State var actionFinished: Bool = false
    
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
    @State private var purchaseStoreID: Int?
    @Binding var lastPurchaseStoreID: Int?
    @State private var purchaseLocationID: Int?
    @Binding var lastPurchaseLocationID: Int?
    @State private var note: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                if let product = product {
                    // TODO: Picture
//                    Section {
//                        HStack {
//                            if let pictureFileName = product.pictureFileName,
//                               !pictureFileName.isEmpty,
//                               let utf8str = pictureFileName.data(using: .utf8),
//                               let pictureURL = grocyVM.getPictureURL(
//                                groupName: "productpictures",
//                                fileName: utf8str.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
//                               ),
//                               let url = URL(string: pictureURL)
//                            {
//                                AsyncImage(url: url, content: { image in
//                                    image
//                                        .resizable()
//                                        .aspectRatio(contentMode: .fit)
//                                        .background(Color.white)
//                                }, placeholder: {
//                                    ProgressView()
//                                })
//                                .frame(width: 50, height: 50)
//                            }
//                            VStack(alignment: .leading) {
//                                Text(product.name).font(.title)
//                                if let amount = stockElement?.amount {
//                                    Text(LocalizedStringKey("str.quickScan.input.info.stockAmount \("\(amount.formattedAmount) \(getQUString(amount: amount))")"))
//                                }
//                            }
//                        }
//                    }
                    
                    if quickScanMode == .consume {
                        ConsumeProductView(
                            directProductToConsumeID: product.id,
                            directStockEntryID: grocyCode?.stockID,
                            barcode: productBarcode,
                            consumeType: .consume,
                            quickScan: true,
                            actionFinished: $actionFinished,
                            toastType: $toastType,
                            infoString: $infoString
                        )
                    }
                    
                    if quickScanMode == .markAsOpened {
                        ConsumeProductView(
                            directProductToConsumeID: product.id,
                            directStockEntryID: grocyCode?.stockID,
                            barcode: productBarcode,
                            consumeType: .open,
                            quickScan: true,
                            actionFinished: $actionFinished,
                            toastType: $toastType,
                            infoString: $infoString
                        )
                    }
                    
                    if quickScanMode == .purchase {
                        PurchaseProductView(
                            directProductToPurchaseID: product.id,
                            barcode: productBarcode,
                            quickScan: true,
                            actionFinished: $actionFinished,
                            toastType: $toastType,
                            infoString: $infoString
                        )
                    }
                } else {
                    Text(LocalizedStringKey("str.md.products.empty"))
                }
            }
            .onChange(of: actionFinished, perform: { actionFinished in
                if self.actionFinished {
                    self.dismiss()
                }
            })
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button(LocalizedStringKey("str.cancel")) {
                        self.dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    .disabled(grocyVM.loadingObjectEntities.count > 0)
                })
            })
        }
        .interactiveDismissDisabled(grocyVM.loadingObjectEntities.count > 0)
        .toast(
            item: $toastType,
            isSuccess: Binding.constant(false),
            isShown: [.failConsume, .failOpen, .failPurchase].contains(toastType),
            text: { item in
                switch item {
                case .failConsume:
                    return LocalizedStringKey("str.stock.consume.product.consume.fail")
                case .failOpen:
                    return LocalizedStringKey("str.stock.consume.product.open.fail")
                case .failPurchase:
                    return LocalizedStringKey("str.stock.buy.product.buy.fail")
                default:
                    return LocalizedStringKey("")
                }
            })
        .onAppear(perform: {
            if firstOpen {
                if let productID = product?.id {
                    Task.init {
                        try await grocyVM.getStockProductEntries(productID: productID)
                    }
                }
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
                productBarcode: MDProductBarcode(id: 1, productID: 1, barcode: "1234567891011", quID: 1, amount: 1.0, storeID: 1, lastPrice: 1, rowCreatedTimestamp: "ts", note: "note"),
                grocyCode: nil,
                toastType: Binding.constant(ToastType.successConsume),
                infoString: Binding.constant(nil),
                lastConsumeLocationID: Binding.constant(nil),
                lastPurchaseDueDate: Binding.constant(Date()),
                lastPurchaseStoreID: Binding.constant(nil),
                lastPurchaseLocationID: Binding.constant(nil)
            )
            
            QuickScanModeInputView(
                quickScanMode: Binding.constant(QuickScanMode.markAsOpened),
                productBarcode: MDProductBarcode(id: 1, productID: 1, barcode: "1234567891011", quID: 1, amount: 1.0, storeID: 1, lastPrice: 1, rowCreatedTimestamp: "ts", note: "note"),
                grocyCode: nil,
                toastType: Binding.constant(ToastType.successOpen),
                infoString: Binding.constant(nil),
                lastConsumeLocationID: Binding.constant(nil),
                lastPurchaseDueDate: Binding.constant(Date()),
                lastPurchaseStoreID: Binding.constant(nil),
                lastPurchaseLocationID: Binding.constant(nil)
            )
            
            QuickScanModeInputView(
                quickScanMode: Binding.constant(QuickScanMode.purchase),
                productBarcode: MDProductBarcode(id: 1, productID: 1, barcode: "1234567891011", quID: 1, amount: 1.0, storeID: 1, lastPrice: 1, rowCreatedTimestamp: "ts", note: "note"),
                grocyCode: nil,
                toastType: Binding.constant(ToastType.successPurchase),
                infoString: Binding.constant(nil),
                lastConsumeLocationID: Binding.constant(nil),
                lastPurchaseDueDate: Binding.constant(Date()),
                lastPurchaseStoreID: Binding.constant(nil),
                lastPurchaseLocationID: Binding.constant(nil)
            )
        }
    }
}
