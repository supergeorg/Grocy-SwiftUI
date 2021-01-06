//
//  QuickScanModeView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 06.01.21.
//

import SwiftUI
import AVFoundation

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

func checkForTorch() -> Bool {
    guard let device = AVCaptureDevice.default(for: .video) else { return false }
    return device.hasTorch
}

func toggleTorch(on: Bool) {
    guard let device = AVCaptureDevice.default(for: .video) else { return }

    if device.hasTorch {
        do {
            try device.lockForConfiguration()

            if on == true {
                device.torchMode = .on
            } else {
                device.torchMode = .off
            }

            device.unlockForConfiguration()
        } catch {
            print("Torch could not be used")
        }
    } else {
        print("Torch is not available")
    }
}

struct QuickScanModeView: View {
    @State private var flashOn: Bool = false
    @State private var quickScanMode: QuickScanMode = .consume
    @State private var showConfig: Bool = false
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        switch result {
        case .success(let barcode):
            print(barcode)
            guard barcode.count == 13 else {return}
            
            print("sucess")
        case .failure(let error):
            print("Scanning failed")
            print(error)
        }
    }
    
    var body: some View {
        ZStack(alignment: .top){
            CodeScannerView(codeTypes: [.ean13], simulatedData: "5901234123457", completion: self.handleScan)
            HStack{
                Button(action: {
                    showConfig.toggle()
                }, label: {
                    Image(systemName: "gear")
                })
                Spacer()
                Picker(selection: $quickScanMode, label: Label(quickScanMode.getDescription(), systemImage: "chevron.down.circle"), content: {
                    Text(QuickScanMode.consume.getDescription()).tag(QuickScanMode.consume)
                    Text(QuickScanMode.markAsOpened.getDescription()).tag(QuickScanMode.markAsOpened)
                    Text(QuickScanMode.purchase.getDescription()).tag(QuickScanMode.purchase)
                })
                .pickerStyle(MenuPickerStyle())
                Spacer()
                Button(action: {
                    flashOn.toggle()
                    toggleTorch(on: flashOn)
                }, label: {
                    Image(systemName: flashOn ? "bolt.circle" : "bolt.slash.circle")
                })
                .disabled(!checkForTorch())
            }
            .padding(.horizontal)
        }
        .popover(isPresented: $showConfig, content: {
            QuickScanModeConfigView()
        })
    }
}

struct QuickScanModeView_Previews: PreviewProvider {
    static var previews: some View {
        QuickScanModeView()
    }
}
