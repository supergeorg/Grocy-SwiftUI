//
//  OnboardingView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.01.21.
//

import SwiftUI

struct OnboardingCard: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String
    
}

struct OnboardingDevicesView: View {
    var body: some View {
        HStack{
            #if os(macOS)
            Image(systemName: "desktopcomputer")
            Image(systemName: "laptopcomputer")
            Image(systemName: "macmini")
            #elseif os(iOS)
            Image(systemName: "iphone.homebutton")
            Image(systemName: "iphone")
            Image(systemName: "ipad")
            Image(systemName: "ipad.homebutton")
            #endif
        }
    }
}

struct OnboardingCardView: View {
    var card: OnboardingCard
    var body: some View {
        VStack{
            Image(card.imageName)
                .resizable()
                .scaledToFit()
            Spacer()
            Text(LocalizedStringKey(card.title)).font(.largeTitle)
            if card.subtitle.isEmpty{
                OnboardingDevicesView()
                    .font(.largeTitle)
            } else {
                Text(LocalizedStringKey(card.subtitle))
            }
            Spacer()
        }
        .padding()
    }
}

struct OnboardingView: View {
    @AppStorage("onboardingNeeded") var onboardingNeeded: Bool = true
    
    let onboardingCards: [OnboardingCard] = [
        OnboardingCard(title: "Grocy", subtitle: "", imageName: "grocy-logo"),
        OnboardingCard(title: "str.onboard.grocy.title", subtitle: "str.onboard.grocy.subtitle", imageName: "web-stock"),
        OnboardingCard(title: "str.onboard.app.title", subtitle: "str.onboard.app.subtitle", imageName: "stock-screenshot")
    ]
    var body: some View {
        VStack{
            #if os(iOS)
            TabView{
                ForEach(onboardingCards, id:\.id) {card in
                    OnboardingCardView(card: card)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            #else
            HStack{
                ForEach(onboardingCards, id:\.id) {card in
                    OnboardingCardView(card: card)
                }
            }
            #endif
            Button(action: {
                onboardingNeeded = false
            }, label: {
                #if os(iOS)
                Text(LocalizedStringKey("str.onboard.start"))
                    .padding(20)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.green)
                        }
                    )
                    .foregroundColor(.primary)
                #else
                Text(LocalizedStringKey("str.onboard.start"))
                #endif
            })
            .padding()
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
