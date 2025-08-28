//
//  ShoppingListFilterView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 28.08.25.
//

import SwiftData
import SwiftUI

struct ShoppingListFilterView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Binding var filteredStatus: ShoppingListStatus

    var body: some View {
        List {
            Picker(
                selection: $filteredStatus,
                content: {
                    Text("All")
                        .tag(ShoppingListStatus.all)
                    Text("Below min. stock amount")
                        .tag(ShoppingListStatus.belowMinStock)
                    Text("Only done items")
                        .tag(ShoppingListStatus.done)
                    Text("Only undone items")
                        .tag(ShoppingListStatus.undone)
                },
                label: {
                    Label("Status", systemImage: MySymbols.filter)
                        .foregroundStyle(.primary)
                }
            )
        }
    }
}

#Preview {
    @Previewable @State var filteredStatus: ShoppingListStatus = .all
    
    ShoppingListFilterView(filteredStatus: $filteredStatus )
}
