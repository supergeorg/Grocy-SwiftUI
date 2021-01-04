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
        VStack(spacing: 0) {
            Divider()
                .hidden()
                .frame(height: 10)
                .background(normalColor)
            HStack {
                if filteredStatus == ownFilteredStatus {
                    Image(systemName: "line.horizontal.3.decrease.circle")
                }
                Text(ownFilteredStatus.getDescription(amount: num))
                    .bold()
                    .foregroundColor(colorScheme == .light ? darkColor : lightColor)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .background(colorScheme == .light ? lightColor : darkColor)
        }
        .fixedSize()
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
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false){
            HStack{
                ShoppingListFilterItemView(num: numBelowStock, filteredStatus: $filteredStatus, ownFilteredStatus: ShoppingListStatus.belowMinStock, normalColor: Color.grocyBlue, lightColor: Color.grocyBlueLight, darkColor: Color.grocyBlueDark)
            }
        }
    }
}

//struct ShoppingListFilterActionView_Previews: PreviewProvider {
//    static var previews: some View {
//        ShoppingListFilterActionView()
//    }
//}
