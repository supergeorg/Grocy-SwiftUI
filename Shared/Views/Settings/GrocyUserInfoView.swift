//
//  GrocyUserInfoView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 05.01.21.
//

import SwiftUI

struct GrocyUserInfoView: View {
    @ObservedObject var grocyVM: GrocyViewModel = .shared
    
    @State private var userPictureURL: URL? = nil
    
    var grocyUser: GrocyUser
    
    var body: some View {
        HStack{
            if let userPictureURL = userPictureURL {
                AsyncImage(url: userPictureURL, content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(Color.white)
                }, placeholder: {
                    ProgressView()
                })
                .frame(width: 100, height: 100)
            }
            VStack(alignment: .leading){
                Text(grocyUser.username)
                    .font(.title)
                Text(grocyUser.displayName)
            }
        }
        .task {
            do {
                if let pictureFileName = grocyUser.pictureFileName,
                   let utf8str = pictureFileName.data(using: .utf8),
                   let pictureURL = try await grocyVM.getPictureURL(
                    groupName: "userpictures",
                    fileName: utf8str.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
                   )
                {
                    self.userPictureURL = URL(string: pictureURL)
                }
            } catch {
                grocyVM.postLog("Getting product picture failed. \(error)", type: .error)
            }
        }
    }
}

//struct GrocyUserInfoView_Previews: PreviewProvider {
//    static var previews: some View {
//        GrocyUserInfoView()
//    }
//}
