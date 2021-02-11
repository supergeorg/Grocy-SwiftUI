//
//  View+ToastMessage.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 29.01.21.
//

import SwiftUI

extension View {
    func toast<Content>(isPresented: Binding<Bool>, isSuccess: Bool? = nil, @ViewBuilder content: @escaping () -> Content) -> some View where Content: View {
        ToastMessage(
            isPresented: isPresented,
            isSuccess: isSuccess,
            presenter: { self },
            content: content
        )
    }

    public func toast<Item, Content>(item: Binding<Item?>, isSuccess: Binding<Bool>, @ViewBuilder content: @escaping (Item) -> Content) -> some View where Item: Identifiable, Content : View {
        ToastMessageItem(
            item: item,
            presenter: { self },
            content: content,
            isSuccess: isSuccess
        )
    }
}
