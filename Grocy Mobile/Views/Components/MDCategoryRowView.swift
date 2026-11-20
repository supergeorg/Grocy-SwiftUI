//
//  MDCategoryRowView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 17.11.25.
//

import SwiftData
import SwiftUI

struct MDCategoryRowView<T: PersistentModel>: View {
    @Environment(\.modelContext) private var modelContext
    @State private var itemCount: Int = 0

    let categoryName: LocalizedStringKey
    let iconName: String
    let mdType: T.Type

    private func updateCount() {
        var descriptor = FetchDescriptor<T>()
        descriptor.fetchLimit = 0
        itemCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    var body: some View {
        ListRowLabel(categoryName, systemImage: iconName, count: itemCount)
            .onAppear {
                updateCount()
            }
    }
}

#Preview(traits: .previewData) {
    List {
        MDCategoryRowView(categoryName: "Stores", iconName: MySymbols.store, mdType: MDStore.self)
    }
}
