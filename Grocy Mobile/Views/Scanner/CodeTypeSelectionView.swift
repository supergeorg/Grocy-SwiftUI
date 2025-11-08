//
//  CodeTypeSelectionView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 08.11.25.
//

import SwiftUI

struct CodeTypeSelectionView: View {
    @Environment(\.dismiss) var dismiss

    @AppStorage("enabledCodeAztec") var enabledCodeAztec: Bool = true
    @AppStorage("enabledCodeCodabar") var enabledCodeCodabar: Bool = true
    @AppStorage("enabledCode39") var enabledCode39: Bool = true
    @AppStorage("enabledCode39Checksum") var enabledCode39Checksum: Bool = true
    @AppStorage("enabledCode39FullASCII") var enabledCode39FullASCII: Bool = true
    @AppStorage("enabledCode39FullASCIIChecksum") var enabledCode39FullASCIIChecksum: Bool = true
    @AppStorage("enabledCode93") var enabledCode93: Bool = true
    @AppStorage("enabledCode93i") var enabledCode93i: Bool = true
    @AppStorage("enabledCode128") var enabledCode128: Bool = true
    @AppStorage("enabledCodeDataMatrix") var enabledCodeDataMatrix: Bool = true
    @AppStorage("enabledCodeEAN13") var enabledCodeEAN13: Bool = true
    @AppStorage("enabledCodeEAN8") var enabledCodeEAN8: Bool = true
    @AppStorage("enabledCodeGS1DataBar") var enabledCodeGS1DataBar: Bool = true
    @AppStorage("enabledCodeGS1DataBarExpanded") var enabledCodeGS1DataBarExpanded: Bool = true
    @AppStorage("enabledCodeGS1DataBarLimited") var enabledCodeGS1DataBarLimited: Bool = true
    @AppStorage("enabledCodeI2of5") var enabledCodeI2of5: Bool = true
    @AppStorage("enabledCodeI2of5Checksum") var enabledCodeI2of5Checksum: Bool = true
    @AppStorage("enabledCodeITF14") var enabledCodeITF14: Bool = true
    @AppStorage("enabledCodeMicroPDF417") var enabledCodeMicroPDF417: Bool = true
    @AppStorage("enabledCodeMicroQR") var enabledCodeMicroQR: Bool = true
    @AppStorage("enabledCodeMSIPlessey") var enabledCodeMSIPlessey: Bool = true
    @AppStorage("enabledCodePDF417") var enabledCodePDF417: Bool = true
    @AppStorage("enabledCodeQR") var enabledCodeQR: Bool = true
    @AppStorage("enabledCodeUPCE") var enabledCodeUPCE: Bool = true

    var body: some View {
        List {
            Section("Basic Barcodes") {
                Toggle(CodeTypes.ean13.name, isOn: $enabledCodeEAN13)
                Toggle(CodeTypes.ean8.name, isOn: $enabledCodeEAN8)
                Toggle(CodeTypes.upce.name, isOn: $enabledCodeUPCE)
                Toggle(CodeTypes.code128.name, isOn: $enabledCode128)
            }
            Section("Code 39 / Code 93 / Codabar family") {
                Toggle(CodeTypes.code39.name, isOn: $enabledCode39)
                Toggle(CodeTypes.code39Checksum.name, isOn: $enabledCode39Checksum)
                Toggle(CodeTypes.code39FullASCII.name, isOn: $enabledCode39FullASCII)
                Toggle(CodeTypes.code39FullASCIIChecksum.name, isOn: $enabledCode39FullASCIIChecksum)
                Toggle(CodeTypes.code93.name, isOn: $enabledCode93)
                Toggle(CodeTypes.code93i.name, isOn: $enabledCode93i)
                Toggle(CodeTypes.codabar.name, isOn: $enabledCodeCodabar)
            }
            Section("2D Matrix codes") {
                Toggle(CodeTypes.qr.name, isOn: $enabledCodeQR)
                Toggle(CodeTypes.microQR.name, isOn: $enabledCodeMicroQR)
                Toggle(CodeTypes.aztec.name, isOn: $enabledCodeAztec)
                Toggle(CodeTypes.dataMatrix.name, isOn: $enabledCodeDataMatrix)
                Toggle(CodeTypes.pdf417.name, isOn: $enabledCodePDF417)
                Toggle(CodeTypes.microPDF417.name, isOn: $enabledCodeMicroPDF417)
            }
            Section("GS1 family") {
                Toggle(CodeTypes.gs1DataBar.name, isOn: $enabledCodeGS1DataBar)
                Toggle(CodeTypes.gs1DataBarExpanded.name, isOn: $enabledCodeGS1DataBarExpanded)
                Toggle(CodeTypes.gs1DataBarLimited.name, isOn: $enabledCodeGS1DataBarLimited)
            }
            Section("Industrial codes") {
                Toggle(CodeTypes.i2of5.name, isOn: $enabledCodeI2of5)
                Toggle(CodeTypes.i2of5Checksum.name, isOn: $enabledCodeI2of5Checksum)
                Toggle(CodeTypes.itf14.name, isOn: $enabledCodeITF14)
                Toggle(CodeTypes.msiPlessey.name, isOn: $enabledCodeMSIPlessey)
            }
        }
        .navigationTitle("Barcode settings")
        .toolbar {
            ToolbarItem(
                placement: .destructiveAction,
                content: {
                    Button(
                        role: .close,
                        action: {
                            self.dismiss()
                        })
                })
        }
    }
}

#Preview {
    CodeTypeSelectionView()
}
