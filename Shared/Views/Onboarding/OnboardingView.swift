//
//  OnboardingView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 19.01.21.
//

import SwiftUI

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
    var card: OnboardingCards
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
    
    var body: some View {
        VStack{
#if os(iOS)
            TabView{
                ForEach(OnboardingCards.allCases, id:\.self) {card in
                    OnboardingCardView(card: card)
                }
            }
            .tabViewStyle(PageTabViewStyle())
#else
            HStack{
                ForEach(OnboardingCards.allCases, id:\.self) {card in
                    OnboardingCardView(card: card)
                }
            }
#endif
            Button(action: {
                onboardingNeeded = false
            }, label: {
                
                Text(LocalizedStringKey("str.onboard.start"))
#if os(iOS)
                    .padding(20)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.green)
                        }
                    )
                    .foregroundStyle(.primary)
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

public enum OnboardingCards: CaseIterable {
    case GROCY
    case ERP_BEYOND
    case IOS_MACOS
    
    public var title: String {
        switch self {
        case .GROCY:
            return "Grocy"
        case .ERP_BEYOND:
            return "str.onboard.grocy.title"
        case .IOS_MACOS:
            return "str.onboard.app.title"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .GROCY:
            return ""
        case .ERP_BEYOND:
            return "str.onboard.grocy.subtitle"
        case .IOS_MACOS:
            return "str.onboard.app.subtitle"
        }
    }
    
    public var imageName: String {
        switch self {
        case .GROCY:
            return "grocy-logo"
        case .ERP_BEYOND:
            return "web-stock"
        case .IOS_MACOS:
            return "stock-screenshot"
        }
    }
}

