//
//  RecipeImportTests.swift
//  Grocy MobileTests
//
//  Created by Georg Meißner on 14.11.26.
//

import Foundation
import Testing

@testable import Grocy_Mobile

@Suite("Ingredient line parser")
struct IngredientLineParserTests {
    @Test(
        "Amount, unit, name and note",
        arguments: [
            ("200 g Butter, weich", 200.0, "g", "Butter", "weich"),
            ("200g Mehl", 200.0, "g", "Mehl", ""),
            ("1,5 kg Kartoffeln (festkochend)", 1.5, "kg", "Kartoffeln", "festkochend"),
            ("2 EL Olivenöl", 2.0, "EL", "Olivenöl", ""),
            ("1 Pck. Vanillezucker", 1.0, "Pck", "Vanillezucker", ""),
            ("1 Zehe/n Knoblauch", 1.0, "Zehe/n", "Knoblauch", ""),
            ("1/2 tsp salt", 0.5, "tsp", "salt", ""),
            ("1 1/2 cups flour", 1.5, "cups", "flour", ""),
            ("½ Bund Petersilie", 0.5, "Bund", "Petersilie", ""),
            ("1½ l Milch", 1.5, "l", "Milch", ""),
            ("1 fl oz cream", 1.0, "fl oz", "cream", ""),
        ]
    )
    func parsesLine(text: String, amount: Double, unit: String, name: String, note: String) {
        let line = IngredientLineParser.parse(text)
        #expect(line.amount == amount)
        #expect(line.unit == unit)
        #expect(line.name == name)
        #expect(line.note == note)
        #expect(line.knownUnit != nil)
    }

    @Test("Commas inside parentheses belong to the note")
    func commaInParentheses() {
        let line = IngredientLineParser.parse("30 g Speck (durchwachsener, klein geschnittener)")
        #expect(line.name == "Speck")
        #expect(line.note == "durchwachsener, klein geschnittener")
    }

    @Test("Lines without a unit")
    func noUnit() {
        let line = IngredientLineParser.parse("3 Eier")
        #expect(line.amount == 3)
        #expect(line.unit == nil)
        #expect(line.name == "Eier")

        let tomato = IngredientLineParser.parse("1 Tomate")
        #expect(tomato.unit == nil)
        #expect(tomato.name == "Tomate")
    }

    @Test("Lines without an amount")
    func noAmount() {
        let line = IngredientLineParser.parse("Salz und Pfeffer")
        #expect(line.amount == nil)
        #expect(line.name == "Salz und Pfeffer")
    }

    @Test("Vague quantities become the note")
    func vagueQuantity() {
        let asNeeded = IngredientLineParser.parse("n. B. Butterflöckchen")
        #expect(asNeeded.amount == nil)
        #expect(asNeeded.unit == nil)
        #expect(asNeeded.name == "Butterflöckchen")
        #expect(asNeeded.note == "n. B.")

        let some = IngredientLineParser.parse("etwas Salz und Pfeffer (frisch gemahlen)")
        #expect(some.name == "Salz und Pfeffer")
        #expect(some.note == "etwas, frisch gemahlen")
    }

    @Test("Lines with several ingredients are split")
    func split() throws {
        let vague = try #require(IngredientLineParser.split(IngredientLineParser.parse("n. B. Salz und Pfeffer, frisch gemahlen"), language: "de"))
        #expect(vague.map(\.name) == ["Salz", "Pfeffer"])
        #expect(vague.map(\.originalText) == ["n. B. Salz", "n. B. Pfeffer"])
        #expect(vague.allSatisfy { $0.amount == nil && $0.vagueAmount == "n. B." && $0.note == "n. B., frisch gemahlen" })

        let shared = try #require(IngredientLineParser.split(IngredientLineParser.parse("2 EL Öl und Essig"), language: "de"))
        #expect(shared.map(\.name) == ["Öl", "Essig"])
        #expect(shared.map(\.originalText) == ["2 EL Öl", "2 EL Essig"])
        #expect(shared.allSatisfy { $0.amount == 2 && $0.unit == "EL" })

        let own = try #require(IngredientLineParser.split(IngredientLineParser.parse("1 Zwiebel & 2 Knoblauchzehen"), language: "de"))
        #expect(own.map(\.name) == ["Zwiebel", "Knoblauch"])
        #expect(own.map(\.amount) == [1, 2])

        #expect(IngredientLineParser.split(IngredientLineParser.parse("200 g Butter"), language: "de") == nil)
        #expect(IngredientLineParser.split(IngredientLineParser.parse("Butter oder Margarine"), language: "de") == nil)
    }

