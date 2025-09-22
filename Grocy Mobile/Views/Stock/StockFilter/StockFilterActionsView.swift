//
//  StockFilterActionsView.swift
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                StockFilterCapsuleView(num: numExpiringSoon, filteredStatus: $filteredStatus, ownFilteredStatus: ProductStatus.expiringSoon, color: Color(.GrocyColors.grocyYellow), backgroundColor: Color(.GrocyColors.grocyYellowBackground))
                StockFilterCapsuleView(num: numOverdue, filteredStatus: $filteredStatus, ownFilteredStatus: ProductStatus.overdue, color: Color(.GrocyColors.grocyGray), backgroundColor: Color(.GrocyColors.grocyGrayBackground))
                StockFilterCapsuleView(num: numExpired, filteredStatus: $filteredStatus, ownFilteredStatus: ProductStatus.expired, color: Color(.GrocyColors.grocyRed), backgroundColor: Color(.GrocyColors.grocyRedBackground))
                StockFilterCapsuleView(num: numBelowStock, filteredStatus: $filteredStatus, ownFilteredStatus: ProductStatus.belowMinStock, color: Color(.GrocyColors.grocyBlue), backgroundColor: Color(.GrocyColors.grocyBlueBackground))
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    @Previewable @State var filteredStatus: ProductStatus = .all

    StockFilterActionsView(filteredStatus: $filteredStatus, numExpiringSoon: 1, numOverdue: 2, numExpired: 2, numBelowStock: 3)
        .environment(\.colorScheme, .light)
}
#Preview("Darkmode") {
    @Previewable @State var filteredStatus: ProductStatus = .all

    StockFilterActionsView(filteredStatus: $filteredStatus, numExpiringSoon: 1, numOverdue: 2, numExpired: 2, numBelowStock: 3)
        .environment(\.colorScheme, .dark)
}
