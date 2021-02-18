//
//  MDBatteriesView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 17.11.20.
//

import SwiftUI

struct MDBatteriesView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var body: some View {
        VStack{
            Text("Batteries not implemented")
            Button("load") {
//                grocyVM.getMDBatteries()
                grocyVM.getEntity(entity: .batteries, type: MDBatteries())
//                let x: MDBatteries = grocyVM.getEntity(entity: .batteries) as! MDBatteries
            }
            Button("post") {
//                grocyVM.postMDObject(object: .batteries, content: MDBatteryPOST(id: "10", name: "BAT1", mdBatteryDescription: "Desc", chargeIntervalDays: "1", rowCreatedTimestamp: "ts", active: "1"))
            }
//            if (grocyVM.sucessfulMessage != nil) || (grocyVM.unsucessfulMessage != nil) {
//                Text(grocyVM.sucessfulMessage != nil ? grocyVM.sucessfulMessage!.createdObjectID : grocyVM.unsucessfulMessage!.errorMessage)
//            }
//            Button("reset succ and unsucc") {
//                grocyVM.resetSuccessMessage()
//                grocyVM.resetUnsuccessMessage()
//            }
        }
    }
}

struct MDBatteriesView_Previews: PreviewProvider {
    static var previews: some View {
        MDBatteriesView()
    }
}