    @Test(
        "Lines are split with the word for \"and\" of the recipe's language",
        arguments: [
            ("Salt and pepper", "en"), ("Sel et poivre", "fr"), ("Sal y pimienta", "es"), ("Sale e pepe", "it"),
            ("Zout en peper", "nl"), ("Salt och peppar", "sv"), ("Tuz ve biber", "tr"), ("Sól i pieprz", "pl"),
        ]
    )
    func splitInLanguage(text: String, language: String) throws {
        let parts = try #require(IngredientLineParser.split(IngredientLineParser.parse(text), language: language))
        #expect(parts.count == 2)
    }

    @Test("Without a known language, only unambiguous words split")
    func splitWithoutLanguage() {
        #expect(IngredientLineParser.split(IngredientLineParser.parse("Salz und Pfeffer"), language: nil)?.count == 2)
        #expect(IngredientLineParser.split(IngredientLineParser.parse("Salz & Pfeffer"), language: nil)?.count == 2)
        // "e" is "and" in Italian, but a letter elsewhere
        #expect(IngredientLineParser.split(IngredientLineParser.parse("Vitamin e Tabletten"), language: nil) == nil)
    }

    @Test("The language of the ingredients is recognized")
    func language() {
        let lines = ["300 g Hähnchenbrustfilet", "1 EL Pflanzenöl", "1 Paprikaschote, rote", "n. B. Salz und Pfeffer"].map { IngredientLineParser.parse($0) }
        #expect(IngredientLineParser.language(of: lines) == "de")
    }

    @Test("Unit words in compound words become the unit")
    func compoundUnit() {
        let paprika = IngredientLineParser.parse("1 Paprikaschote(n), rote")
        #expect(paprika.name == "Paprika")
        #expect(paprika.knownUnit == .piece)
        #expect(paprika.note == "rote")

        let garlic = IngredientLineParser.parse("2 Knoblauchzehen")
        #expect(garlic.name == "Knoblauch")
        #expect(garlic.knownUnit == .clove)

        // A unit given before the name stays, and short stems aren't split off
        #expect(IngredientLineParser.parse("1 Stück Vanilleschote").name == "Vanilleschote")
        #expect(IngredientLineParser.parse("2 Zehen").knownUnit == .clove)
    }

    @Test("Ranges keep their text")
    func range() {
        let line = IngredientLineParser.parse("2-3 EL Zucker")
        #expect(line.amount == 3)
        #expect(line.amountText == "2-3")
        #expect(line.unit == "EL")
        #expect(line.name == "Zucker")
    }

    @Test("Plural markers in parentheses are no note")
    func pluralMarker() {
        let line = IngredientLineParser.parse("2 Zwiebel(n), fein gewürfelt")
        #expect(line.name == "Zwiebel")
        #expect(line.note == "fein gewürfelt")
    }

    @Test("Structured ingredients")
    func structured() {
        let line = IngredientLineParser.parse(Ingredient.structured(value: "250", name: "Quark", unitCode: "GRM"))
        #expect(line.amount == 250)
        #expect(line.knownUnit == .gram)
        #expect(line.name == "Quark")
    }

    @Test("HTML entities are decoded")
    func entities() {
        let line = IngredientLineParser.parse("100 g Cr&egrave;me fra&icirc;che &amp; Sahne")
        #expect(line.name.contains("& Sahne"))
    }
}

@Suite("Recipe picture")
@MainActor
struct RecipePictureParsingTests {
    private func page(jsonLD: String, head: String = "") -> String {
        "<html><head>\(head)<script type=\"application/ld+json\">\(jsonLD)</script></head><body></body></html>"
    }

