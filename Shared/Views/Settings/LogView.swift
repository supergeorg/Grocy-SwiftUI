//
//  LogView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 16.02.21.
//

import SwiftUI

struct LogView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var logText: String = ""
    
    var body: some View {
        VStack{
            HStack{
                Button("Update") {
                    print("cant get log")
//                    do {
////                        try logText = grocyVM.getLogEntries().first?.formatString ?? ""
//                        grocyVM.getLog()
//                    } catch {
//                        print(error)
//                    }
                }
            }
            TextEditor(text: $logText)
                .disabled(true)
        }
    }
}

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView()
    }
}
