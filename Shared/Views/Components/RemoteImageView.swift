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

#if os(macOS)
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
#elseif os(iOS)
struct RemoteImageView: View {
    @ObservedObject var imageLoader:ImageLoader
    @State var image:UIImage = UIImage()

    init(withURL url:String) {
        imageLoader = ImageLoader(urlString:url)
    }

    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width:100, height:100)
        }.onReceive(imageLoader.didChange) { data in
            self.image = UIImage(data: data) ?? UIImage()
        }
    }
}
#endif

struct RemoteImageView_Previews: PreviewProvider {
    static var previews: some View {
        RemoteImageView(withURL: "https://www.google.com/logos/doodles/2020/december-holidays-days-2-30-6753651837108830.3-law.gif")
    }
}