    @Test("A picture referenced by @id in the @graph is resolved")
    func imageReference() throws {
        let json = """
            {"@context": "https://schema.org", "@graph": [
              {"@type": "Recipe", "name": "Nudeln", "image": {"@id": "https://example.com/r#primaryimage"}},
              {"@type": "ImageObject", "@id": "https://example.com/r#primaryimage", "url": "https://example.com/nudeln.jpg"}
            ]}
            """
        let recipe = try #require(try RecipeParser.parse(html: page(jsonLD: json)).first)
        #expect(recipe.image == URL(string: "https://example.com/nudeln.jpg"))
    }

    @Test("The page's og:image is used when the recipe has no picture")
    func openGraphFallback() throws {
        let json = #"{"@type": "Recipe", "name": "Nudeln"}"#
        let head = #"<meta content="https://example.com/og.jpg?a=1&amp;b=2" property="og:image">"#
        let recipe = try #require(try RecipeParser.parse(html: page(jsonLD: json, head: head)).first)
        #expect(recipe.image == URL(string: "https://example.com/og.jpg?a=1&b=2"))
    }

    @Test("The recipe's own picture wins over og:image")
    func ownPictureFirst() throws {
        let json = #"{"@type": "Recipe", "name": "Nudeln", "image": ["https://example.com/own.jpg"]}"#
        let head = #"<meta property="og:image" content="https://example.com/og.jpg">"#
        let recipe = try #require(try RecipeParser.parse(html: page(jsonLD: json, head: head)).first)
        #expect(recipe.image == URL(string: "https://example.com/own.jpg"))
    }
}

@Suite("Preparation format")
struct RecipePreparationFormatTests {
    private let steps = [
        RecipePreparationStep(section: "Teig", title: nil, text: "Mehl & Butter verkneten."),
        RecipePreparationStep(section: "Teig", title: "Ruhen", text: "30 Minuten kühlen."),
        RecipePreparationStep(section: "Füllung", title: nil, text: "Äpfel schälen.\nIn Spalten schneiden."),
    ]

    @Test("Steps survive the round trip through HTML")
    func roundTrip() {
        let html = RecipePreparationFormat.html(introduction: "Ein Klassiker.", steps: steps, sourceURL: URL(string: "https://example.com/apfelkuchen"))
        #expect(html.contains("<h3>Teig</h3>"))
        #expect(html.contains("&amp;"))
        #expect(RecipePreparationFormat.steps(fromHTML: html) == steps)
    }

    @Test("Introduction and source are no steps")
    func introductionIsNoStep() {
        let html = RecipePreparationFormat.html(
            introduction: "Intro",
            steps: [RecipePreparationStep(section: nil, title: nil, text: "Only step")],
            sourceURL: URL(string: "https://example.com")
        )
        let parsed = RecipePreparationFormat.steps(fromHTML: html)
        #expect(parsed.count == 1)
        #expect(parsed.first?.text == "Only step")
    }

    @Test("HTML without a list is split into paragraphs")
    func paragraphs() {
        let parsed = RecipePreparationFormat.steps(fromHTML: "<p>First.</p><p><b>Second</b> step.</p>")
        #expect(parsed.map(\.text) == ["First.", "Second step."])
    }

    @Test("One instruction text with line breaks becomes several steps")
    func singleTextIsSplit() {
        let instruction = InstructionStep(position: 1, sectionName: nil, name: nil, text: "Erst das.\n\nDann das.", imageURL: nil, url: nil)
        let steps = RecipePreparationFormat.steps(from: [instruction])
        #expect(steps.map(\.text) == ["Erst das.", "Dann das."])
    }
}

@Suite("Recipe description")
@MainActor
struct RecipeDescriptionTests {
    private func page(description: String, body: String) -> String {
        let jsonLD =
            #"{"@context":"https://schema.org","@type":"Recipe","name":"Gebratene Nudeln","description":"\#(description)","recipeIngredient":["200 g Nudeln"]}"#
        return """
            <html><head><meta name="description" content="\(description)"><script type="application/ld+json">\(jsonLD)</script></head>
            <body><h1>Gebratene Nudeln</h1>\(body)<script>var text = "\(description)";</script></body></html>
            """
    }

