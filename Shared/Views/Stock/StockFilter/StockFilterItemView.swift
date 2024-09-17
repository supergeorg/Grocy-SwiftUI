//
//  StockFilterItemView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 05.10.23.
//

import SwiftUI
import SwiftData

struct StockFilterItemView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @Query var userSettingsList: GrocyUserSettingsList
    var userSettings: GrocyUserSettings? {
        return userSettingsList.first
    }
    
    var num: Int?
    @Binding var filteredStatus: ProductStatus
    var ownFilteredStatus: ProductStatus
    var color: Color
    var backgroundColor: Color
    
#if os(iOS)
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
#endif
    
    var body: some View {
        HStack{
            if filteredStatus == ownFilteredStatus {
                Image(systemName: MySymbols.filter)
            }
#if os(iOS)
            // check if small display (not widescreen or iPad)
            if horizontalSizeClass == .compact && verticalSizeClass == .regular {
                HStack{
                    Text(String(num ?? 0))
                        .bold()
                    Image(systemName: ownFilteredStatus.getIconName())
                }
            } else {
                Text(ownFilteredStatus.getDescription(amount: num ?? 0, dueSoonDays: userSettings?.stockDueSoonDays ?? 5))
                    .bold()
            }
#elseif os(macOS)
            Text(ownFilteredStatus.getDescription(amount: num ?? 0, dueSoonDays: userSettings?.stockDueSoonDays ?? 5))
                .bold()
#endif
        }
        .padding(.horizontal, 10.0)
        .padding(.top, 15.0)
        .padding(.bottom, 10.0)
        .background(backgroundColor)
        .overlay(alignment: .top) {
            Rectangle()
                .frame(width: nil, height: 10.0, alignment: .top)
                .foregroundStyle(color)
        }
        .onTapGesture {
            if filteredStatus != ownFilteredStatus {
                filteredStatus = ownFilteredStatus
            } else {
                filteredStatus = ProductStatus.all
            }
        }
        .cornerRadius(5.0)
        .animation(.default, value: filteredStatus)
    }
}

//#Preview {
//    StockFilterItemView(filteredStatus: Binding.constant(.all), ownFilteredStatus: .all, normalColor: Color.grocyBlue, lightColor: Color.grocyBlueLight, darkColor: Color.grocyBlueDark)
//}
