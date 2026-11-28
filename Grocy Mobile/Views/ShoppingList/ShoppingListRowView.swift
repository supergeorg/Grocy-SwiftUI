//
//  ShoppingListRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 13.09.25.
//

import SwiftData
import SwiftUI

struct ShoppingListRowView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(ShoppingListInteractionNavigationRouter.self) private var shoppingListInteractionRouter

    var shoppingListItem: ShoppingListItem
    var isBelowStock: Bool
    var product: MDProduct? = nil
    var quantityUnit: MDQuantityUnit? = nil
    var userSettings: GrocyUserSettings? = nil
    var conversions: MDQuantityUnitConversions = []

    // Callbacks for interactions
    var onToggleDone: (ShoppingListItem) async -> Void = { _ in }
    var onDelete: (ShoppingListItem) -> Void = { _ in }

    var amountString: String {
        // Grocy stores the amount in the stock unit, so it's converted to the item's unit (#114).
        let amount = shoppingListItem.displayAmount(roundUp: userSettings?.shoppingListRoundUp ?? false, product: product, conversions: conversions)
        if let quantityUnit = quantityUnit {
            return "\(amount.formattedAmount) \(quantityUnit.getName(amount: amount))"
        } else {
            return "\(amount.formattedAmount)"
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(product?.name ?? shoppingListItem.note)
                .font(.headline)
                .strikethrough(shoppingListItem.done)
            if !shoppingListItem.note.isEmpty && product != nil {
                Text(shoppingListItem.note)
                    .font(.caption)
            }
            Text("\(Text("Amount")): \(amountString)")
                .strikethrough(shoppingListItem.done)
        }
        .foregroundStyle(shoppingListItem.done ? .secondary : .primary)
        // Done is announced, not only shown by the strikethrough and the dimmed color.
        .accessibilityElement(children: .combine)
        .accessibilityValue(shoppingListItem.done ? Text("Done") : Text(""))
        .contextMenu(menuItems: {
            Button(
                action: {
                    Task {
                        if !shoppingListItem.done && userSettings?.shoppingListToStockWorkflowAutoSubmitWhenPrefilled ?? false {
                            shoppingListInteractionRouter.present(.autoPurchase(item: shoppingListItem))
                        }
                        await onToggleDone(shoppingListItem)
                    }
                },
                label: {
                    if !shoppingListItem.done {
                        Label("Mark this item as done", systemImage: MySymbols.done)
                    } else {
                        Label("Mark this item as undone", systemImage: MySymbols.undone)
                    }
                }
            )
            if shoppingListItem.productID != nil {
                Button(
                    action: {
                        shoppingListInteractionRouter.present(.purchase(item: shoppingListItem))
                    },
                    label: {
                        Label("Add this item to stock", systemImage: MySymbols.purchase)
                    }
                )
            }
            Divider()
            Button(
                role: .destructive,
                action: {
                    onDelete(shoppingListItem)
                },
                label: {
                    Label("Delete this item", systemImage: MySymbols.delete)
                }
            )
        })
        .swipeActions(
            edge: .trailing,
            allowsFullSwipe: true,
            content: {
                Button(
                    role: .destructive,
                    action: { onDelete(shoppingListItem) },
                    label: { Label("Delete", systemImage: MySymbols.delete) }
                )
            }
        )
        .swipeActions(
            edge: .leading,
            allowsFullSwipe: !shoppingListItem.done,
            content: {
                Group {
                    Button(
                        action: {
                            Task {
                                if !shoppingListItem.done && userSettings?.shoppingListToStockWorkflowAutoSubmitWhenPrefilled ?? false {
                                    shoppingListInteractionRouter.present(.autoPurchase(item: shoppingListItem))
                                }
                                await onToggleDone(shoppingListItem)
                            }
                        },
                        label: { Label("Done", systemImage: MySymbols.done) }
                    )
                    .tint(.green)
                    // A swipe action is a VoiceOver action, which reads only its name: the short visible title gets a full one.
                    .accessibilityLabel(!shoppingListItem.done ? "Mark this item as done" : "Mark this item as undone")
                    if shoppingListItem.productID != nil {
                        Button(
                            action: {
                                shoppingListInteractionRouter.present(.purchase(item: shoppingListItem))
                            },
                            label: { Label("Purchase", systemImage: MySymbols.purchase) }
                        )
                        .tint(.blue)
                    }
                }
            }
        )
    }
}

#Preview {
    List {
        ShoppingListRowView(
            shoppingListItem: ShoppingListItem(id: 1, productID: 1, note: "note", amount: 2, shoppingListID: 1, done: true, quID: 1),
            isBelowStock: false
        )
        ShoppingListRowView(
            shoppingListItem: ShoppingListItem(id: 2, productID: 1, note: "note", amount: 2, shoppingListID: 1, done: false, quID: 1),
            isBelowStock: true
        )
    }
}
