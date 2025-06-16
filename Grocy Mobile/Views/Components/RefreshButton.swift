//
//  RefreshButton.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 05.11.21.
//

import SwiftUI

struct RefreshButton: View {
    let updateData: ()  -> Void
    
#if os(macOS)
    @State private var reloadRotationDeg: Double = 0
#endif
    
    var body: some View {
        Button(action: {
            withAnimation {
#if os(macOS)
                self.reloadRotationDeg += 360
#endif
            }
            updateData()
        }, label: {
            Image(systemName: MySymbols.reload)
#if os(macOS)
                .rotationEffect(Angle.degrees(reloadRotationDeg))
#endif
        })
    }
}

struct RefreshButton_Previews: PreviewProvider {
    static var previews: some View {
        RefreshButton(updateData: { print("Update") })
    }
}
