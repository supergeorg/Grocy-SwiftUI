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
    @Test("Amount, unit, name and note", arguments: [
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
    ])
    func parsesLine(text: String, amount: Double, unit: String, name: String, note: String) {
        let line = IngredientLineParser.parse(text)
        #expect(line.amount == amount)
        #expect(line.unit == unit)
        #expect(line.name == name)
        #expect(line.note == note)
        #expect(line.knownUnit != nil)
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
        let html = RecipePreparationFormat.html(introduction: "Intro", steps: [RecipePreparationStep(section: nil, title: nil, text: "Only step")], sourceURL: URL(string: "https://example.com"))
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

    @Test("Servings are read from the yield", arguments: [("4 Portionen", 4.0), ("Serves 2-3", 2.0), ("12", 12.0)])
    func servings(yield: String, servings: Double) {
        #expect(RecipeImportMapper.servings(from: yield) == servings)
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
        #expect(RecipeAmountConversion.displayAmount(forStored: 0.5, quID: 1, onlyCheckSingleUnitInStock: false, product: flour, conversions: conversions) == 500)
    }

    @Test("Only checking stock keeps the amount as entered")
    func onlyCheck() {
        #expect(RecipeAmountConversion.storedAmount(for: 500, quID: 1, onlyCheckSingleUnitInStock: true, product: flour, conversions: conversions) == 500)
        #expect(RecipeAmountConversion.displayAmount(forStored: 500, quID: 1, onlyCheckSingleUnitInStock: true, product: flour, conversions: conversions) == 500)
    }

    @Test("Units without a conversion keep the amount")
    func noConversion() {
        #expect(RecipeAmountConversion.storedAmount(for: 2, quID: 3, onlyCheckSingleUnitInStock: false, product: flour, conversions: conversions) == 2)
    }
}