    @Test("Text only meant for search engines is left out")
    func searchEngineTextIsRemoved() throws {
        let html = page(
            description: "Gebratene Nudeln - schnell und einfach. Über 26 Bewertungen und für beliebt befunden. Mit ► Portionsrechner ► Kochbuch!",
            body: "<p>Schnell und einfach</p><ul><li>200 g Nudeln</li></ul>"
        )
        #expect(try RecipeParser.parse(html: html).first?.schemaDescription == nil)
    }

    @Test("Sentences the page shows are kept")
    func shownSentencesAreKept() throws {
        let html = page(
            description: "A great dish for busy days. Rated 4.8 by 120 cooks!",
            body: "<p>A great   dish for <em>busy</em> days.</p><p>Bake 1.5 hours.</p>"
        )
        #expect(try RecipeParser.parse(html: html).first?.schemaDescription == "A great dish for busy days.")
    }

    @Test("Pages without rendered text keep the description")
    func javaScriptPagesKeepTheDescription() {
        let pageText = RecipeParser.visibleText(in: "<html><body><div id=\"app\"></div></body></html>")
        #expect(RecipeParser.shownDescription("Only in metadata.", recipeName: "Gebratene Nudeln", pageText: pageText) == "Only in metadata.")
    }

    @Test("Decimals don't split sentences")
    func sentences() {
        #expect(RecipeParser.sentences(in: "Bake 1.5 hours. Done! Really?") == ["Bake 1.5 hours.", "Done!", "Really?"])
    }
}

@MainActor
@Suite("Recipe import mapping")
struct RecipeImportMapperTests {
    private let gram = MDQuantityUnit(id: 1, name: "Gramm", namePlural: "Gramm")
    private let kilogram = MDQuantityUnit(id: 2, name: "Kilogramm", namePlural: "Kilogramm")
    private let tablespoon = MDQuantityUnit(id: 3, name: "Esslöffel", namePlural: "Esslöffel")
    private let piece = MDQuantityUnit(id: 4, name: "Stück", namePlural: "Stück")

    private var mapper: RecipeImportMapper {
        RecipeImportMapper(
            products: [
                MDProduct(id: 1, name: "Mehl", quIDPurchase: 2, quIDStock: 2, quIDConsume: 1),
                MDProduct(id: 2, name: "Butter", quIDPurchase: 1, quIDStock: 1, quIDConsume: 1),
                MDProduct(id: 3, name: "Ei", quIDPurchase: 4, quIDStock: 4, quIDConsume: 4),
                MDProduct(id: 4, name: "Salz", quIDPurchase: 1, quIDStock: 1, quIDConsume: 1),
            ],
            quantityUnits: [gram, kilogram, tablespoon, piece],
            conversions: [MDQuantityUnitConversion(id: 1, fromQuID: 2, toQuID: 1, factor: 1000)]
        )
    }

    @Test("Amounts are converted to the stock unit")
    func convertsToStockUnit() throws {
        let ingredient = mapper.ingredient(from: IngredientLineParser.parse("500 g Mehl"))
        #expect(ingredient.productID == 1)
        #expect(ingredient.quID == gram.id)
        let product = try #require(mapper.products.first(where: { $0.id == 1 }))
        // Mehl is stocked in kg: 500 g = 0.5 kg
        #expect(mapper.stockAmount(for: ingredient.amount, quID: gram.id, product: product) == 0.5)
        #expect(ingredient.onlyCheckSingleUnitInStock == false)
    }

    @Test("Known unit spellings find the quantity unit")
    func unitAliases() {
        #expect(mapper.matchQuantityUnit(for: "EL", knownUnit: .tablespoon)?.id == tablespoon.id)
        #expect(mapper.matchQuantityUnit(for: "g", knownUnit: .gram)?.id == gram.id)
        #expect(mapper.matchQuantityUnit(for: "Stk.", knownUnit: .piece)?.id == piece.id)
    }

    @Test("Products are matched by name")
    func productMatching() {
        #expect(mapper.matchProduct(for: "kalte Butter")?.id == 2)
        #expect(mapper.matchProduct(for: "Eier")?.id == 3)
        #expect(mapper.matchProduct(for: "Zucker") == nil)
    }

