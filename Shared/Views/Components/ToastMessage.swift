//
//  ToastMessage.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 28.01.21.
//
// Inspired by user protasm on StackOverflow: https://stackoverflow.com/questions/56550135/swiftui-global-overlay-that-can-be-triggered-from-any-view

import SwiftUI

struct ToastMessageText<Presenting>: View where Presenting: View {
    @Binding var isPresented: Bool
    var isSuccess: Bool?
    let presenter: () -> Presenting
    let text: LocalizedStringKey
    let delay: TimeInterval = 2
    
    var body: some View {
        if self.isPresented {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                withAnimation {
                    self.isPresented = false
                }
            }
        }
        return ZStack(alignment: .bottom) {
            self.presenter()
            HStack(alignment: .center) {
                if let isSuccess = isSuccess {
                    Image(systemName: isSuccess ? MySymbols.success : MySymbols.failure)
                        .font(.title)
                }
                Text(text)
            }
            .padding()
            .background(isSuccess != nil ? (isSuccess! ? Color.green.opacity(0.9) : Color.red.opacity(0.9)) : Color.gray, in: RoundedRectangle(cornerRadius: 16.0))
            .opacity(self.isPresented ? 1 : 0)
            .padding(.bottom)
        }
    }
}

struct ToastMessageTextItem<Presenting, Item>: View where Item: Identifiable, Presenting: View {
    @Binding var item: Item?
    let presenter: () -> Presenting
    var text: (Item) -> LocalizedStringKey
    @Binding var isSuccess: Bool
    let delay: TimeInterval = 2
    
    var body: some View {
        if self.item != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                withAnimation {
                    self.item = nil
                }
            }
        }
        return ZStack(alignment: .bottom) {
            self.presenter()
            HStack(alignment: .center) {
                if item != nil {
                    Image(systemName: isSuccess ? MySymbols.success : MySymbols.failure)
                        .font(.title)
                }
                if let item = item {
                    Text(self.text(item))
                }
            }
            .padding()
            .background(isSuccess ? Color.green.opacity(0.9) : Color.red.opacity(0.9), in: RoundedRectangle(cornerRadius: 16.0))
            .opacity(self.item != nil ? 1 : 0)
            .padding(.bottom)
        }
    }
}

struct ToastMessage_Previews: PreviewProvider {
    static var previews: some View {
        Text("Test toast")
            .toast(isPresented: Binding.constant(true), isSuccess: true, text: LocalizedStringKey("Yay, a toast"))
    }
}
