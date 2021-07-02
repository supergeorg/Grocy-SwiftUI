//
//  CodeTypeSelectionView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 30.06.21.
//

import SwiftUI
import AVFoundation

struct CodeTypeSelectionView: View {
    @State private var selection = Set<CodeType>()
    @State private var firstAppear = true
    
    var body: some View {
        List(Array(CodeTypes.types).sorted{$0.name < $1.name}, id:\.self, selection: $selection) { codeType in
            HStack{
                if selection.contains(codeType) {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text(codeType.name)
            }
        }
        .navigationTitle(LocalizedStringKey("str.settings.codeTypes"))
        .toolbar {
            EditButton()
        }
        .onChange(of: selection, perform: { value in
            if !firstAppear {
                saveCodeTypes(enabledCodes: selection)
            }
        })
        .onAppear {
            selection = getSavedCodeTypes()
            firstAppear = false
        }
    }
}

struct CodeTypeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            CodeTypeSelectionView()
        }
    }
}
