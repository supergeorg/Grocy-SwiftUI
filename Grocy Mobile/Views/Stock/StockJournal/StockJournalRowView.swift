//
//  StockJournalRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.10.23.
//

import SwiftData
import SwiftUI

struct StockJournalRowView: View {
    var journalEntry: StockJournalEntry
    var product: MDProduct?
    var location: MDLocation?
    var quantityUnit: MDQuantityUnit?
    var grocyUser: GrocyUser?

    @AppStorage("localizationKey") var localizationKey: String = "en"

    var body: some View {
        VStack(alignment: .leading) {
            Text(product?.name ?? "Name Error")
                .font(.headline)
                .strikethrough(journalEntry.undone, color: .primary)
            if journalEntry.undone {
                if let date = getDateFromTimestamp(journalEntry.undoneTimestamp ?? "") {
                    HStack(spacing: Spacing.xxSmall) {
                        Text("\(Text("Undone on")):")
                        Text(formatDateAsString(date, showTime: true, localizationKey: localizationKey) ?? "")
                        Text(getRelativeDateAsText(date, localizationKey: localizationKey) ?? "")
                            .italic()
                    }
                    .font(.caption)
                }
            }
            Group {
                HStack(spacing: Spacing.xxSmall) {
                    Text("\(Text("Amount")):")
                    Text("\(journalEntry.amount.formattedAmount) \(quantityUnit?.getName(amount: journalEntry.amount) ?? "")")
                }
                HStack(spacing: Spacing.xxSmall) {
                    Text("\(Text("Transaction time")):")
                    Text(formatDateAsString(journalEntry.rowCreatedTimestamp, showTime: true, localizationKey: localizationKey) ?? "")
                    Text(getRelativeDateAsText(journalEntry.rowCreatedTimestamp, localizationKey: localizationKey) ?? "")
                        .italic()
                }
                HStack(spacing: Spacing.xxSmall) {
                    Text("\(Text("Transaction type")):")
                    Text(journalEntry.transactionType.localizedName)
                }
                if let locationName = location?.name {
                    HStack(spacing: Spacing.xxSmall) {
                        Text("\(Text("Location")):")
                        Text(locationName)
                    }
                }
                HStack(spacing: Spacing.xxSmall) {
                    Text("\(Text("Done by")):")
                    Text(grocyUser?.displayName ?? "Username Error")
                }
                if let note = journalEntry.note {
                    HStack(spacing: Spacing.xxSmall) {
                        Text("\(Text("Note")): ")
                        Text(note)
                    }
                }
            }
            .font(.caption)
        }
        .foregroundStyle(journalEntry.undone ? .secondary : .primary)
    }
}

#Preview(traits: .previewData) {
    let container = PreviewContainer.shared
    let context = ModelContext(container)

    // Fetch one object from the preview store
    let descriptor = FetchDescriptor<StockJournalEntry>()
    let journalEntry = (try? context.fetch(descriptor))?.randomElement()

    //    let productDescriptor = FetchDescriptor<MDProduct>(predicate: #Predicate<MDProduct> { $0.id == journalEntry?.productID })
    //    let product = (try? context.fetch(productDescriptor))?.first

    List {
        if let journalEntry {
            StockJournalRowView(journalEntry: journalEntry, product: MDProduct())
        }
    }
}
