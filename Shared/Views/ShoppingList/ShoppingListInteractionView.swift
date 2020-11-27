//
//  ShoppingListInteractionView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 27.11.20.
//

import SwiftUI

struct ShoppingListInteractionView: View {
    let cornerRadiusValue: CGFloat = 5.0
    let paddingAmount: CGFloat = 4.0
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false){
            HStack(spacing: 5){
                Text("str.shL.action.addItem".localized)
                    .padding(paddingAmount)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(cornerRadiusValue)
                Text("str.shL.action.clearList".localized)
                    .padding(paddingAmount)
                    .foregroundColor(.red)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadiusValue)
                            .stroke(Color.red, lineWidth: 1)
                    )
                Text("str.shL.action.addListItemsToStock".localized)
                    .padding(paddingAmount)
                    .foregroundColor(.blue)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadiusValue)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                Text("str.shL.action.addBelowMinStock".localized)
                    .padding(paddingAmount)
                    .foregroundColor(.blue)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadiusValue)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                Text("str.shL.action.addOverdue".localized)
                    .padding(paddingAmount)
                    .foregroundColor(.blue)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadiusValue)
                            .stroke(Color.blue, lineWidth: 1)
                    )
            }
        }
    }
}

struct ShoppingListInteractionView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListInteractionView()
    }
}