    @Test("Units without a conversion only check whether anything is in stock")
    func notConvertible() {
        let ingredient = mapper.ingredient(from: IngredientLineParser.parse("2 EL Butter"))
        #expect(ingredient.productID == 2)
        #expect(ingredient.quID == tablespoon.id)
        #expect(ingredient.onlyCheckSingleUnitInStock)
    }

    @Test("Unknown units are kept as variable amount")
    func unknownUnit() {
        let ingredient = mapper.ingredient(from: IngredientLineParser.parse("1 Prise Salz"))
        #expect(ingredient.productID == 4)
        #expect(ingredient.quID == 1)
        #expect(ingredient.onlyCheckSingleUnitInStock)
        #expect(ingredient.variableAmount == "1 Prise")
    }

    @Test("Counted amounts use the piece unit")
    func countedAmountForMeasuredProduct() {
        // Butter is used in grams, so "1 Butter" is one piece and not "1 Gramm"
        let ingredient = mapper.ingredient(from: IngredientLineParser.parse("1 Butter"))
        #expect(ingredient.productID == 2)
        #expect(ingredient.quID == piece.id)
        #expect(ingredient.variableAmount.isEmpty)
        #expect(ingredient.onlyCheckSingleUnitInStock)

        // Eggs are counted in pieces
        let eggs = mapper.ingredient(from: IngredientLineParser.parse("3 Eier"))
        #expect(eggs.quID == piece.id)
        #expect(eggs.variableAmount.isEmpty)
        #expect(eggs.onlyCheckSingleUnitInStock == false)

        // Without a piece unit, the amount is shown as written
        let withoutPiece = RecipeImportMapper(products: mapper.products, quantityUnits: [gram, kilogram], conversions: mapper.conversions)
        let butter = withoutPiece.ingredient(from: IngredientLineParser.parse("1 Butter"))
        #expect(butter.quID == gram.id)
        #expect(butter.variableAmount == "1")
        #expect(butter.onlyCheckSingleUnitInStock)
    }

    @Test("A compound with a unit word is counted in that unit")
    func compoundUnitIngredient() {
        let paprika = RecipeImportMapper(
            products: [MDProduct(id: 5, name: "Paprika", quIDPurchase: 1, quIDStock: 1, quIDConsume: 1)],
            quantityUnits: [gram, piece],
            conversions: []
        )
        let ingredient = paprika.ingredient(from: IngredientLineParser.parse("1 Paprikaschote(n), rote"))
        #expect(ingredient.productID == 5)
        #expect(ingredient.amount == 1)
        #expect(ingredient.quID == piece.id)
        #expect(ingredient.unitMatch == .exact)
    }

    @Test("Vague quantities are kept as variable amount")
    func vagueAmount() {
        let ingredient = mapper.ingredient(from: IngredientLineParser.parse("n. B. Salz"))
        #expect(ingredient.productID == 4)
        #expect(ingredient.variableAmount == "n. B.")
        #expect(ingredient.onlyCheckSingleUnitInStock)
    }

    @Test("Lines are split, unless a product has the whole name")
    func automaticSplit() {
        #expect(mapper.splitAutomatically(IngredientLineParser.parse("n. B. Salz und Pfeffer"), language: "de").map(\.name) == ["Salz", "Pfeffer"])
        #expect(mapper.splitAutomatically(IngredientLineParser.parse("2 EL Öl und Essig"), language: "de").map(\.originalText) == ["2 EL Öl", "2 EL Essig"])

        let combined = RecipeImportMapper(
            products: [MDProduct(id: 1, name: "Salz und Pfeffer", quIDPurchase: 1, quIDStock: 1, quIDConsume: 1)],
            quantityUnits: [gram],
            conversions: []
        )
        #expect(combined.splitAutomatically(IngredientLineParser.parse("Salz und Pfeffer"), language: "de").count == 1)
    }

