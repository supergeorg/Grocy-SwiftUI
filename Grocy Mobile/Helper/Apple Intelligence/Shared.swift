//
//  Shared.swift
//  Grocy Mobile
//
//  Created by Georg Meißner on 22.03.26.
//

import Foundation
import FoundationModels

public actor AppleIntelligenceStatus {
    public static var isAppleIntelligenceAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }
}
