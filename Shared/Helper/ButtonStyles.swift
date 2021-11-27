//
//  ButtonStyles.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 18.02.21.
//

import SwiftUI

struct FilledButtonStyle: ButtonStyle {
    let cornerRadiusValue: CGFloat = 5.0
    let paddingAmount: CGFloat = 12.0

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration
                .label
            Spacer()
        }
            .foregroundColor(Color.white)
            .padding(paddingAmount)
            .background(Color.accentColor)
            .cornerRadius(cornerRadiusValue)
    }
}


struct BorderButtonStyle: ButtonStyle {
    let cornerRadiusValue: CGFloat = 5.0
    let paddingAmount: CGFloat = 12.0
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration
                .label
            Spacer()
        }
            .padding(paddingAmount)
            .overlay(RoundedRectangle(cornerRadius: cornerRadiusValue, style: .continuous).stroke(Color.accentColor, lineWidth: 1))
    }
}
