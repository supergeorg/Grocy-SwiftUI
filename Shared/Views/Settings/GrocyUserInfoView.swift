//
//  GrocyUserInfoView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 05.01.21.
//

import SwiftUI
import URLImage

struct GrocyUserInfoView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    var grocyUser: GrocyUser
    
    var body: some View {
        HStack{
            if let pictureFileName = grocyUser.pictureFileName {
                let utf8str = pictureFileName.data(using: .utf8)
                if let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
                    if let pictureURL = grocyVM.getPictureURL(groupName: "userpictures", fileName: "\(base64Encoded)_\(base64Encoded)") {
                        if let url = URL(string: pictureURL) {
                            URLImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .background(Color.white)
                            }
                            .frame(width: 100, height: 100)
                        }
                    }
                }
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
