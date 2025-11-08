//
//  BarcodeTypes.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 08.11.25.
//

import SwiftUI
import Vision

struct CodeType: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var type: VNBarcodeSymbology
}

struct CodeTypes {
    static let aztec = CodeType(name: "Aztec Code", type: .aztec)
    static let codabar = CodeType(name: "Codabar", type: .codabar)
    static let code39 = CodeType(name: "Code 39", type: .code39)
    static let code39Checksum = CodeType(name: "Code 39 Checksum", type: .code39Checksum)
    static let code39FullASCII = CodeType(name: "Code 39 Full ASCII", type: .code39FullASCII)
    static let code39FullASCIIChecksum = CodeType(name: "Code 39 Full ASCII Checksum", type: .code39FullASCIIChecksum)
    static let code93 = CodeType(name: "Code 93", type: .code93)
    static let code93i = CodeType(name: "Code 93i", type: .code93i)
    static let code128 = CodeType(name: "Code 128", type: .code128)
    static let dataMatrix = CodeType(name: "Data Matrix", type: .dataMatrix)
    static let ean8 = CodeType(name: "EAN-8", type: .ean8)
    static let ean13 = CodeType(name: "EAN-13", type: .ean13)
    static let gs1DataBar = CodeType(name: "GS1 DataBar", type: .gs1DataBar)
    static let gs1DataBarExpanded = CodeType(name: "GS1 DataBar Expanded", type: .gs1DataBarExpanded)
    static let gs1DataBarLimited = CodeType(name: "GS1 DataBar Limited", type: .gs1DataBarLimited)
    static let i2of5 = CodeType(name: "Interleaved 2 of 5", type: .i2of5)
    static let i2of5Checksum = CodeType(name: "Interleaved 2 of 5 Checksum", type: .i2of5Checksum)
    static let itf14 = CodeType(name: "ITF-14", type: .itf14)
    static let microPDF417 = CodeType(name: "MicroPDF417", type: .microPDF417)
    static let microQR = CodeType(name: "Micro QR", type: .microQR)
    static let msiPlessey = CodeType(name: "Modified Plessey", type: .msiPlessey)
    static let pdf417 = CodeType(name: "PDF417", type: .pdf417)
    static let qr = CodeType(name: "QR-Code", type: .qr)
    static let upce = CodeType(name: "UPC-E", type: .upce)

    static let types: Set<CodeType> = [
        aztec, codabar, code128, code39, code39Checksum, code39FullASCII,
        code39FullASCIIChecksum, code93, code93i, dataMatrix, ean13, ean8,
        gs1DataBar, gs1DataBarExpanded, gs1DataBarLimited, i2of5, i2of5Checksum,
        itf14, microPDF417, microQR, pdf417, qr, upce,
    ]
}

func getSavedCodeTypes() -> [VNBarcodeSymbology] {
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

    var enabledCodes: Set<VNBarcodeSymbology> = Set<VNBarcodeSymbology>()

    if enabledCodeAztec { enabledCodes.insert(CodeTypes.aztec.type) }
    if enabledCodeCodabar { enabledCodes.insert(CodeTypes.codabar.type) }
    if enabledCode39 { enabledCodes.insert(CodeTypes.code39.type) }
    if enabledCode39Checksum { enabledCodes.insert(CodeTypes.code39Checksum.type) }
    if enabledCode39FullASCII { enabledCodes.insert(CodeTypes.code39FullASCII.type) }
    if enabledCode39FullASCIIChecksum { enabledCodes.insert(CodeTypes.code39FullASCIIChecksum.type) }
    if enabledCode93 { enabledCodes.insert(CodeTypes.code93.type) }
    if enabledCode93i { enabledCodes.insert(CodeTypes.code93i.type) }
    if enabledCode128 { enabledCodes.insert(CodeTypes.code128.type) }
    if enabledCodeDataMatrix { enabledCodes.insert(CodeTypes.dataMatrix.type) }
    if enabledCodeEAN13 { enabledCodes.insert(CodeTypes.ean13.type) }
    if enabledCodeEAN8 { enabledCodes.insert(CodeTypes.ean8.type) }
    if enabledCodeGS1DataBar { enabledCodes.insert(CodeTypes.gs1DataBar.type) }
    if enabledCodeGS1DataBarExpanded { enabledCodes.insert(CodeTypes.gs1DataBarExpanded.type) }
    if enabledCodeGS1DataBarLimited { enabledCodes.insert(CodeTypes.gs1DataBarLimited.type) }
    if enabledCodeI2of5 { enabledCodes.insert(CodeTypes.i2of5.type) }
    if enabledCodeI2of5Checksum { enabledCodes.insert(CodeTypes.i2of5Checksum.type) }
    if enabledCodeITF14 { enabledCodes.insert(CodeTypes.itf14.type) }
    if enabledCodeMicroPDF417 { enabledCodes.insert(CodeTypes.microPDF417.type) }
    if enabledCodeMicroQR { enabledCodes.insert(CodeTypes.microQR.type) }
    if enabledCodeMSIPlessey { enabledCodes.insert(CodeTypes.msiPlessey.type) }
    if enabledCodePDF417 { enabledCodes.insert(CodeTypes.pdf417.type) }
    if enabledCodeQR { enabledCodes.insert(CodeTypes.qr.type) }
    if enabledCodeUPCE { enabledCodes.insert(CodeTypes.upce.type) }

    let request = VNDetectBarcodesRequest()
    do {
        let symbologies = try request.supportedSymbologies()
        for code in enabledCodes {
            if !symbologies.contains(code) {
                enabledCodes.remove(code)
                NSLog("Removed code \(code).")
            }
        }
    } catch {
        print("Error fetching supported symbologies: \(error)")
    }

    return Array(enabledCodes)
}
