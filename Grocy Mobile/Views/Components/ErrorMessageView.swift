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
            Label {
                Text(errorMessage)
                    .foregroundStyle(.primary)
            } icon: {
                Image(systemName: MySymbols.error)
                    .foregroundStyle(Color(.GrocyColors.grocyRed))
            }
            // Tinted background with primary text keeps the contrast above 4.5:1 in light and dark mode.
            .listRowBackground(Color(.GrocyColors.grocyRedBackground))
        }
    }
}

#Preview {
    Form {
        ErrorMessageView(errorMessage: "Error Message")
    }
}
