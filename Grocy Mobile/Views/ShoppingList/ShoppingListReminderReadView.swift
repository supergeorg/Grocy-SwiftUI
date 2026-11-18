import SwiftData
//
//  ShoppingListReminderReadView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 08.12.25.
//
import SwiftUI

struct ShoppingListReminderReadView: View {
    var reminders: [Reminder]

    @Environment(GrocyViewModel.self) private var grocyVM

    @Query var mdProducts: MDProducts
    @Query var shoppingList: [ShoppingListItem]

    func updateShoppingListFromReminders(shoppingListID: Int, reminders: [Reminder]) async {
        for reminder in reminders {
            var nameComponents = reminder.title.components(separatedBy: " ")
            let amount = Double(nameComponents.removeFirst())
            let name = nameComponents.joined(separator: " ")
            if let product = self.mdProducts.first(where: { $0.name == name }),
                let entry = self.shoppingList.first(where: { $0.productID == product.id })
            {
                let shoppingListEntryNew = ShoppingListItem(
                    id: entry.id,
                    productID: entry.productID ?? -1,
                    note: reminder.notes ?? "",
                    amount: amount ?? entry.amount,
                    shoppingListID: shoppingListID,
                    done: reminder.isComplete,
                    quID: entry.quID ?? -1,
                    rowCreatedTimestamp: entry.rowCreatedTimestamp
                )
                if shoppingListEntryNew.note != entry.note, shoppingListEntryNew.amount != entry.amount, shoppingListEntryNew.done != entry.done {
                    do {
                        try await grocyVM.putMDObjectWithID(
                            object: .shopping_list,
                            id: entry.id,
                            content: shoppingListEntryNew
                        )
                        GrocyLogger.info("Shopping entry edited successfully.")
                    } catch {
                        GrocyLogger.error("Shopping entry edit failed. \(error)")
                    }
                }
            } else {
                GrocyLogger.info("Found no matching product for the shopping list entry \(name).")
            }
        }
    }

    var body: some View {
        Form {
            ForEach(reminders, id: \.id) { reminder in
                Text(reminder.title)
            }
        }
    }
}
