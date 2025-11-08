//
//  CodeTypes.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 30.06.21.
//

import Foundation
import AVFoundation
import SwiftUI

struct CodeTypeLegacy: Identifiable, Hashable {
    var id = UUID()
    
    var name: String
    var type: AVMetadataObject.ObjectType
}

struct CodeTypesLegacy {
    static let codeAztec = CodeTypeLegacy(name: "Aztec Code", type: .aztec)
    static let code128 = CodeTypeLegacy(name: "Code 128", type: .code128)
    static let code39 = CodeTypeLegacy(name: "Code 39", type: .code39)
    static let code39Mod43 = CodeTypeLegacy(name: "Code 39 mod 43", type: .code39Mod43)
    static let code93 = CodeTypeLegacy(name: "Code 93", type: .code93)
    static let dataMatrix = CodeTypeLegacy(name: "Data Matrix", type: .dataMatrix)
    static let ean13 = CodeTypeLegacy(name: "EAN-13", type: .ean13)
    static let ean8 = CodeTypeLegacy(name: "EAN-8", type: .ean8)
    static let interleaved2of5 = CodeTypeLegacy(name: "Interleaved 2 of 5", type: .interleaved2of5)
    static let itf14 = CodeTypeLegacy(name: "ITF-14", type: .itf14)
    static let pdf417 = CodeTypeLegacy(name: "PDF417", type: .pdf417)
    static let qr = CodeTypeLegacy(name: "QR-Code", type: .qr)
    static let upce = CodeTypeLegacy(name: "UPC-E", type: .upce)
    
    static let types: Set<CodeTypeLegacy> = [codeAztec, code128, code39, code39Mod43, code93, dataMatrix, ean13, ean8, interleaved2of5, itf14, pdf417, qr, upce]
}

func getSavedCodeTypesLegacy() -> Set<CodeTypeLegacy> {
    @AppStorage("enabledCodeAztec") var enabledCodeAztec: Bool = false
    @AppStorage("enabledCode128") var enabledCode128: Bool = false
    @AppStorage("enabledCode39") var enabledCode39: Bool = false
    @AppStorage("enabledCode39Mod43") var enabledCode39Mod43: Bool = false
    @AppStorage("enabledCode93") var enabledCode93: Bool = false
    @AppStorage("enabledCodeDataMatrix") var enabledCodeDataMatrix: Bool = false
    @AppStorage("enabledCodeEAN13") var enabledCodeEAN13: Bool = true
    @AppStorage("enabledCodeEAN8") var enabledCodeEAN8: Bool = true
    @AppStorage("enabledCodeInterleaved2of5") var enabledCodeInterleaved2of5: Bool = false
    @AppStorage("enabledCodeITF14") var enabledCodeITF14: Bool = false
    @AppStorage("enabledCodeQR") var enabledCodeQR: Bool = false
    @AppStorage("enabledCodeUPCE") var enabledCodeUPCE: Bool = false
    
    var enabledCodes: Set<CodeTypeLegacy> = Set<CodeTypeLegacy>()
    
    if enabledCodeAztec { enabledCodes.insert(CodeTypesLegacy.codeAztec) }
    if enabledCode128 { enabledCodes.insert(CodeTypesLegacy.code128) }
    if enabledCode39 { enabledCodes.insert(CodeTypesLegacy.code39) }
    if enabledCode39Mod43 { enabledCodes.insert(CodeTypesLegacy.code39Mod43) }
    if enabledCode93 { enabledCodes.insert(CodeTypesLegacy.code93) }
    if enabledCodeDataMatrix { enabledCodes.insert(CodeTypesLegacy.dataMatrix) }
    if enabledCodeEAN13 { enabledCodes.insert(CodeTypesLegacy.ean13) }
    if enabledCodeEAN8 { enabledCodes.insert(CodeTypesLegacy.ean8) }
    if enabledCodeInterleaved2of5 { enabledCodes.insert(CodeTypesLegacy.interleaved2of5) }
    if enabledCodeITF14 { enabledCodes.insert(CodeTypesLegacy.itf14) }
    if enabledCodeQR { enabledCodes.insert(CodeTypesLegacy.qr) }
    if enabledCodeUPCE { enabledCodes.insert(CodeTypesLegacy.upce) }
    
    return enabledCodes
}
