//
//  StockJournalRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.10.23.
//

import SwiftUI
import SwiftData

struct StockJournalRowView: View {
    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext
    
    var product: MDProduct? {
        let predicate = #Predicate<MDProduct> { product in
            product.id == journalEntry.productID
        }
        
        let descriptor = FetchDescriptor<MDProduct>(
            predicate: predicate,
            sortBy: []
        )
        
        return (try? modelContext.fetch(descriptor))?.first
    }
    
    var location: MDLocation? {
        let predicate = #Predicate<MDLocation> { location in
            location.id == journalEntry.locationID
        }
        
        let descriptor = FetchDescriptor<MDLocation>(
            predicate: predicate,
            sortBy: []
        )
        
        return (try? modelContext.fetch(descriptor))?.first
    }
    
    var quantityUnit: MDQuantityUnit? {
        let predicate = #Predicate<MDQuantityUnit> { quantityUnit in
            product != nil ? quantityUnit.id == product!.quIDStock : false
        }
        
        let descriptor = FetchDescriptor<MDQuantityUnit>(
            predicate: predicate,
            sortBy: []
        )
        
        return (try? modelContext.fetch(descriptor))?.first
    }
    
    var grocyUser: GrocyUser? {
        let predicate = #Predicate<GrocyUser> { grocyUser in
            grocyUser.id == journalEntry.userID
        }
        
        let descriptor = FetchDescriptor<GrocyUser>(
            predicate: predicate,
            sortBy: []
        )
        
        return (try? modelContext.fetch(descriptor))?.first
    }
    
    @Query(sort: \GrocyUser.id, order: .forward) var grocyUsers: GrocyUsers
    
    @AppStorage("localizationKey") var localizationKey: String = "en"
    
    var journalEntry: StockJournalEntry
    
    var body: some View {
        VStack(alignment: .leading){
            Text(product?.name ?? "Name Error")
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
                Text("Location: \(location?.name ?? "Location Error")")
                Text("Done by: \(grocyUser?.displayName ?? "Username Error")")
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
