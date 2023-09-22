//
//  RecipeRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 02.12.22.
//

import SwiftUI

struct RecipeRowView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    var recipe: Recipe
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading){
                Text(recipe.name)
                    .font(.title)
            }
            Spacer()
            Text(String(recipe.dueScore))
                .font(.title)
        }
    }
}

//struct RecipeRowView_Previews: PreviewProvider {
//    static var previews: some View {
//        RecipeRowView()
//    }
//}
