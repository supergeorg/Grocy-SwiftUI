//
//  SettingsAppView.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 10.06.22.
//

import SwiftUI

struct SettingsAppView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @AppStorage("devMode") private var devMode: Bool = false
    
    @AppStorage("quickScanActionAfterAdd") private var quickScanActionAfterAdd: Bool = false
    @AppStorage("autoReload") private var autoReload: Bool = false
    @AppStorage("autoReloadInterval") private var autoReloadInterval: Int = 0
    @AppStorage("isDemoModus") var isDemoModus: Bool = true
    
    let refreshIntervals: [Int] = [3, 5, 10, 30, 60, 300]
    
    var body: some View {
        Form {
#if os(iOS)
            Section(header: Text(LocalizedStringKey("str.settings.app.quickScan")).font(.title)) {
                MyToggle(isOn: $quickScanActionAfterAdd, description: "str.settings.app.quickScan.actionAfterAdd")
            }
#endif
            Section(header: Text(LocalizedStringKey("str.settings.app.update")).font(.title)) {
                MyToggle(isOn: $autoReload, description: "str.settings.app.update.autoReload")
                Picker(selection: $autoReloadInterval, content: {
                    Text("").tag(0)
                    ForEach(refreshIntervals, id:\.self, content: { interval in
                        if !isDemoModus {
                            Text("\(interval.formatted())s").tag(interval)
                        } else {
                            // Add factor to reduce server load on demo servers
                            Text("\((interval * 2).formatted())s").tag(interval * 2)
                        }
                    })
                }, label: {
                    Label(title: {
                        Text(LocalizedStringKey("str.settings.app.update.autoReload.interval"))
                    }, icon: {
                        Image(systemName: MySymbols.timedRefresh)
                    })
                }
                )
                .disabled(!autoReload)
            }
            
            if devMode {
                Section(header: Text(LocalizedStringKey("REMINDER SYNC")).font(.title)) {
                    Button(action: {
                        Task {
                            do {
                                try await ReminderStore.shared.requestAccess()
                                ReminderStore.shared.initCalendar()
                            } catch {
                                print(error)
                            }
                        }
                    }, label: {
                        Text("INIT CALENDAR")
                    })
                    Button(action: {
                        do {
                            for shoppingListItem in grocyVM.shoppingList {
                                let title = "\(shoppingListItem.amount.formattedAmount) \(grocyVM.mdProducts.first(where: { $0.id == shoppingListItem.productID })?.name ?? "\(shoppingListItem.productID ?? 0)")"
                                try ReminderStore.shared.save(Reminder(title: title, dueDate: Date(), isComplete: shoppingListItem.done == 1))
                            }
                        } catch {
                            print(error)
                        }
                    }, label: {
                        Text("ADD TO CALENDAR")
                    })
                    .disabled(!ReminderStore.shared.isAvailable_)
                }
            }
        }
        .navigationTitle(LocalizedStringKey("str.settings.app"))
    }
}

struct SettingsAppView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAppView()
    }
}
