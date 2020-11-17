//
//  NSTableView.swift
//  Grocy-SwiftUI (macOS)
//
//  Created by Georg Meissner on 13.11.20.
//

import Foundation
import AppKit

//struct Wrap<Wrapped: NSView>: NSViewRepresentable {
//    typealias Updater = (Wrapped, Context) -> Void
//
//    var makeView: () -> Wrapped
//    var update: (Wrapped, Context) -> Void
//
//    init(_ makeView: @escaping @autoclosure () -> Wrapped,
//         updater update: @escaping Updater) {
//        self.makeView = makeView
//        self.update = update
//    }
//
//    func makeNSView(context: Context) -> Wrapped {
//        makeView()
//    }
//
//    func updateNSView(_ view: Wrapped, context: Context) {
//        update(view, context)
//    }
//}
//
//extension Wrap {
//    init(_ makeView: @escaping @autoclosure () -> Wrapped,
//         updater update: @escaping (Wrapped) -> Void) {
//        self.makeView = makeView
//        self.update = { view, _ in update(view) }
//    }
//
//    init(_ makeView: @escaping @autoclosure () -> Wrapped) {
//        self.makeView = makeView
//        self.update = { _, _ in }
//    }
//}
//
//
//struct NSTableView_Previews: PreviewProvider {
//    static var previews: some View {
////        NSTableView()
//        Wrap(UIActivityIndicatorView()) {
//                        if self.viewModel.isLoading {
//                            $0.startAnimating()
//                        } else {
//                            $0.stopAnimating()
//                        }
//                    }
//    }
//}
