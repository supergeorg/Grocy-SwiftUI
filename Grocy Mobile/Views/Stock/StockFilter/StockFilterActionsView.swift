//
//  StockFilterView.swift
//  grocy-ios
//
//  Created by Georg Meissner on 29.10.20.
//

import SwiftUI

struct StockFilterActionsView: View {
    @Binding var filteredStatus: ProductStatus
    
    var numExpiringSoon: Int?
    var numOverdue: Int?
    var numExpired: Int?
    var numBelowStock: Int?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false){
            HStack{
                StockFilterItemView(num: numExpiringSoon, filteredStatus: $filteredStatus, ownFilteredStatus: ProductStatus.expiringSoon, color: Color(.GrocyColors.grocyYellow), backgroundColor: Color(.GrocyColors.grocyYellowBackground))
                StockFilterItemView(num: numOverdue, filteredStatus: $filteredStatus, ownFilteredStatus: ProductStatus.overdue, color: Color(.GrocyColors.grocyGray), backgroundColor: Color(.GrocyColors.grocyGrayBackground))
                StockFilterItemView(num: numExpired, filteredStatus: $filteredStatus, ownFilteredStatus: ProductStatus.expired, color: Color(.GrocyColors.grocyRed), backgroundColor: Color(.GrocyColors.grocyRedBackground))
                StockFilterItemView(num: numBelowStock, filteredStatus: $filteredStatus, ownFilteredStatus: ProductStatus.belowMinStock, color: Color(.GrocyColors.grocyBlue), backgroundColor: Color(.GrocyColors.grocyBlueBackground))
            }
        }
    }
}

struct StockFilterActionsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockFilterActionsView(filteredStatus: .constant(.expired), numExpiringSoon: 1, numOverdue: 2, numExpired: 2, numBelowStock: 3)
                .environment(\.colorScheme, .light)
            StockFilterActionsView(filteredStatus: .constant(.expired), numExpiringSoon: 1, numOverdue: 2, numExpired: 2, numBelowStock: 3)
                .environment(\.colorScheme, .dark)
        }
    }
}
