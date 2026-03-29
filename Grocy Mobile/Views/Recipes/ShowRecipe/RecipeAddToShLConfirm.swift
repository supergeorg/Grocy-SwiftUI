//
//  RecipeAddToShLConfirm.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 29.03.26.
//

import SwiftUI

struct AddMissingToShLItem: Identifiable {
    let id: Int
    var label: String
    var isChecked: Bool

    init(id: Int, label: String, isChecked: Bool = true) {
        self.id = id
        self.label = label
        self.isChecked = isChecked
    }
}

// MARK: - Popover Content

struct AddMissingToShLView: View {
    let question: String
    @Binding var items: [AddMissingToShLItem]
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        List {
            Text(question)
                .font(.headline)
                .padding()

            Section {
                ForEach($items) { $item in
                    Toggle(item.label, isOn: $item.isChecked)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction, content: {
                Button(role: .cancel, action: { onCancel() })
            })
            ToolbarItem(placement: .confirmationAction, content: {
                Button(role: .confirm, action: { onConfirm() })
            })
        }
    }
}
