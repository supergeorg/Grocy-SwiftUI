//
//  CodeTypeSelectionView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 30.06.21.
//

import SwiftUI
import AVFoundation

struct CodeTypeSelectionView: View {
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
    
    var body: some View {
        List() {
            Group {
                Toggle(CodeTypes.codeAztec.name, isOn: $enabledCodeAztec)
                Toggle(CodeTypes.code128.name, isOn: $enabledCode128)
                Toggle(CodeTypes.code39.name, isOn: $enabledCode39)
                Toggle(CodeTypes.code39Mod43.name, isOn: $enabledCode39Mod43)
                Toggle(CodeTypes.code93.name, isOn: $enabledCode93)
                Toggle(CodeTypes.dataMatrix.name, isOn: $enabledCodeDataMatrix)
            }
            Group {
                Toggle(CodeTypes.ean13.name, isOn: $enabledCodeEAN13)
                Toggle(CodeTypes.ean8.name, isOn: $enabledCodeEAN8)
                Toggle(CodeTypes.interleaved2of5.name, isOn: $enabledCodeInterleaved2of5)
                Toggle(CodeTypes.itf14.name, isOn: $enabledCodeITF14)
                Toggle(CodeTypes.qr.name, isOn: $enabledCodeQR)
                Toggle(CodeTypes.upce.name, isOn: $enabledCodeUPCE)
            }
        }
        .navigationTitle(LocalizedStringKey("str.settings.codeTypes"))
    }
}

struct CodeTypeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            CodeTypeSelectionView()
        }
    }
}
