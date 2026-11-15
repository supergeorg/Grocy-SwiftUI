//
//  RecipeImportView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 25.04.26.
//

import ImageIO
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

enum RecipeImportInteraction: Hashable {
    case editIngredient(id: UUID)
}

/// Imports a recipe from a website (schema.org/Recipe JSON-LD) as a Grocy recipe,
/// with the ingredients linked to products and the preparation saved as numbered steps.
struct RecipeImportView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \MDProduct.name, order: .forward) var mdProducts: MDProducts
    @Query(sort: \MDQuantityUnit.id, order: .forward) var mdQuantityUnits: MDQuantityUnits
    @Query var mdQuantityUnitConversions: MDQuantityUnitConversions
    @Query var recipes: Recipes

    @State private var urlText: String
    @State private var isLoading: Bool = false
    @State private var loadErrorMessage: String? = nil
    @State private var draft: RecipeImportDraft? = nil

    @State private var isNameCorrect: Bool = false
    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil
    /// Set once the recipe exists on the server, so a failed ingredient doesn't lead to a second recipe.
    @State private var createdRecipeID: Int? = nil

    @FocusState private var isURLFieldFocused: Bool

    init(url: String = "") {
        _urlText = State(initialValue: url)
    }

    private let dataToUpdate: [ObjectEntities] = [.products, .quantity_units, .quantity_unit_conversions, .recipes, .recipes_pos]
    private func updateData() async {
        await grocyVM.requestData(objects: dataToUpdate)
    }

    private var mapper: RecipeImportMapper {
        RecipeImportMapper(products: mdProducts, quantityUnits: mdQuantityUnits, conversions: mdQuantityUnitConversions)
    }

    private func checkNameCorrect() -> Bool {
        guard let name = draft?.name, !name.isEmpty else { return false }
        return !recipes.contains(where: { $0.name == name })
    }

    private func finishForm() {
        dismiss()
    }

    // MARK: - Loading

    private var websiteURL: URL? {
        var text = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty, !text.contains("://") {
            text = "https://" + text
        }
        guard let url = URL(string: text), url.scheme == "https" || url.scheme == "http", url.host() != nil else { return nil }
        return url
    }

    private func loadRecipe() async {
        guard let url = websiteURL else {
            loadErrorMessage = String(localized: "Enter a website address that starts with http:// or https://.")
            return
        }
        isURLFieldFocused = false
        isLoading = true
        loadErrorMessage = nil
        draft = nil
        createdRecipeID = nil
        isSuccessful = nil
        do {
            // Products and units are needed to map the ingredients
            await updateData()
            let parsedRecipes = try await RecipeParser.fetch(from: url)
            guard let parsedRecipe = parsedRecipes.first else { throw RecipeParserError.noRecipeFound }
            var newDraft = mapper.draft(from: parsedRecipe)
            if newDraft.sourceURL == nil {
                newDraft.sourceURL = url
                newDraft.preparationHTML = RecipePreparationFormat.html(introduction: parsedRecipe.schemaDescription, steps: newDraft.steps, sourceURL: url)
            }
            draft = newDraft
            isNameCorrect = checkNameCorrect()
            GrocyLogger.info("Loading recipe from \(url.host() ?? "website") was successful.")
        } catch RecipeParserError.noRecipeFound {
            GrocyLogger.warning("No recipe found on \(url.absoluteString).")
            loadErrorMessage = String(localized: "No recipe was found on this website. Only websites that provide schema.org recipe data are supported.")
        } catch {
            GrocyLogger.error("Loading recipe from \(url.absoluteString) failed. \(error)")
            loadErrorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Saving

    private func saveRecipe() async {
        guard let draft else { return }
        isProcessing = true
        isSuccessful = nil
        errorMessage = nil

        do {
            let recipeID: Int
            if let createdRecipeID {
                recipeID = createdRecipeID
            } else {
                var pictureFileName: String? = nil
                if draft.importPicture, let imageURL = draft.imageURL {
                    pictureFileName = await uploadPicture(from: imageURL, recipeName: draft.name)
                }
                let recipe = Recipe(
                    id: try grocyVM.findNextID(.recipes),
                    name: draft.name,
                    recipeDescription: draft.preparationHTML,
                    pictureFileName: pictureFileName,
                    baseServings: draft.baseServings,
                    desiredServings: draft.baseServings
                )
                let creation = try await grocyVM.postMDObject(object: .recipes, content: recipe)
                recipeID = creation.createdObjectID
                createdRecipeID = recipeID
                GrocyLogger.info("Importing recipe \(draft.name) was successful.")
            }

            var failedIngredients: [ImportedIngredient] = []
            var usedIDs = Set(grocyVM.recipesPos.map(\.id))
            for ingredient in draft.ingredientsToSave {
                guard let recipePos = recipePos(for: ingredient, recipeID: recipeID, usedIDs: &usedIDs) else { continue }
                do {
                    _ = try await grocyVM.postMDObject(object: .recipes_pos, content: recipePos)
                    GrocyLogger.info("Adding ingredient \(ingredient.line.originalText) was successful.")
                    // Saved ingredients are not posted again when the person tries again
                    self.draft?.markSaved(ingredient)
                } catch {
                    GrocyLogger.error("Adding ingredient \(ingredient.line.originalText) failed. \(error)")
                    failedIngredients.append(ingredient)
                }
            }

            await grocyVM.requestData(objects: [.recipes, .recipes_pos])

            if failedIngredients.isEmpty {
                isSuccessful = true
            } else {
                isSuccessful = false
                let names = failedIngredients.map(\.line.originalText).joined(separator: ", ")
                errorMessage = String(localized: "The recipe was saved, but these ingredients couldn't be added: \(names)")
            }
        } catch {
            GrocyLogger.error("Importing recipe \(draft.name) failed. \(error)")
            isSuccessful = false
            if let apiError = error as? APIError {
                errorMessage = apiError.displayMessage
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isProcessing = false
    }

    /// The Grocy ingredient for an imported one. Grocy stores the amount in the product's stock unit
    /// and the chosen unit only for displaying it, so the amount is converted here.
    private func recipePos(for ingredient: ImportedIngredient, recipeID: Int, usedIDs: inout Set<Int>) -> RecipePos? {
        guard let productID = ingredient.productID, let product = mdProducts.first(where: { $0.id == productID }) else { return nil }
        let quID = ingredient.quID ?? product.quIDConsume
        let stockAmount = mapper.stockAmount(for: ingredient.amount, quID: quID, product: product)

        var id = 1
        while usedIDs.contains(id) { id += 1 }
        usedIDs.insert(id)

        return RecipePos(
            id: id,
            recipeID: recipeID,
            productID: productID,
            // With "only check if any amount is in stock", Grocy keeps the amount as entered
            amount: ingredient.onlyCheckSingleUnitInStock ? ingredient.amount : (stockAmount ?? ingredient.amount),
            note: ingredient.note,
            quID: quID,
            // Without a conversion, Grocy can only check whether any amount is in stock
            onlyCheckSingleUnitInStock: ingredient.onlyCheckSingleUnitInStock || stockAmount == nil,
            ingredientGroup: ingredient.ingredientGroup,
            variableAmount: ingredient.variableAmount
        )
    }

    /// Downloads the recipe's picture and uploads it to Grocy. Returns the file name, or `nil` when it failed.
    /// The recipe is still imported without a picture then.
    private func uploadPicture(from url: URL, recipeName: String) async -> String? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let jpegData = Self.jpegData(from: data) else {
                GrocyLogger.warning("The recipe picture from \(url.absoluteString) couldn't be converted.")
                return nil
            }
            let fileName = "\(UUID())_\(recipeName.cleanedFileName).jpg"
            guard let fileNameData = fileName.data(using: .utf8) else { return nil }
            try await grocyVM.uploadFileData(fileData: jpegData, groupName: PictureType.recipePictures.rawValue, fileName: fileNameData.base64EncodedString())
            GrocyLogger.info("Uploading recipe picture was successful.")
            return fileName
        } catch {
            GrocyLogger.warning("Uploading recipe picture failed. \(error)")
            return nil
        }
    }

    /// Converts a picture in any format (e.g. WebP) to a JPEG of at most 2000 pixels.
    nonisolated private static func jpegData(from data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 2000,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }

    // MARK: - Body

    var body: some View {
        Form {
            if isSuccessful == false, let errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }

            urlSection

            if isLoading {
                Section {
                    ProgressView("Loading recipe…")
                        .frame(maxWidth: .infinity)
                }
            } else if let draftBinding = Binding($draft) {
                recipeSections(draft: draftBinding)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Import recipe")
        .navigationDestination(for: RecipeImportInteraction.self) { interaction in
            switch interaction {
            case .editIngredient(let id):
                if let draftBinding = Binding($draft), let index = draftBinding.wrappedValue.ingredients.firstIndex(where: { $0.id == id }) {
                    RecipeImportIngredientFormView(ingredient: draftBinding.ingredients[index])
                }
            }
        }
        .task {
            await updateData()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel, action: finishForm)
                    .keyboardShortcut(.cancelAction)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(
                    role: .confirm,
                    action: {
                        Task {
                            await saveRecipe()
                        }
                    },
                    label: {
                        if !isProcessing {
                            Label("Save", systemImage: MySymbols.save)
                        } else {
                            ProgressView().progressViewStyle(.circular)
                        }
                    }
                )
                .disabled(draft == nil || !(isNameCorrect || createdRecipeID != nil) || (draft?.baseServings ?? 0) <= 0 || isProcessing || isLoading)
                .keyboardShortcut(.defaultAction)
            }
        }
        .onChange(of: isSuccessful) {
            if isSuccessful == true {
                finishForm()
            }
        }
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }

    // MARK: - Sections

    private var urlSection: some View {
        Section {
            TextField(
                text: $urlText,
                prompt: Text(verbatim: "https://example.com/recipe"),
                label: {
                    Label("Website", systemImage: MySymbols.link)
                }
            )
            .focused($isURLFieldFocused)
            .autocorrectionDisabled()
            #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .textContentType(.URL)
            #endif
            .submitLabel(.go)
            .onSubmit {
                Task { await loadRecipe() }
            }

            Button(
                action: {
                    Task { await loadRecipe() }
                },
                label: {
                    Label("Load recipe", systemImage: MySymbols.importRecipe)
                }
            )
            .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading || isProcessing)
        } footer: {
            if let loadErrorMessage {
                Label {
                    Text(loadErrorMessage)
                } icon: {
                    Image(systemName: MySymbols.warning)
                        .foregroundStyle(Color(.GrocyColors.grocyRed))
                }
            } else if draft == nil {
                Text("The recipe is read from the website's schema.org data, which most recipe websites provide.")
            }
        }
    }

    @ViewBuilder
    private func recipeSections(draft: Binding<RecipeImportDraft>) -> some View {
        Section {
            MyTextField(
                textToEdit: draft.name,
                description: "Name",
                prompt: "Required",
                isCorrect: $isNameCorrect,
                leadingIcon: MySymbols.name,
                emptyMessage: "A name is required",
                errorMessage: "Name already exists"
            )
            .onChange(of: draft.wrappedValue.name) {
                isNameCorrect = checkNameCorrect()
            }
            .disabled(createdRecipeID != nil)

            MyDoubleStepper(
                amount: draft.baseServings,
                description: "Servings",
                descriptionInfo: "The ingredients listed here result in this amount of servings",
                minAmount: 0.0000001,
                systemImage: MySymbols.amount
            )
            .disabled(createdRecipeID != nil)
        }

        if let imageURL = draft.wrappedValue.imageURL {
            Section {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(.rect(cornerRadius: 8.0))
                    case .failure:
                        Image(systemName: MySymbols.picturePlaceholder)
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    default:
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 240.0)
                .accessibilityHidden(true)

                MyToggle(isOn: draft.importPicture, description: "Import picture", icon: MySymbols.picture)
                    .disabled(createdRecipeID != nil)
            }
        }

        Section {
            ForEach(draft.wrappedValue.ingredients) { ingredient in
                NavigationLink(value: RecipeImportInteraction.editIngredient(id: ingredient.id)) {
                    RecipeImportIngredientRowView(
                        ingredient: ingredient,
                        product: mdProducts.first(where: { $0.id == ingredient.productID }),
                        quantityUnit: mdQuantityUnits.first(where: { $0.id == ingredient.quID })
                    )
                }
                .disabled(draft.wrappedValue.savedIngredientIDs.contains(ingredient.id))
            }
        } header: {
            Text("Ingredients list")
        } footer: {
            let missingCount = draft.wrappedValue.ingredientsWithoutProduct.count
            if missingCount > 0 {
                Text("\(missingCount) ingredients have no product and won't be imported. Select an ingredient to choose or create its product.")
            }
        }

        if !draft.wrappedValue.steps.isEmpty {
            Section {
                ForEach(Array(draft.wrappedValue.steps.enumerated()), id: \.offset) { index, step in
                    RecipeImportStepRowView(number: index + 1, step: step, showsSection: index == 0 || draft.wrappedValue.steps[index - 1].section != step.section)
                }
            } header: {
                Label("Preparation", systemImage: MySymbols.steps)
            } footer: {
                Text("The preparation is saved as numbered steps.")
            }
        }
    }
}

// MARK: - Step row

private struct RecipeImportStepRowView: View {
    var number: Int
    var step: RecipePreparationStep
    var showsSection: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            if showsSection, let section = step.section {
                Text(section)
                    .font(.headline)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8.0) {
                Text(number, format: .number)
                    .font(.body.monospacedDigit().bold())
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2.0) {
                    if let title = step.title {
                        Text(title)
                            .font(.subheadline.bold())
                    }
                    Text(step.text)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Saved ingredients

extension RecipeImportDraft {
    /// IDs of ingredients already saved to the server.
    var savedIngredientIDs: Set<UUID> {
        Set(ingredients.filter(\.isSaved).map(\.id))
    }

    mutating func markSaved(_ ingredient: ImportedIngredient) {
        guard let index = ingredients.firstIndex(where: { $0.id == ingredient.id }) else { return }
        ingredients[index].isSaved = true
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        RecipeImportView(url: "https://www.chefkoch.de/rezepte/3349111497722186/Weisser-Spargel-mit-Butter-und-Parmesan.html")
    }
}
