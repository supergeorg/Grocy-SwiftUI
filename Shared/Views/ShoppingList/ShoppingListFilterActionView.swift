//
//  ShoppingListFilterActionView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 27.11.20.
//

import SwiftUI

private struct ShoppingListFilterItemView: View {
    @Environment(\.colorScheme) var colorScheme
    var num: Int
    @Binding var filteredStatus: ShoppingListStatus
    var ownFilteredStatus: ShoppingListStatus
    var normalColor: Color
    var lightColor: Color
    var darkColor: Color
    
    var body: some View {
        VStack(spacing: 0.0) {
            Divider()
                .hidden()
                .frame(height: 10.0)
                .background(normalColor)
            HStack {
                if filteredStatus == ownFilteredStatus {
                    Image(systemName: MySymbols.filter)
                }
                Text(ownFilteredStatus.getDescription(amount: num))
                    .bold()
                    .foregroundColor(colorScheme == .light ? darkColor : lightColor)
            }
            .padding(.horizontal, 10.0)
            .padding(.top, 10.0)
            .padding(.bottom, 10.0)
            .background(colorScheme == .light ? lightColor : darkColor)
        }
        .fixedSize()
        .cornerRadius(5.0)
        .onTapGesture {
            if filteredStatus != ownFilteredStatus {
                filteredStatus = ownFilteredStatus
            } else {
                filteredStatus = ShoppingListStatus.all
            }
        }
    }
}

struct ShoppingListFilterActionView: View {
    @Binding var filteredStatus: ShoppingListStatus

    var numBelowStock: Int
    var numUndone: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false){
            HStack{
                // Undone items
                ShoppingListFilterItemView(
                    num: numUndone,
                    filteredStatus: $filteredStatus,
                    ownFilteredStatus: ShoppingListStatus.undone,
                    normalColor: Color.grocyGray,
                    lightColor: Color.grocyGrayLight,
                    darkColor: Color.grocyGrayDark
                )
                // Below stock
                ShoppingListFilterItemView(
                    num: numBelowStock,
                    filteredStatus: $filteredStatus,
                    ownFilteredStatus: ShoppingListStatus.belowMinStock,
                    normalColor: Color.grocyBlue,
                    lightColor: Color.grocyBlueLight,
                    darkColor: Color.grocyBlueDark
                )
            }
        }
    }
}

struct ShoppingListFilterActionView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListFilterActionView(filteredStatus: Binding.constant(.all), numBelowStock: 1, numUndone: 1)
    }
}
