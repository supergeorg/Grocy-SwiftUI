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
        .foregroundStyle(Color.white)
        .padding(paddingAmount)
        .background(Color.accentColor)
        .cornerRadius(cornerRadiusValue)
        .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}


struct BorderButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    let cornerRadiusValue: CGFloat = 5.0
    let paddingAmount: CGFloat = 12.0
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration
                .label
            Spacer()
        }
        .foregroundStyle(Color.primary)
        .padding(paddingAmount)
        .background(colorScheme == .light ? Color.white : Color.black)
        .cornerRadius(cornerRadiusValue)
        .overlay(RoundedRectangle(cornerRadius: cornerRadiusValue, style: .continuous).stroke(Color.accentColor, lineWidth: 1))
        .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