    @Test("An ingredient can be split by the person")
    func manualSplit() {
        let original = mapper.ingredient(from: IngredientLineParser.parse("2 EL Butter und Mehl"))
        var draft = RecipeImportDraft(
            name: "Test",
            baseServings: 1,
            preparationHTML: "",
            steps: [],
            importPicture: false,
            ingredients: [original],
            language: "de"
        )
        #expect(mapper.canSplit(original, language: "de"))
        mapper.split(ingredientID: original.id, in: &draft)
        #expect(draft.ingredients.map(\.productID) == [2, 1])
        #expect(draft.ingredients.allSatisfy { $0.amount == 2 && $0.quID == tablespoon.id })
    }

    @Test("Servings are read from the yield", arguments: [("4 Portionen", 4.0), ("Serves 2-3", 2.0), ("12", 12.0)])
    func servings(yield: String, servings: Double) {
        #expect(RecipeImportMapper.servings(from: yield) == servings)
    }
}

@MainActor
@Suite("Recipe import suggestions")
struct RecipeImportSuggestionTests {
    private let gram = MDQuantityUnit(id: 1, name: "Gram", namePlural: "Grams")
    private let milliliter = MDQuantityUnit(id: 2, name: "ml (Milliliter)")
    private let teaspoon = MDQuantityUnit(id: 3, name: "Teelöffel", namePlural: "Teelöffel")
    private let piece = MDQuantityUnit(id: 4, name: "Stück", namePlural: "Stück")
    private let can = MDQuantityUnit(id: 5, name: "Dose")

    private func mapper(products: [String]) -> RecipeImportMapper {
        RecipeImportMapper(
            products: products.enumerated().map { MDProduct(id: $0.offset + 1, name: $0.element, quIDPurchase: 4, quIDStock: 4, quIDConsume: 4) },
            quantityUnits: [gram, milliliter, teaspoon, piece, can],
            conversions: []
        )
    }

    private func matchedName(_ line: String, products: [String]) -> String? {
        let mapper = mapper(products: products)
        let ingredient = mapper.ingredient(from: IngredientLineParser.parse(line))
        return mapper.products.first(where: { $0.id == ingredient.productID })?.name
    }

    @Test("A more specific product described by the note is preferred")
    func noteMakesItSpecific() {
        #expect(matchedName("0.5 TL Thymian (getrockneter)", products: ["Thymian", "Thymian, getrocknet"]) == "Thymian, getrocknet")
        #expect(matchedName("0.5 TL Thymian (getrockneter)", products: ["Thymian frisch", "Thymian"]) == "Thymian")
    }

    @Test("Without the exact product, a similar one is suggested")
    func plainProductIsSuggested() {
        let mapper = mapper(products: ["Thymian frisch"])
        let ingredient = mapper.ingredient(from: IngredientLineParser.parse("0.5 TL Thymian (getrockneter)"))
        #expect(ingredient.productID == 1)
        #expect(ingredient.productMatch == .suggested)
    }

    @Test("Exact names are exact matches")
    func exactMatch() {
        let mapper = mapper(products: ["Champignon", "Zwiebel"])
        #expect(mapper.ingredient(from: IngredientLineParser.parse("500 g Champignons (frische)")).productMatch == .exact)
        #expect(mapper.ingredient(from: IngredientLineParser.parse("1 Zwiebel(n) (klein gehackte)")).productMatch == .exact)
    }

    @Test(
        "Products are suggested for adjectives, compounds and typos",
        arguments: [
            ("125 ml süße Sahne", "Sahne"),
            ("4 Schweineschnitzel", "Schnitzel"),
            ("Mehl", "Weizenmehl"),
            ("200 g Jogurt", "Joghurt"),
        ]
    )
    func suggestions(line: String, product: String) {
        let mapper = mapper(products: [product, "Zucker"])
        let ingredient = mapper.ingredient(from: IngredientLineParser.parse(line))
        #expect(ingredient.productID == 1)
        #expect(ingredient.productMatch == .suggested)
    }

    @Test("Unrelated products aren't suggested")
    func noFalseSuggestions() {
        #expect(matchedName("Butterschmalz", products: ["Butter", "Salz"]) == nil)
        #expect(matchedName("Zucker", products: ["Butter"]) == nil)
    }

