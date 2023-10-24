//
//  StockJournalRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.10.23.
//

import SwiftUI

struct StockJournalRowView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    var journalEntry: StockJournalEntry
    
    var quantityUnit: MDQuantityUnit? {
        let product = grocyVM.mdProducts.first(where: {$0.id == journalEntry.productID})
        return grocyVM.mdQuantityUnits.first(where: {$0.id == product?.quIDStock})
    }
    
    var body: some View {
        VStack(alignment: .leading){
            Text(grocyVM.mdProducts.first(where: { $0.id == journalEntry.productID })?.name ?? "Name Error")
                .font(.title)
                .strikethrough(journalEntry.undone == 1, color: .primary)
            if journalEntry.undone == 1 {
                if let date = getDateFromTimestamp(journalEntry.undoneTimestamp ?? "") {
                    HStack(alignment: .bottom){
                        Text("Undone on \(formatDateAsString(date, showTime: true, localizationKey: localizationKey) ?? "")")
                            .font(.caption)
                        Text(getRelativeDateAsText(date, localizationKey: localizationKey) ?? "")
                            .font(.caption)
                            .italic()
                    }
                    .foregroundStyle(journalEntry.undone == 1 ? Color.gray : Color.primary)
                }
            }
            Group {
                Text("Amount: \(journalEntry.amount.formattedAmount) \(quantityUnit?.getName(amount: journalEntry.amount) ?? "")")
                Text("Transaction time: \(formatTimestampOutput(journalEntry.rowCreatedTimestamp, localizationKey: localizationKey) ?? "")")
                Text("Transaction type: \(journalEntry.transactionType.formatTransactionType())")
                    .font(.caption)
                Text("Location: \(grocyVM.mdLocations.first(where: {$0.id == journalEntry.locationID})?.name ?? "Location Error")")
                Text("Done by: \(grocyVM.users.first(where: { $0.id == journalEntry.userID })?.displayName ?? "Username Error")")
                if let note = journalEntry.note {
                    Text("Note: \(note)")
                }
            }
            .foregroundStyle(journalEntry.undone == 1 ? Color.gray : Color.primary)
            .font(.caption)
        }
    }
}

//#Preview {
//    StockJournalRowView()
//}
