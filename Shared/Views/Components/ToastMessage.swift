//
//  ToastMessage.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 28.01.21.
//
// Inspired by user protasm on StackOverflow: https://stackoverflow.com/questions/56550135/swiftui-global-overlay-that-can-be-triggered-from-any-view

import SwiftUI

extension View {
    func toast<Content>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View where Content: View {
        ToastMessage(
            isPresented: isPresented,
            presenter: { self },
            content: content
        )
    }
    
//    public func toast<Item, Content>(item: Binding<Item?>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping (Item) -> Content) -> some View where Item : Identifiable, Content : View {
    public func toast<Item, Content>(item: Binding<Item?>, content: @escaping () -> Content) -> some View where Item: Identifiable, Content : View {
        ToastMessageI(
            item: item,
//            presenter: { self },
            content: content
        )
    }
}

enum ToastType: Identifiable {
    case success, successAlt, fail, failAlt
    
    var id: Int {
        self.hashValue
    }
}

struct ToastMessageI<Item, Content>: View where Item: Identifiable, Content: View {
    @Binding var item: Item?
    let content: () -> Content
    let delay: TimeInterval = 2
    
    var body: some View {
        if self.item != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                withAnimation {
                    self.item = nil
                }
            }
        }
        return GeometryReader { geometry in
            ZStack(alignment: .bottom) {
//                self.presenter()
                
                ZStack {
                    Capsule()
                        .fill(Color.gray)
                    
                    self.content()
                }
                .frame(width: geometry.size.width / 1.25, height: geometry.size.height / 10)
                .opacity(self.item != nil ? 1 : 0)
            }
            .padding(.bottom)
        }
    }
}


struct ToastMessage<Presenting, Content>: View where Presenting: View, Content: View {
    @Binding var isPresented: Bool
    let presenter: () -> Presenting
    let content: () -> Content
    let delay: TimeInterval = 2
    
    var body: some View {
        if self.isPresented {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                withAnimation {
                    self.isPresented = false
                }
            }
        }
        return GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                self.presenter()
                
                ZStack {
                    Capsule()
                        .fill(Color.gray)
                    
                    self.content()
                }
                .frame(width: geometry.size.width / 1.25, height: geometry.size.height / 10)
                .opacity(self.isPresented ? 1 : 0)
            }
            .padding(.bottom)
        }
    }
}

struct ToastMessage_Previews: PreviewProvider {
    static var previews: some View {
        Text("Test toast")
            .toast(isPresented: Binding.constant(true), content: {
                HStack{
                    Text("Yay, a toast")
                    Image(systemName: "sparkles")
                        .renderingMode(.original)
                }
            })
    }
}
