//
//  QuickScanModeConfigView.swift
//  Grocy-SwiftUI (iOS)
//
//  Created by Georg Meissner on 06.01.21.
//

import SwiftUI

public enum QuickScanAskMode: Int {
    case never = 0
    case always = 1
    case firstInSession = 2
}

struct QuickScanModeConfigPicker: View {
    @Binding var pickerSetting: QuickScanAskMode
    var description: String
    var icon: String
    
    var enableFirstInSession: Bool
    
    var body: some View {
        HStack{
            Image(systemName: icon)
            VStack(alignment: .leading){
                Text(LocalizedStringKey(description))
                Picker(selection: $pickerSetting, label: Text(LocalizedStringKey(description)), content: {
                    Text(LocalizedStringKey("str.quickScan.settings.state.never")).tag(QuickScanAskMode.never)
                    Text(LocalizedStringKey("str.quickScan.settings.state.always")).tag(QuickScanAskMode.always)
                    if enableFirstInSession {
                        Text(LocalizedStringKey("str.quickScan.settings.state.onlyFirstInSession"))
                            .tag(QuickScanAskMode.firstInSession)
                    }
                })
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }
}

struct QuickScanModeConfigView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @AppStorage("quickScanConsumeAskLocation") var quickScanConsumeAskLocation: QuickScanAskMode = QuickScanAskMode.always
    @AppStorage("quickScanConsumeAskSpecificItem") var quickScanConsumeAskSpecificItem: QuickScanAskMode = QuickScanAskMode.always
    @AppStorage("quickScanConsumeConsumeAll") var quickScanConsumeConsumeAll: Bool = false
    
    @AppStorage("quickScanMarkAsOpenedAskSpecificItem") var quickScanMarkAsOpenedAskSpecificItem: QuickScanAskMode = QuickScanAskMode.always
    
    @AppStorage("quickScanPurchaseAskDueDate") var quickScanPurchaseAskDueDate: QuickScanAskMode = QuickScanAskMode.always
    @AppStorage("quickScanPurchaseAskPrice") var quickScanPurchaseAskPrice: QuickScanAskMode = QuickScanAskMode.always
    @AppStorage("quickScanPurchaseAskStore") var quickScanPurchaseAskStore: QuickScanAskMode = QuickScanAskMode.always
    @AppStorage("quickScanPurchaseAskLocation") var quickScanPurchaseAskLocation: QuickScanAskMode = QuickScanAskMode.always
    
    var body: some View {
        NavigationView{
            Form{
                Section(header: Text(LocalizedStringKey("str.quickScan.consume"))) {
                    QuickScanModeConfigPicker(pickerSetting: $quickScanConsumeAskLocation, description: "str.quickScan.settings.askLocation", icon: "mappin.circle.fill", enableFirstInSession: false)
                    QuickScanModeConfigPicker(pickerSetting: $quickScanConsumeAskSpecificItem, description: "str.quickScan.settings.askSpecificEntry", icon: "line.3.crossed.swirl.circle.fill", enableFirstInSession: false)
                    MyToggle(isOn: $quickScanConsumeConsumeAll, description: "str.quickScan.settings.consumeAll", icon: "tuningfork")
                }
                
                Section(header: Text(LocalizedStringKey("str.quickScan.markAsOpened"))) {
                    QuickScanModeConfigPicker(pickerSetting: $quickScanMarkAsOpenedAskSpecificItem, description: "str.quickScan.settings.askSpecificEntry", icon: "line.3.crossed.swirl.circle.fill", enableFirstInSession: false)
                }
                
                Section(header: Text(LocalizedStringKey("str.quickScan.purchase"))) {
                    QuickScanModeConfigPicker(pickerSetting: $quickScanPurchaseAskDueDate, description: "str.quickScan.settings.askDueDate", icon: "calendar.circle.fill", enableFirstInSession: true)
                    QuickScanModeConfigPicker(pickerSetting: $quickScanPurchaseAskPrice, description: "str.quickScan.settings.askPrice", icon: "dollarsign.circle.fill", enableFirstInSession: true)
                    QuickScanModeConfigPicker(pickerSetting: $quickScanPurchaseAskStore, description: "str.quickScan.settings.askStore", icon: "cart.circle.fill", enableFirstInSession: true)
                    QuickScanModeConfigPicker(pickerSetting: $quickScanPurchaseAskLocation, description: "str.quickScan.settings.askLocation", icon: "mappin.circle.fill", enableFirstInSession: true)
                }
            }
            .navigationTitle(LocalizedStringKey("str.quickScan.settings"))
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction , content: {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }, label: { Text(LocalizedStringKey("str.close")) })
                })
            })
        }
    }
}

struct QuickScanModeConfigView_Previews: PreviewProvider {
    static var previews: some View {
        QuickScanModeConfigView()
    }
}
