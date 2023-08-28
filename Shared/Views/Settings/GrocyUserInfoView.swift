//
//  GrocyUserInfoView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 05.01.21.
//

import SwiftUI

struct GrocyUserInfoView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var userPictureURL: URL? = nil
    
    var grocyUser: GrocyUser
    
    var body: some View {
        HStack{
            if let pictureFileName = grocyUser.pictureFileName {
                PictureView(pictureFileName: pictureFileName, pictureType: .userPictures)
            }
            VStack(alignment: .leading){
                Text(grocyUser.username)
                    .font(.title)
                Text(grocyUser.displayName)
            }
        }
    }
}

//struct GrocyUserInfoView_Previews: PreviewProvider {
//    static var previews: some View {
//        GrocyUserInfoView()
//    }
//}
