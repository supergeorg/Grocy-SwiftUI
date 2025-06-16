//
//  CodeTypes.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 30.06.21.
//

import Foundation
import AVFoundation
import SwiftUI

struct CodeType: Identifiable, Hashable {
    var id = UUID()
    
    var name: String
    var type: AVMetadataObject.ObjectType
}

struct CodeTypes {
    static let codeAztec = CodeType(name: "Aztec Code", type: .aztec)
    static let code128 = CodeType(name: "Code 128", type: .code128)
    static let code39 = CodeType(name: "Code 39", type: .code39)
    static let code39Mod43 = CodeType(name: "Code 39 mod 43", type: .code39Mod43)
    static let code93 = CodeType(name: "Code 93", type: .code93)
    static let dataMatrix = CodeType(name: "Data Matrix", type: .dataMatrix)
    static let ean13 = CodeType(name: "EAN-13", type: .ean13)
    static let ean8 = CodeType(name: "EAN-8", type: .ean8)
    static let interleaved2of5 = CodeType(name: "Interleaved 2 of 5", type: .interleaved2of5)
    static let itf14 = CodeType(name: "ITF-14", type: .itf14)
    static let pdf417 = CodeType(name: "PDF417", type: .pdf417)
    static let qr = CodeType(name: "QR-Code", type: .qr)
    static let upce = CodeType(name: "UPC-E", type: .upce)
    
    static let types: Set<CodeType> = [codeAztec, code128, code39, code39Mod43, code93, dataMatrix, ean13, ean8, interleaved2of5, itf14, pdf417, qr, upce]
}

func getSavedCodeTypes() -> Set<CodeType> {
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
    
    var enabledCodes: Set<CodeType> = Set<CodeType>()
    
    if enabledCodeAztec { enabledCodes.insert(CodeTypes.codeAztec) }
    if enabledCode128 { enabledCodes.insert(CodeTypes.code128) }
    if enabledCode39 { enabledCodes.insert(CodeTypes.code39) }
    if enabledCode39Mod43 { enabledCodes.insert(CodeTypes.code39Mod43) }
    if enabledCode93 { enabledCodes.insert(CodeTypes.code93) }
    if enabledCodeDataMatrix { enabledCodes.insert(CodeTypes.dataMatrix) }
    if enabledCodeEAN13 { enabledCodes.insert(CodeTypes.ean13) }
    if enabledCodeEAN8 { enabledCodes.insert(CodeTypes.ean8) }
    if enabledCodeInterleaved2of5 { enabledCodes.insert(CodeTypes.interleaved2of5) }
    if enabledCodeITF14 { enabledCodes.insert(CodeTypes.itf14) }
    if enabledCodeQR { enabledCodes.insert(CodeTypes.qr) }
    if enabledCodeUPCE { enabledCodes.insert(CodeTypes.upce) }
    
    return enabledCodes
}
