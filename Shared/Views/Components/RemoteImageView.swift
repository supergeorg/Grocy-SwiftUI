//
//  RemoteImageView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 09.12.20.
//

import SwiftUI
import Combine

class ImageLoader: ObservableObject {
    var didChange = PassthroughSubject<Data, Never>()
    var data = Data() {
        didSet {
            didChange.send(data)
        }
    }

    init(urlString:String) {
        guard let url = URL(string: urlString) else { return }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            DispatchQueue.main.async {
                self.data = data
            }
        }
        task.resume()
    }
}


struct RemoteImageView: View {
    @ObservedObject var imageLoader:ImageLoader
    @State var image:NSImage = NSImage()

    init(withURL url:String) {
        imageLoader = ImageLoader(urlString:url)
    }

    var body: some View {
        VStack {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width:100, height:100)
        }.onReceive(imageLoader.didChange) { data in
            self.image = NSImage(data: data) ?? NSImage()
        }
    }
}

//struct RemoteImageView_Previews: PreviewProvider {
//    static var previews: some View {
//        RemoteImageView()
//    }
//}
