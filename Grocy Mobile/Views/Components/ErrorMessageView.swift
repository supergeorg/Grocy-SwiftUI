//
//  ErrorMessageView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 13.10.23.
//

import SwiftUI

struct ErrorMessageView: View {
    var errorMessage: String
    
    var body: some View {
        Section {
            HStack(alignment: .center) {
                Image(systemName: MySymbols.error)
                    .font(.title2)
                Text(errorMessage)
            }
            .listRowBackground(Color.red)
        }
    }
}

#Preview {
    ErrorMessageView(errorMessage: "Error Message")
}
