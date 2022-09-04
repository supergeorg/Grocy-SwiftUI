//
//  QuickScanModeView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 06.01.21.
//

import SwiftUI

enum QuickScanMode {
    case consume, markAsOpened, purchase
    
    func getDescription() -> LocalizedStringKey {
        switch self {
        case .consume:
            return LocalizedStringKey("str.quickScan.consume")
        case .markAsOpened:
            return LocalizedStringKey("str.quickScan.markAsOpened")
        case .purchase:
            return LocalizedStringKey("str.quickScan.purchase")
        }
    }
}

enum QSActiveSheet: Identifiable {
    case barcode, grocyCode, selectProduct
    
    var id: Int {
        hashValue
    }
}

struct QuickScanModeView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @AppStorage("devMode") private var devMode: Bool = false
    @AppStorage("quickScanActionAfterAdd") private var quickScanActionAfterAdd: Bool = false
    
    @State private var flashOn: Bool = false
    @AppStorage("isFrontCamera") private var isFrontCamera: Bool = false
    @State private var quickScanMode: QuickScanMode = .consume
    
    @State private var qsActiveSheet: QSActiveSheet?
    
    @State private var firstInSession: Bool = true
    
    @State private var showDemoGrocyCode: Bool = false
    
    @State var recognizedBarcode: MDProductBarcode? = nil
    @State var newRecognizedBarcode: MDProductBarcode? = nil
    @State var recognizedGrocyCode: GrocyCode? = nil
    @State var notRecognizedBarcode: String? = nil
    
    @State var toastType: ToastType?
    @State private var infoString: String?
    
    @State private var lastConsumeLocationID: Int?
    @State private var lastPurchaseDueDate: Date = .init()
    @State private var lastPurchaseShoppingLocationID: Int?
    @State private var lastPurchaseLocationID: Int?
    
    @State private var isScanPaused: Bool = false
    func checkScanPause() {
        isScanPaused = (qsActiveSheet != nil)
    }
    
    private let dataToUpdate: [ObjectEntities] = [
        .product_barcodes,
        .products,
        .locations,
        .shopping_locations,
        .quantity_units,
        .quantity_unit_conversions,
    ]
    private let additionalDataToUpdate: [AdditionalEntities] = [
        .stock,
        .system_config,
    ]
    
    func updateData() {
        grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }
    
    func searchForGrocyCode(barcodeString: String) -> GrocyCode? {
        let codeComponents = barcodeString.components(separatedBy: ":")
        if codeComponents.count >= 3,
           codeComponents[0] == "grcy",
           codeComponents[1] == "p",
           let productID = Int(codeComponents[2])
        {
            let stockID: String? = codeComponents.count == 4 ? codeComponents[3] : nil
            return GrocyCode(entityType: .product, entityID: productID, stockID: stockID)
        } else {
            return nil
        }
    }
    
    func searchForBarcode(barcodeString: String) -> MDProductBarcode? {
        return grocyVM.mdProductBarcodes.first(where: { $0.barcode == barcodeString })
    }
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        switch result {
        case .success(let barcodeString):
            if let grocyCode = searchForGrocyCode(barcodeString: barcodeString) {
                recognizedGrocyCode = grocyCode
                qsActiveSheet = .grocyCode
            } else if let barcode = searchForBarcode(barcodeString: barcodeString) {
                recognizedBarcode = barcode
                qsActiveSheet = .barcode
            } else {
                notRecognizedBarcode = barcodeString
                qsActiveSheet = .selectProduct
            }
        case .failure(let error):
            grocyVM.postLog("Barcode scan failed. \(error)", type: .error)
        }
    }
    
    var body: some View {
        if grocyVM.failedToLoadObjects.count == 0 && grocyVM.failedToLoadAdditionalObjects.count == 0 {
            bodyContent
        } else {
            ServerProblemView()
                .navigationTitle(LocalizedStringKey("str.nav.quickScan"))
        }
    }
    
    var modePicker: some View {
        HStack {
            Picker(selection: $quickScanMode, label: Label(quickScanMode.getDescription(), systemImage: MySymbols.menuPick), content: {
                Label(QuickScanMode.consume.getDescription(), systemImage: MySymbols.consume)
                    .labelStyle(.titleAndIcon)
                    .tag(QuickScanMode.consume)
                Label(QuickScanMode.markAsOpened.getDescription(), systemImage: MySymbols.open)
                    .labelStyle(.titleAndIcon)
                    .tag(QuickScanMode.markAsOpened)
                Label(QuickScanMode.purchase.getDescription(), systemImage: MySymbols.purchase)
                    .labelStyle(.titleAndIcon)
                    .tag(QuickScanMode.purchase)
            })
            .pickerStyle(.segmented)
            Spacer()
            Button(action: {
                flashOn.toggle()
                toggleTorch(on: flashOn)
            }, label: {
                Image(systemName: flashOn ? "bolt.circle" : "bolt.slash.circle")
                    .font(.title)
            })
            .disabled(!checkForTorch())
            if getFrontCameraAvailable() {
                Button(action: {
                    isFrontCamera.toggle()
                }, label: {
                    Image(systemName: MySymbols.changeCamera)
                        .font(.title)
                })
            }
            if isScanPaused {
                Button(action: {
                    qsActiveSheet = nil
                }, label: {
                    Image(systemName: "pause.rectangle")
                        .font(.title)
                })
            }
        }
        .padding(.vertical)
        .animation(.default, value: isScanPaused)
    }
    
    var bodyContent: some View {
        CodeScannerView(
            codeTypes: getSavedCodeTypes().map { $0.type },
            scanMode: .continuous,
            simulatedData: showDemoGrocyCode ? "grcy:p:13:5fe1f33579ef4" : "5901234123457",
            isPaused: $isScanPaused,
            isFrontCamera: $isFrontCamera,
            completion: self.handleScan
        )
        .overlay(modePicker, alignment: .top)
        .sheet(item: $qsActiveSheet) { item in
            switch item {
            case .grocyCode:
                QuickScanModeInputView(
                    quickScanMode: $quickScanMode,
                    grocyCode: recognizedGrocyCode,
                    toastType: $toastType,
                    infoString: $infoString,
                    lastConsumeLocationID: $lastConsumeLocationID,
                    lastPurchaseDueDate: $lastPurchaseDueDate,
                    lastPurchaseShoppingLocationID: $lastPurchaseShoppingLocationID,
                    lastPurchaseLocationID: $lastPurchaseLocationID
                )
            case .barcode:
                QuickScanModeInputView(
                    quickScanMode: $quickScanMode,
                    productBarcode: recognizedBarcode,
                    toastType: $toastType,
                    infoString: $infoString,
                    lastConsumeLocationID: $lastConsumeLocationID,
                    lastPurchaseDueDate: $lastPurchaseDueDate,
                    lastPurchaseShoppingLocationID: $lastPurchaseShoppingLocationID,
                    lastPurchaseLocationID: $lastPurchaseLocationID
                )
            case .selectProduct:
                QuickScanModeSelectProductView(
                    barcode: notRecognizedBarcode,
                    toastType: $toastType,
                    qsActiveSheet: $qsActiveSheet,
                    newRecognizedBarcode: $newRecognizedBarcode
                )
            }
        }
        .toast(
            item: $toastType,
            isSuccess: Binding.constant(true),
            isShown: [.successAdd, .successConsume, .successOpen, .successPurchase].contains(toastType),
            text: { item in
                switch item {
                case .successAdd:
                    return LocalizedStringKey("str.quickScan.add.product.add.success")
                case .successConsume:
                    return LocalizedStringKey("str.stock.consume.product.consume.success \(infoString ?? "")")
                case .successOpen:
                    return LocalizedStringKey("str.stock.consume.product.open.success \(infoString ?? "")")
                case .successPurchase:
                    return LocalizedStringKey("str.stock.buy.product.buy.success \(infoString ?? "")")
                default:
                    return LocalizedStringKey("str.error")
                }
            })
        .onAppear(perform: {
            grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate, ignoreCached: false)
        })
        .onChange(of: newRecognizedBarcode?.id, perform: { _ in
            DispatchQueue.main.async {
                if quickScanActionAfterAdd {
                    recognizedBarcode = newRecognizedBarcode
                    qsActiveSheet = .barcode
                    checkScanPause()
                }
            }
        })
        .onChange(of: qsActiveSheet, perform: { _ in
            DispatchQueue.main.async {
                checkScanPause()
            }
        })
    }
}

struct QuickScanModeView_Previews: PreviewProvider {
    static var previews: some View {
        QuickScanModeView()
    }
}
