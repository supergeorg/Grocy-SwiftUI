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
        }
    }
}

struct MDBatteriesView_Previews: PreviewProvider {
    static var previews: some View {
        MDBatteriesView()
    }
}
