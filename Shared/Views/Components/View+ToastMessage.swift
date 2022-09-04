//
//  View+ToastMessage.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 29.01.21.
//

import SwiftUI

extension View {
    func toast(isPresented: Binding<Bool>, isSuccess: Bool? = nil, text: LocalizedStringKey) -> some View{
        ToastMessageText(
            isPresented: isPresented,
            isSuccess: isSuccess,
            presenter: { self },
            text: text
        )
    }

    public func toast<Item>(item: Binding<Item?>, isSuccess: Binding<Bool>, isShown: Bool, text: @escaping (Item) -> LocalizedStringKey) -> some View where Item: Identifiable{
        ToastMessageTextItem(
            item: item,
            presenter: { self },
            text: text,
            isShown: isShown,
            isSuccess: isSuccess
        )
    }
}
