//
//  NewMDRowLabel.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 12.03.21.
//

import SwiftUI

struct NewMDRowLabel: View {
    var title: String
    
    var body: some View {
        HStack{
            Image(systemName: MySymbols.new)
            Text(LocalizedStringKey(title))
        }
        .foregroundStyle(.primary)
        .font(.largeTitle)
        .padding(10)
    }
}

struct NewMDRowLabel_Previews: PreviewProvider {
    static var previews: some View {
        NewMDRowLabel(title: "NEW MD DATA")
    }
}
