//
//  MiseEnPlaceStore.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 28.11.26.
//

import SwiftUI

/// The ingredients ticked off per recipe, by `RecipePosResolvedElement.miseEnPlaceID`. Shared by the recipe screen's
/// ingredient checkboxes and the cooking mode, which on the Mac is a window of its own. Like in Grocy, it isn't saved.
@Observable
final class MiseEnPlaceStore {
    static let shared = MiseEnPlaceStore()

    private var readyIngredients: [Int: Set<String>] = [:]

    subscript(recipeID: Int) -> Set<String> {
        get { readyIngredients[recipeID] ?? [] }
        set { readyIngredients[recipeID] = newValue }
    }

    func binding(for recipeID: Int) -> Binding<Set<String>> {
        Binding {
            self[recipeID]
        } set: { newValue in
            self[recipeID] = newValue
        }
    }
}
