//
//  RecipeGenerationView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 09.02.26.
//

import Foundation
import FoundationModels
import SwiftUI

struct RecipeParserView: View {
    @State private var urlInput = ""
    @State private var recipe: ParsedRecipe?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            TextField("Paste recipe URL", text: $urlInput)
                #if os(iOS)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                #endif

            Button("Extract Recipe") {
                Task {
                    await extractRecipe()
                }
            }
            .disabled(isLoading || urlInput.isEmpty)

            if isLoading {
                ProgressView("Extracting recipe...")
            }

            if let recipe {
                RecipeDisplayView(recipe: recipe)
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(Color(.GrocyColors.grocyRed))
                    .font(.caption)
            }
        }
    }

    func extractRecipe() async {
        isLoading = true
        errorMessage = nil
        recipe = nil
        do {
            // Fetch raw HTML first to extract image URL
            guard let url = URL(string: urlInput) else {
                throw URLError(.badURL)
            }
            let (rawData, _) = try await URLSession.shared.data(from: url)
            let rawHTML = String(data: rawData, encoding: .utf8) ?? ""

            // Extract image URL directly from raw HTML
            let imageURL = rawHTML.extractImageURL()

            // Fetch and clean website HTML (for token efficiency)
            let cleanedContent = try await fetchAndCleanWebsite(from: urlInput)

            // Parse with Foundation Models
            let session = LanguageModelSession()
            let prompt = """
                Extract the recipe information from the following webpage text.
                Return the recipe name, a structural list of all ingredients with their amounts, units, and names, and the full cooking instructions/description in HTML format.

                For ingredients:
                - Parse the amount as a number (e.g., "2" from "2 cups flour")
                - Extract the unit (cups, grams, tablespoons, ml, etc.)
                - Extract the ingredient name

                \(cleanedContent)
                """

            let response = try await session.respond(to: prompt, generating: ParsedRecipe.self)
            await MainActor.run {
                var recipeResult = response.content
                // Add the extracted image URL to the recipe
                if !imageURL.isEmpty {
                    recipeResult.imageURL = imageURL
                }
                self.recipe = recipeResult
                isLoading = false
                print("Recipe extracted: \(recipe?.name ?? "Unknown")")
            }

        } catch {
            await MainActor.run {
                errorMessage = "Failed to extract recipe: \(error.localizedDescription)"
                isLoading = false
                print("Recipe extraction error: \(error)")
            }
        }
    }
}

struct RecipeDisplayView: View {
    let recipe: ParsedRecipe
    /// Converted once and off the body: the synchronous HTML import blocks the main thread on every redraw.
    @State private var preparation: AttributedString?

    var body: some View {
        Section {
            Text(recipe.name)
                .font(.title)
                .bold()

            if !recipe.imageURL.isEmpty, let imageUrl = URL(string: recipe.imageURL) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: Sizes.parserTextHeight)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: Sizes.parserResultMaxHeight)
                            .clipped()
                            .cornerRadius(12)
                    case .failure:
                        Image(systemName: MySymbols.picture)
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                            .frame(height: Sizes.parserTextHeight)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }

        Section("Ingredients") {
            ForEach(recipe.ingredients.indices, id: \.self) { index in
                let ingredient = recipe.ingredients[index]
                HStack(alignment: .top, spacing: Spacing.small) {
                    Text("•")

                    if ingredient.amount > 0 {
                        Text("\(ingredient.amount.formattedAmount)")
                            .fontWeight(.semibold)

                        if !ingredient.unit.isEmpty {
                            Text(ingredient.unit)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(ingredient.name)

                    Spacer()
                }
            }
        }

        Section("Preparation") {
            if let preparation {
                Text(preparation)
                    .font(.body)
            } else {
                ProgressView()
            }
        }
        .task(id: recipe.descriptionHTML) {
            preparation = await recipe.descriptionHTML.htmlToAttributedStringAsync()
        }
    }
}

#Preview {
    NavigationStack {
        RecipeParserView()
    }
}
