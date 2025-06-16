//
//  StockFilterViewNew.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 12.06.25.
//

import SwiftUI

enum StockFilterViewNewItemType: Hashable {
    case Test1
    case Test2
}

struct StockFilterViewNew: View {
    @State private var activeTab: StockFilterViewNewItemType = .Test1
    var body: some View {
        HStack {
            StockFilterViewNewItem(activeTab: $activeTab, label: "Test1", icon: MySymbols.clear, itemType: .Test1)
            StockFilterViewNewItem(activeTab: $activeTab, label: "Test2", icon: MySymbols.clear, itemType: .Test2)
            
        }
    }
}

struct StockFilterViewNewItem: View {
    @Binding var activeTab: StockFilterViewNewItemType
    
    var label: String
    var icon: String
    let itemType: StockFilterViewNewItemType
    
    var body: some View {
        Button(action: { activeTab = itemType }) {
            Label(label, systemImage: icon)
//                .labelStyle(itemType == activeTab ? AnyLabelStyle(IconOnlyLabelStyle()) : AnyLabelStyle(TitleAndIconLabelStyle()))
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    StockFilterViewNew()
}
