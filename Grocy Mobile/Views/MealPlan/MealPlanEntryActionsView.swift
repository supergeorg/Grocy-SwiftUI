//
//  MealPlanEntryActionsView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 18.11.26.
//

import SwiftUI

/// What can be done with a meal plan entry, as in the Grocy web app.
enum MealPlanEntryAction {
    case edit
    case toggleDone
    /// Recipes: consume the ingredients in stock. Products: consume the planned amount.
    case consume
    /// Recipes: put the missing ingredients on the shopping list. Products: put the planned amount on it.
    case addToShoppingList
    case delete
}

/// The actions of a meal plan entry, for its context menu.
struct MealPlanEntryActionsView: View {
    let entry: MealPlanEntry
    let lookup: MealPlanLookup
    let showsShoppingList: Bool
    let perform: (MealPlanEntryAction) -> Void

    var body: some View {
        Button {
            perform(.toggleDone)
        } label: {
            if entry.done {
                Label("Mark as not done", systemImage: MySymbols.undone)
            } else {
                Label("Mark as done", systemImage: MySymbols.done)
            }
        }

        switch entry.type {
        case .recipe:
            Section {
                Button {
                    perform(.consume)
                } label: {
                    Label("Consume all ingredients needed by this recipe", systemImage: MySymbols.consume)
                }
                .disabled(lookup.shadowRecipeID(of: entry) == nil || !lookup.showsStock)
                if showsShoppingList {
                    Button {
                        perform(.addToShoppingList)
                    } label: {
                        Label("Put missing products on shopping list", systemImage: MySymbols.addToShoppingList)
                    }
                    .disabled(lookup.shadowRecipeID(of: entry) == nil || lookup.fulfillment(of: entry)?.needFulfilled == true)
                }
            }
        case .product:
            Section {
                Button {
                    perform(.consume)
                } label: {
                    Label("Consume", systemImage: MySymbols.consume)
                }
                .disabled(!lookup.isInStock(entry))
                if showsShoppingList {
                    Button {
                        perform(.addToShoppingList)
                    } label: {
                        Label("Add to shopping list", systemImage: MySymbols.addToShoppingList)
                    }
                }
            }
        case .note:
            EmptyView()
        }

        Section {
            Button {
                perform(.edit)
            } label: {
                Label("Edit this item", systemImage: MySymbols.edit)
            }
            Button(role: .destructive) {
                perform(.delete)
            } label: {
                Label("Delete this item", systemImage: MySymbols.delete)
            }
        }
    }
}
