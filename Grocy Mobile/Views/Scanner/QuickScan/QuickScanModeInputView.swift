//
//  QuickScanModeInputView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 06.01.21.
//

import SwiftUI
import SwiftData

enum ConsumeAmountMode {
    case standard, barcode, custom, all
}

struct QuickScanModeInputView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query(sort: \StockElement.productID, order: .forward) var stock: Stock
    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query(sort: \MDQuantityUnitConversion.id, order: .forward) var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query(sort: \StockEntry.id, order: .forward) var stockProductEntries: StockEntries
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstOpen: Bool = true
    @State private var firstClose: Bool = true
    
    @Binding var quickScanMode: QuickScanMode
    var productBarcode: MDProductBarcode?
    var grocyCode: GrocyCode?
    
    @State private var consumeAmountMode: ConsumeAmountMode = .standard
    
    @State private var isProcessingAction: Bool = false
    
    @State var actionFinished: Bool = false
    
    var product: MDProduct? {
        if let grocyCode = grocyCode {
            return mdProducts.first(where: { $0.id == grocyCode.entityID })
        } else if let productBarcode = productBarcode {
            return mdProducts.first(where: { $0.id == productBarcode.productID })
        }
        return nil
    }
    
    var stockElement: StockElement? {
        stock.first(where: { $0.productID == product?.id })
    }
    
    var quantityUnitPurchase: MDQuantityUnit? {
        mdQuantityUnits.first(where: { $0.id == product?.quIDPurchase })
    }
    
    var quantityUnitStock: MDQuantityUnit? {
        mdQuantityUnits.first(where: { $0.id == product?.quIDStock })
    }
    
    private var quantityUnitConversions: [MDQuantityUnitConversion] {
        return mdQuantityUnitConversions.filter { $0.toQuID == product?.quIDStock }
    }
    
    private var purchaseAmountFactored: Double {
        return purchaseAmount * (quantityUnitConversions.first(where: { $0.fromQuID == purchaseQuantityUnitID })?.factor ?? 1)
    }
    
    private var purchaseUnitPrice: Double? {
        if purchaseIsTotalPrice {
            return ((purchasePrice ?? 0.0) / purchaseAmountFactored)
        } else {
            return purchasePrice
        }
    }
    
    private func getAmountForLocation(lID: Int) -> Double {
        var maxAmount: Double = 0.0
        let filtEntries = stockProductEntries.filter { entry in
            entry.productID == product?.id && entry.locationID == lID
        }
        for filtEntry in filtEntries {
            maxAmount += filtEntry.amount
        }
        return maxAmount
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
                    Section {
                        HStack {
                            if let pictureFileName = product.pictureFileName {
                                PictureView(pictureFileName: pictureFileName, pictureType: .productPictures, maxWidth: 50.0, maxHeight: 50.0)
                            }
                            VStack(alignment: .leading) {
                                Text(product.name).font(.title)
                                if let amount = stockElement?.amount {
                                    Text("Stock amount: \(amount.formattedAmount) \(quantityUnitStock?.getName(amount: amount) ?? "")")
                                }
                            }
                        }
                    }
                    
                    if quickScanMode == .consume {
                        ConsumeProductView(
                            directProductToConsumeID: product.id,
                            directStockEntryID: grocyCode?.stockID,
                            barcode: productBarcode,
                            consumeType: .consume,
                            quickScan: true,
                            actionFinished: $actionFinished
                        )
                    }
                    
                    if quickScanMode == .markAsOpened {
                        ConsumeProductView(
                            directProductToConsumeID: product.id,
                            directStockEntryID: grocyCode?.stockID,
                            barcode: productBarcode,
                            consumeType: .open,
                            quickScan: true,
                            actionFinished: $actionFinished
                        )
                    }
                    
                    if quickScanMode == .purchase {
                        PurchaseProductView(
                            directProductToPurchaseID: product.id,
                            barcode: productBarcode,
                            quickScan: true,
                            actionFinished: $actionFinished
                        )
                    }
                } else {
                    Text("No products found.")
                }
            }
            .onChange(of: actionFinished) {
                if self.actionFinished {
                    self.dismiss()
                }
            }
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button("Cancel") {
                        self.dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    .disabled(grocyVM.loadingObjectEntities.count > 0)
                })
            })
        }
        .interactiveDismissDisabled(grocyVM.loadingObjectEntities.count > 0)
        .task {
            if firstOpen {
                if let productID = product?.id {
                    do {
                        try await grocyVM.getStockProductEntries(productID: productID)
                    } catch {
                        GrocyLogger.error("Get stock product entries failed. \(error)")
                    }
                }
                firstOpen = false
            }
        }
    }
}

//struct QuickScanModeInputView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            QuickScanModeInputView(
//                quickScanMode: Binding.constant(QuickScanMode.consume),
//                productBarcode: MDProductBarcode(id: 1, productID: 1, barcode: "1234567891011", quID: 1, amount: 1.0, storeID: 1, lastPrice: 1, rowCreatedTimestamp: "ts", note: "note"),
//                grocyCode: nil,
//                lastConsumeLocationID: Binding.constant(nil),
//                lastPurchaseDueDate: Binding.constant(Date()),
//                lastPurchaseStoreID: Binding.constant(nil),
//                lastPurchaseLocationID: Binding.constant(nil)
//            )
//            
//            QuickScanModeInputView(
//                quickScanMode: Binding.constant(QuickScanMode.markAsOpened),
//                productBarcode: MDProductBarcode(id: 1, productID: 1, barcode: "1234567891011", quID: 1, amount: 1.0, storeID: 1, lastPrice: 1, rowCreatedTimestamp: "ts", note: "note"),
//                grocyCode: nil,
//                lastConsumeLocationID: Binding.constant(nil),
//                lastPurchaseDueDate: Binding.constant(Date()),
//                lastPurchaseStoreID: Binding.constant(nil),
//                lastPurchaseLocationID: Binding.constant(nil)
//            )
//            
//            QuickScanModeInputView(
//                quickScanMode: Binding.constant(QuickScanMode.purchase),
//                productBarcode: MDProductBarcode(id: 1, productID: 1, barcode: "1234567891011", quID: 1, amount: 1.0, storeID: 1, lastPrice: 1, rowCreatedTimestamp: "ts", note: "note"),
//                grocyCode: nil,
//                lastConsumeLocationID: Binding.constant(nil),
//                lastPurchaseDueDate: Binding.constant(Date()),
//                lastPurchaseStoreID: Binding.constant(nil),
//                lastPurchaseLocationID: Binding.constant(nil)
//            )
//        }
//    }
//}
