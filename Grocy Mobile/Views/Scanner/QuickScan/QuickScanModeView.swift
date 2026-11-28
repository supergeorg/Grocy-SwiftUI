//
//  QuickScanModeView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 06.01.21.
//

import AVFoundation
import SwiftData
import SwiftUI
import Vision

enum QuickScanMode: CaseIterable {
    case consume, markAsOpened, purchase

    var title: LocalizedStringKey {
        switch self {
        case .consume: "Consume"
        case .markAsOpened: "Open"
        case .purchase: "Purchase"
        }
    }

    var icon: String {
        switch self {
        case .consume: MySymbols.consume
        case .markAsOpened: MySymbols.open
        case .purchase: MySymbols.purchase
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
    /// Set when Quick Scan is presented in a sheet: shows the close button.
    var onClose: (() -> Void)? = nil

    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.openURL) private var openURL
    @Environment(\.grocyFeatures) private var features

    @Query var mdProductBarcodes: MDProductBarcodes
    @Query var mdProducts: MDProducts
    @Query var mdChores: MDChores

    @AppStorage("quickScanActionAfterAdd") private var quickScanActionAfterAdd: Bool = false

    @State private var isTorchOn: Bool = false
    @State private var quickScanMode: QuickScanMode = .consume

    @State private var qsActiveSheet: QSActiveSheet?
    /// The choices of the earlier scans, the defaults of the next ones. Kept until the app quits.
    private var session: QuickScanSession { grocyVM.quickScanSession }

    @State private var showDemoGrocyCode: Bool = false

    @State var recognizedBarcode: MDProductBarcode? = nil
    @State var newRecognizedBarcode: MDProductBarcode? = nil
    @State var recognizedGrocyCode: GrocyCode? = nil
    @State var notRecognizedBarcode: String? = nil

    @State private var cameraUnauthorized: Bool = false

    @State private var isScanPaused: Bool = false
    func checkScanPause() {
        isScanPaused = (qsActiveSheet != nil)
    }

    // For realizing keyboard entry (e.g. external Barcode Scanner)
    @State private var scannedCode = ""
    @FocusState private var isFocused: Bool

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

    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate, additionalObjects: additionalDataToUpdate)
    }

    #if os(iOS)
        func searchForBarcode(barcode: CodeResult) -> MDProductBarcode? {
            if barcode.type == .ean13 {
                return mdProductBarcodes.first(where: { $0.barcode.hasSuffix(barcode.value) })
            } else {
                return mdProductBarcodes.first(where: { $0.barcode == barcode.value })
            }
        }

        func handleScan(result: CodeResult) {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            if let grocyCode = GrocyCode(string: result.value) {
                recognizedBarcode = nil
                recognizedGrocyCode = grocyCode
                qsActiveSheet = .grocyCode
            } else if let foundBarcode = searchForBarcode(barcode: result) {
                recognizedBarcode = foundBarcode
                recognizedGrocyCode = nil
                qsActiveSheet = .barcode
            } else {
                notRecognizedBarcode = result.value
                qsActiveSheet = .selectProduct
            }
        }

        func handleKeyPress(characters: String) {
            if characters == "\n" || characters == "\r" {
                // Barcode scanners typically send Enter/Return after the code
                handleScan(result: CodeResult(value: scannedCode, type: .qr))
                scannedCode = ""
            } else {
                scannedCode += characters
            }
        }
    #endif

    var product: MDProduct? {
        if let grocyCode = recognizedGrocyCode, grocyCode.entityType == .product {
            return mdProducts.first(where: { $0.id == grocyCode.entityID })
        } else if let productBarcode = recognizedBarcode {
            return mdProducts.first(where: { $0.id == productBarcode.productID })
        }
        return nil
    }

    var body: some View {
        if grocyVM.failedToLoadObjects.count == 0 && grocyVM.failedToLoadAdditionalObjects.count == 0 {
            bodyContent
                .ignoresSafeArea()
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                #endif
        } else {
            ServerProblemView()
                .padding()
                .navigationTitle("Quick Scan")
        }
    }

    #if os(iOS)
        @ViewBuilder
        private func barcodeScanner() -> some View {
            CodeScannerView(isPaused: $isScanPaused, onCodeFound: handleScan, onAuthorizationFailed: { cameraUnauthorized = true })
                .onAppear { isScanPaused = false }
                .onDisappear { isScanPaused = true }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    isScanPaused = true
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    isScanPaused = false
                }
        }
    #endif

    var bodyContent: some View {
        #if os(iOS)
            barcodeScanner()
                .sheet(item: $qsActiveSheet) { item in
                    NavigationStack {
                        sheetContent(for: item)
                    }
                }
                .task {
                    Task {
                        await updateData()
                    }
                }
                .alert("Camera Access Required", isPresented: $cameraUnauthorized) {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Please enable camera access in Settings to scan barcodes.")
                }
                .toolbar {
                    // Leading: close (in a sheet) and the torch, the controls of the camera.
                    if let onClose {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(role: .close, action: onClose)
                        }
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        TorchButton(isTorchOn: $isTorchOn)
                    }

                    // Trailing: what a scan does. Labeled with the current mode and a chevron, so it reads as a choice.
                    if isScanPaused {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                qsActiveSheet = nil
                            } label: {
                                Label("Resume", systemImage: MySymbols.quickScanPause)
                                    .macHelp("Resume")
                            }
                        }
                        ToolbarSpacer(.fixed, placement: .topBarTrailing)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("Quick Scan mode", selection: $quickScanMode) {
                                ForEach(QuickScanMode.allCases.filter { features.openedTracking || $0 != .markAsOpened }, id: \.self) { mode in
                                    Label(mode.title, systemImage: mode.icon)
                                        .tag(mode)
                                }
                            }
                            if !session.isEmpty {
                                Section {
                                    Button("Forget last choices", systemImage: MySymbols.reset) {
                                        session.reset()
                                    }
                                }
                            }
                        } label: {
                            // Not a Label: the toolbar would reduce it to its icon.
                            HStack(spacing: Spacing.xSmall) {
                                Image(systemName: quickScanMode.icon)
                                Text(quickScanMode.title)
                                Image(systemName: MySymbols.dropdown)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .fixedSize()
                        }
                        .accessibilityLabel("Quick Scan mode")
                        .accessibilityValue(Text(quickScanMode.title))
                    }
                }
                .onChange(of: newRecognizedBarcode?.id) {
                    GrocyLogger.debug("New recognized barcode: \(String(describing: newRecognizedBarcode?.id))")
                    DispatchQueue.main.async {
                        if quickScanActionAfterAdd {
                            recognizedBarcode = newRecognizedBarcode
                            qsActiveSheet = .barcode
                            checkScanPause()
                        }
                    }
                }
                .onChange(of: qsActiveSheet) {
                    DispatchQueue.main.async {
                        checkScanPause()
                    }
                }
                .focusable()
                .focused($isFocused)
                .onKeyPress { press in
                    handleKeyPress(characters: press.characters)
                    return .handled
                }
                .onAppear {
                    isFocused = true
                }
                .onDisappear {
                    isFocused = false
                    if isTorchOn {
                        isTorchOn = false
                        toggleTorch(state: false)
                    }
                }
        #else
            Text("Not available on this platform.")
        #endif
    }

    // Sheet content based on type
    @ViewBuilder
    private func sheetContent(for sheetType: QSActiveSheet) -> some View {
        switch sheetType {
        case .barcode, .grocyCode:
            if let product = product {
                switch quickScanMode {
                case .consume:
                    ConsumeProductView(
                        directProductToConsumeID: product.id,
                        directStockEntryID: recognizedGrocyCode?.stockID,
                        barcode: recognizedBarcode,
                        consumeType: .consume,
                        quickScan: true,
                        quickScanSession: session,
                        isPopup: true
                    )
                case .markAsOpened:
                    ConsumeProductView(
                        directProductToConsumeID: product.id,
                        directStockEntryID: recognizedGrocyCode?.stockID,
                        barcode: recognizedBarcode,
                        consumeType: .open,
                        quickScan: true,
                        isPopup: true
                    )
                case .purchase:
                    PurchaseProductView(
                        directProductToPurchaseID: product.id,
                        barcode: recognizedBarcode,
                        quickScan: true,
                        quickScanSession: session,
                        isPopup: true
                    )
                }
            } else if let grocyCode = recognizedGrocyCode, grocyCode.entityType == .chore {
                ChoreTrackingView(mdChoreID: grocyCode.entityID)
            } else {
                EmptyView()
            }
        case .selectProduct:
            QuickScanModeSelectProductView(
                barcode: notRecognizedBarcode,
                newRecognizedBarcode: $newRecognizedBarcode
            )

        }
    }
}

#if os(iOS)
    extension View {
        /// Presents Quick Scan in a sheet, for when a button opens it (the iPhone search tab's bottom accessory).
        /// Closed with the close button or by swiping down. Opened from a tab or the sidebar, it's shown in place instead.
        /// With `zoomSource`, the sheet zooms out of the view marked with
        /// `.matchedTransitionSource(id:in:)` for that ID and namespace, and back into it when it closes.
        func quickScanSheet(isPresented: Binding<Bool>, zoomSource: (id: String, namespace: Namespace.ID)? = nil) -> some View {
            sheet(isPresented: isPresented) {
                let scanner = NavigationStack {
                    QuickScanModeView(onClose: { isPresented.wrappedValue = false })
                }
                if let zoomSource {
                    scanner.navigationTransition(.zoom(sourceID: zoomSource.id, in: zoomSource.namespace))
                } else {
                    scanner
                }
            }
        }
    }
#endif

#Preview(traits: .previewData) {
    NavigationStack {
        QuickScanModeView()
    }
}
