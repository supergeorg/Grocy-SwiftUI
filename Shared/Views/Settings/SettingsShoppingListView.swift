//
//  SettingsShoppingListView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 29.04.22.
//

import SwiftUI

struct SettingsShoppingListView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var useQuickConsume: Bool = false
    
    @State private var isFirst: Bool = true
    
    @AppStorage("devMode") private var devMode: Bool = false
    
    private let dataToUpdate: [ObjectEntities] = [.shopping_lists]
    
    var body: some View {
#if os(macOS)
        ScrollView {
            content
                .padding()
        }
#else
        content
#endif
    }
    
    var content: some View {
        Form {
            Section(header: Text(LocalizedStringKey("str.settings.shoppingList.shoppingList")).font(.title)) {
                ServerSettingsToggle(settingKey: GrocyUserSettings.CodingKeys.shoppingListAutoAddBelowMinStockAmount.rawValue, description: "str.settings.shoppingList.autoAddToShL")
                ServerSettingsObjectPicker(settingKey: GrocyUserSettings.CodingKeys.shoppingListAutoAddBelowMinStockAmountListID.rawValue, description: "str.shL", objects: .shoppingLists)
            }
            Section(header: Text(LocalizedStringKey("str.settings.shoppingList.shLToStockWF")).font(.title)) {
                ServerSettingsToggle(settingKey: GrocyUserSettings.CodingKeys.shoppingListToStockWorkflowAutoSubmitWhenPrefilled.rawValue, description: "str.settings.shoppingList.autoAddToStock")
            }
        }
        .navigationTitle(LocalizedStringKey("str.settings.shoppingList"))
        .onAppear(perform: {
            if isFirst {
                grocyVM.requestData(objects: dataToUpdate)
                isFirst = false
            }
        })
        .onDisappear(perform: {
            grocyVM.requestData(additionalObjects: [.user_settings])
        })
    }
}

struct SettingsShoppingListView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsShoppingListView()
    }
}
