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
    @Environment(\.colorScheme) var colorScheme

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
            #if os(iOS)
                .listRowBackground(
                    Group {
                        switch filteredStatus {
                        case .all:
                            colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
                        case .done:
                            Color(.GrocyColors.grocyGreen)
                        case .undone:
                            Color(.GrocyColors.grocyGrayBackground)
                        case .belowMinStock:
                            Color(.GrocyColors.grocyBlueBackground)
                        }
                    }
                )
            #endif
        }
    }
}

#Preview {
    @Previewable @State var filteredStatus: ShoppingListStatus = .all

    ShoppingListFilterView(filteredStatus: $filteredStatus)
}
