//
//  ChoreDetailsView.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 13.12.25.
//

import SwiftData
import SwiftUI

struct ChoreDetailsView: View {
    var choreID: Int
    var isPopup: Bool = false

    @Environment(GrocyViewModel.self) private var grocyVM
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(ChoreInteractionNavigationRouter.self) private var choreInteractionRouter

    @AppStorage("localizationKey") var localizationKey: String = "en"

    @Query var mdChores: MDChores
    @Query private var choreDetailsArray: [ChoreDetails]
    var choreDetails: ChoreDetails? {
        choreDetailsArray.first
    }

    init(choreID: Int, isPopup: Bool = false) {
        self.choreID = choreID
        self.isPopup = isPopup
        _choreDetailsArray = Query(
            filter: #Predicate<ChoreDetails> { $0.choreID == choreID }
        )
    }

    var formattedDate: String? {
        if let averageExecutionFrequencyHours = choreDetails?.averageExecutionFrequencyHours {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.year, .month, .weekOfMonth, .day, .hour]
            formatter.unitsStyle = .full
            formatter.maximumUnitCount = 1
            let timeInSeconds = averageExecutionFrequencyHours * 3600
            return formatter.string(from: timeInSeconds)
        } else {
            return nil
        }
    }

    private func updateData() async {
        await grocyVM.getChoreDetails(id: choreID)
    }

    var body: some View {
        Form {
            if let choreDetails = choreDetails {
                if let choreName = choreDetails.chore?.name {
                    LabeledContent(
                        content: {
                            Text(choreName)
                        },
                        label: {
                            Label("Name", systemImage: MySymbols.name)
                                .foregroundStyle(.primary)
                        }
                    )
                }
                LabeledContent(
                    content: {
                        Text("\(choreDetails.trackedCount)")
                    },
                    label: {
                        Label("Tracked count", systemImage: MySymbols.amount)
                            .foregroundStyle(.primary)
                    }
                )
                if let formattedDate {
                    LabeledContent(
                        content: {
                            Text(formattedDate)
                        },
                        label: {
                            Label("Average execution frequency", systemImage: MySymbols.chorePeriodType)
                                .foregroundStyle(.primary)
                        }
                    )
                }
                if let lastTracked = choreDetails.lastTracked {
                    LabeledContent(
                        content: {
                            HStack {
                                Text(
                                    formatDateTimeAsString(lastTracked, dateOnly: choreDetails.chore?.trackDateOnly ?? false, localizationKey: localizationKey)
                                        ?? ""
                                )
                                Text(getRelativeDateAsText(lastTracked, localizationKey: localizationKey) ?? "")
                                    .font(.caption)
                                    .italic()
                            }
                        },
                        label: {
                            Label("Last tracked", systemImage: MySymbols.date)
                                .foregroundStyle(.primary)
                        }
                    )
                }
                if let lastDoneBy = choreDetails.lastDoneBy {
                    LabeledContent(
                        content: {
                            Text(lastDoneBy.displayName)
                        },
                        label: {
                            Label("Last done by", systemImage: MySymbols.user)
                                .foregroundStyle(.primary)
                        }
                    )
                }
            } else {
                Text("Retrieving Details failed.")
            }
        }
        .navigationTitle("Chore overview")
        .task {
            await updateData()
        }
        .toolbar {
            if isPopup {
                ToolbarItem(
                    placement: .cancellationAction,
                    content: {
                        Button(
                            role: .cancel,
                            action: {
                                dismiss()
                            }
                        )
                        .keyboardShortcut(.cancelAction)
                    }
                )
            }
            ToolbarItemGroup(
                placement: .automatic,
                content: {
                    Button(
                        action: {
                            choreInteractionRouter.present(.choreLog(choreID: choreID))
                        },
                        label: {
                            Label("Chore journal", systemImage: MySymbols.stockJournal)
                        }
                    )
                    Button(
                        action: {
                            if let mdChore = mdChores.first(where: { $0.id == choreID }) {
                                choreInteractionRouter.present(.editChore(mdChore: mdChore))
                            }
                        },
                        label: {
                            Label("Edit chore", systemImage: MySymbols.edit)
                        }
                    )
                }
            )
        }
    }
}

#Preview(traits: .previewData) {
    NavigationStack {
        ChoreDetailsView(choreID: 1)
    }
}
