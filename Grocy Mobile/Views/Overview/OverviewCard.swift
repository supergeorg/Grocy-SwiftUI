//
//  OverviewCard.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 17.10.23.
//

import SwiftUI

struct OverviewCard: View {
    var title: String
    var highlightColor: Color
    var icon: String
    var number: Int? = nil
    
    var selected: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: icon)
                    .symbolVariant(.circle)
                    .symbolVariant(.fill)
                    .font(.title)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        selected ? highlightColor : .white, selected ? .white : highlightColor
                    )
                Spacer()
                if let number = number {
                    Text("\(number)")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .padding(.trailing)
                }
            }
            Text(title)
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(8)
        .padding(.horizontal, 5)
        .background(selected ? highlightColor : Color(.GrocyColors.grocyGrayBackground))//Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview("Not selected") {
    OverviewCard(title: "Test", highlightColor: Color.red, icon: MySymbols.stockOverview, number: 69)
}
#Preview("Darkmode") {
    OverviewCard(title: "Test", highlightColor: Color.red, icon: MySymbols.stockOverview, number: 69)
        .preferredColorScheme(.dark)
}
#Preview("Selected") {
    OverviewCard(title: "Test", highlightColor: Color.red, icon: MySymbols.stockOverview, number: 69, selected: true)
}
#Preview("Selected Darkmode") {
    OverviewCard(title: "Test", highlightColor: Color.red, icon: MySymbols.stockOverview, number: 69, selected: true)
        .preferredColorScheme(.dark)
}

