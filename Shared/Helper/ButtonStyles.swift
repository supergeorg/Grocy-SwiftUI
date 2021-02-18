//
//  ButtonStyles.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 18.02.21.
//

import SwiftUI

struct FilledButtonStyle: ButtonStyle {
    let cornerRadiusValue: CGFloat = 5.0
    let paddingAmount: CGFloat = 9.0
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .padding(paddingAmount)
            .background(Color.accentColor)
            .cornerRadius(cornerRadiusValue)
            .overlay(RoundedRectangle(cornerRadius: cornerRadiusValue).stroke(Color.gray, lineWidth: 1))
    }
}

struct BorderButtonStyle: ButtonStyle {
    let cornerRadiusValue: CGFloat = 5.0
    let paddingAmount: CGFloat = 9.0
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .padding(paddingAmount)
            .cornerRadius(cornerRadiusValue)
            .overlay(RoundedRectangle(cornerRadius: cornerRadiusValue).stroke(Color.gray, lineWidth: 1))
    }
}