    @Test("Units are matched by spelling, name words and stems")
    func unitMatching() {
        let mapper = mapper(products: [])
        #expect(mapper.quantityUnitMatch(for: "g", knownUnit: .gram)?.unit.id == gram.id)
        #expect(mapper.quantityUnitMatch(for: "g", knownUnit: .gram)?.quality == .exact)
        #expect(mapper.quantityUnitMatch(for: "ml", knownUnit: .milliliter)?.unit.id == milliliter.id)
        #expect(mapper.quantityUnitMatch(for: "TL", knownUnit: .teaspoon)?.unit.id == teaspoon.id)
        #expect(mapper.quantityUnitMatch(for: "Dosen", knownUnit: nil)?.unit.id == can.id)
        #expect(mapper.quantityUnitMatch(for: "Bund", knownUnit: .bunch) == nil)
    }

    @Test("Missing units can be created with their full name")
    func newUnitNames() {
        let teaspoon = IngredientLineParser.parse("0.5 TL Salz")
        #expect(teaspoon.newQuantityUnitNames(language: .english)?.singular == "Teelöffel")
        let bunch = IngredientLineParser.parse("1 Bund Petersilie")
        #expect(bunch.newQuantityUnitNames(language: .english)?.singular == "Bund")
        let gram = IngredientLineParser.parse("100g flour")
        #expect(gram.newQuantityUnitNames(language: .english)?.plural == "Grams")
        #expect(gram.newQuantityUnitNames(language: .german)?.singular == "Gramm")
        #expect(IngredientUnitLanguage.detect(in: [teaspoon, bunch, gram]) == .german)
    }

    @Test("A created unit is used for all ingredients with that unit")
    func fillsMissingUnits() {
        let lines = ["1 Bund Petersilie", "1 Bund Schnittlauch"].map { IngredientLineParser.parse($0) }
        let before = mapper(products: ["Petersilie", "Schnittlauch"])
        var draft = RecipeImportDraft(
            name: "Test",
            baseServings: 1,
            preparationHTML: "",
            steps: [],
            imageURL: nil,
            importPicture: false,
            sourceURL: nil,
            ingredients: lines.map { before.ingredient(from: $0) }
        )
        let allUnmatched = draft.ingredients.allSatisfy { $0.hasUnmatchedUnit }
        #expect(allUnmatched)

        let bunch = MDQuantityUnit(id: 6, name: "Bund", namePlural: "Bund")
        let after = RecipeImportMapper(products: before.products, quantityUnits: before.quantityUnits + [bunch], conversions: [])
        after.fillMissingMatches(in: &draft)
        let allMatched = draft.ingredients.allSatisfy { $0.quID == bunch.id && !$0.hasUnmatchedUnit }
        #expect(allMatched)
    }

    @Test("A unit without a conversion can be connected to the product")
    func connectsUnitToProduct() {
        let bunch = MDQuantityUnit(id: 6, name: "Bund", namePlural: "Bund")
        let products = [MDProduct(id: 1, name: "Petersilie", quIDPurchase: 4, quIDStock: 4, quIDConsume: 4)]
        let before = RecipeImportMapper(products: products, quantityUnits: [piece, bunch], conversions: [])
        var ingredient = before.ingredient(from: IngredientLineParser.parse("2 Bund Petersilie"))
        let product = products[0]
        #expect(ingredient.quID == bunch.id)
        #expect(ingredient.onlyCheckSingleUnitInStock)
        #expect(before.needsUnitConnection(ingredient, product: product))

        // 1 Bund Petersilie = 3 Stück, only for this product
        let conversion = MDQuantityUnitConversion(id: 1, fromQuID: bunch.id, toQuID: piece.id, factor: 3, productID: product.id)
        let after = RecipeImportMapper(products: products, quantityUnits: [piece, bunch], conversions: [conversion])
        after.unitChanged(&ingredient)
        #expect(!after.needsUnitConnection(ingredient, product: product))
        #expect(!ingredient.onlyCheckSingleUnitInStock)
        #expect(ingredient.variableAmount.isEmpty)
        #expect(after.stockAmount(for: ingredient.amount, quID: bunch.id, product: product) == 6)
    }

