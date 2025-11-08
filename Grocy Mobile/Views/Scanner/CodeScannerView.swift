////
////  CodeScannerView.swift
////  Grocy Mobile
////
////  Created by Georg Meißner on 08.11.25.
////

import SwiftUI
import Vision
import VisionKit

struct CodeResult: Hashable {
    var value: String
    var type: VNBarcodeSymbology
}

#if os(iOS)
    @MainActor
    struct CodeScannerView: UIViewControllerRepresentable {
        @Binding var isPaused: Bool
        var onCodeFound: ((CodeResult) -> Void)?

        init(isPaused: Binding<Bool>, onCodeFound: ((CodeResult) -> Void)? = nil) {
            self._isPaused = isPaused
            self.onCodeFound = onCodeFound
        }

        func makeUIViewController(context: Context) -> DataScannerViewController {
            let scannerViewController = DataScannerViewController(
                recognizedDataTypes: [
                    .barcode(symbologies: getSavedCodeTypes())
                ],
                qualityLevel: .balanced,
                recognizesMultipleItems: false,
                isHighFrameRateTrackingEnabled: false,
                isHighlightingEnabled: true,
            )

            scannerViewController.delegate = context.coordinator

            // Start scanning immediately after creation
            try? scannerViewController.startScanning()

            return scannerViewController
        }

        var scannerAvailable: Bool {
            DataScannerViewController.isSupported && DataScannerViewController.isAvailable
        }

        func updateUIViewController(
            _ uiViewController: DataScannerViewController,
            context: Context
        ) {
            if isPaused && uiViewController.isScanning {
                uiViewController.stopScanning()
            } else if !isPaused && !uiViewController.isScanning {
                try? uiViewController.startScanning()
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, DataScannerViewControllerDelegate {
            var parent: CodeScannerView
            private var lastScanTime: Date = .distantPast
            private let debounceInterval: TimeInterval = 2.0

            init(_ parent: CodeScannerView) {
                self.parent = parent
            }

            func dataScanner(
                _ dataScanner: DataScannerViewController,
                didAdd addedItems: [RecognizedItem],
                allItems: [RecognizedItem]
            ) {
                let currentTime = Date()
                guard currentTime.timeIntervalSince(lastScanTime) >= debounceInterval else {
                    return  // Skip if not enough time has passed since last scan
                }

                for item in addedItems {
                    switch item {
                    case .barcode(let code):
                        if let payload = code.payloadStringValue, let callback = parent.onCodeFound {
                            lastScanTime = currentTime
                            callback(CodeResult(value: payload, type: code.observation.symbology))
                        }
                    default:
                        print("Not implemented")
                    }
                }
            }
        }
    }
#endif