    @Test("Apple Intelligence only looks at ingredients without a product, and its suggestions need a check")
    func intelligenceSuggestion() {
        let mapper = mapper(products: ["Rapsöl", "Butter"])
        var oil = mapper.ingredient(from: IngredientLineParser.parse("1 EL Pflanzenöl"))
        let butter = mapper.ingredient(from: IngredientLineParser.parse("20 g Butter"))
        #expect(RecipeImportMapper.needsIntelligenceMatch(oil))
        #expect(!RecipeImportMapper.needsIntelligenceMatch(butter))

        let rapeseedOil = mapper.products[0]
        mapper.intelligenceSuggested(rapeseedOil, for: &oil)
        #expect(oil.productID == rapeseedOil.id)
        #expect(oil.productMatch == .intelligence)
        #expect(oil.productMatch.needsCheck)
        #expect(!RecipeImportMapper.needsIntelligenceMatch(oil))
        #expect(oil.quID != nil)
    }

    @Test("With many products, the ones with similar letters are offered to Apple Intelligence")
    func intelligenceCandidates() {
        let names = (1...200).map { "Produkt \($0)" } + ["Pflanzenfett", "Rapsöl"]
        let mapper = mapper(products: names)
        let candidates = mapper.intelligenceCandidates(for: "Pflanzenöl", limit: 10).map(\.name)
        #expect(candidates.count == 10)
        #expect(candidates.contains("Pflanzenfett"))
        #expect(mapper.intelligenceCandidates(for: "Pflanzenöl", limit: 500).count == names.count)
    }

    @Test("Units that are already convertible don't need a connection")
    func noConnectionNeeded() {
        let products = [MDProduct(id: 1, name: "Mehl", quIDPurchase: 4, quIDStock: 4, quIDConsume: 4)]
        let mapper = RecipeImportMapper(
            products: products,
            quantityUnits: [piece, gram],
            conversions: [MDQuantityUnitConversion(id: 1, fromQuID: piece.id, toQuID: gram.id, factor: 1000)]
        )
        let inGrams = mapper.ingredient(from: IngredientLineParser.parse("500 g Mehl"))
        let inStockUnit = mapper.ingredient(from: IngredientLineParser.parse("2 Stück Mehl"))
        #expect(!mapper.needsUnitConnection(inGrams, product: products[0]))
        #expect(!mapper.needsUnitConnection(inStockUnit, product: products[0]))
    }
}

@MainActor
@Suite("Recipe ingredient amounts")
struct RecipeAmountConversionTests {
    // Flour is stocked in kg (id 2), 1 kg = 1000 g (id 1); tablespoons (id 3) have no conversion
    private let flour = MDProduct(id: 1, name: "Mehl", quIDPurchase: 2, quIDStock: 2, quIDConsume: 1)
    private let conversions = [MDQuantityUnitConversion(id: 1, fromQuID: 2, toQuID: 1, factor: 1000)]

    @Test("Entered amounts are saved in the stock unit")
    func stored() {
        #expect(RecipeAmountConversion.storedAmount(for: 500, quID: 1, onlyCheckSingleUnitInStock: false, product: flour, conversions: conversions) == 0.5)
        #expect(RecipeAmountConversion.storedAmount(for: 2, quID: 2, onlyCheckSingleUnitInStock: false, product: flour, conversions: conversions) == 2)
    }

    @Test("Saved amounts are shown in the ingredient's unit")
    func displayed() {
        #expect(
            RecipeAmountConversion.displayAmount(forStored: 0.5, quID: 1, onlyCheckSingleUnitInStock: false, product: flour, conversions: conversions) == 500
        )
    }

    @Test("Only checking stock keeps the amount as entered")
    func onlyCheck() {
        #expect(RecipeAmountConversion.storedAmount(for: 500, quID: 1, onlyCheckSingleUnitInStock: true, product: flour, conversions: conversions) == 500)
        #expect(
            RecipeAmountConversion.displayAmount(forStored: 500, quID: 1, onlyCheckSingleUnitInStock: true, product: flour, conversions: conversions) == 500
        )
    }

    @Test("Units without a conversion keep the amount")
    func noConversion() {
        #expect(RecipeAmountConversion.storedAmount(for: 2, quID: 3, onlyCheckSingleUnitInStock: false, product: flour, conversions: conversions) == 2)
    }
}
