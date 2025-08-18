//
//  GeminiModel.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/8/25.
//

import Foundation

enum GeminiModel: Equatable, Hashable, Identifiable, CaseIterable, Sendable {
    case pro
    case flash
    case flashLite
    case flash2
    case flash2Lite
    
    var id: String { rawValue }
    
    init?(rawValue: String) {
        switch rawValue {
        case "gemini-2.5-flash-lite":
            self = .flashLite
        case "gemini-2.5-flash":
            self = .flash
        case "gemini-2.5-pro":
            self = .pro
        case "gemini-2.0-flash-lite":
            self = .flash2Lite
        case "gemini-2.0-flash":
            self = .flash2
        default:
            return nil
        }
    }
    
    nonisolated var rawValue: String {
        switch self {
        case .flashLite:
            return "gemini-2.5-flash-lite"
        case .flash:
            return "gemini-2.5-flash"
        case .pro:
            return "gemini-2.5-pro"
        case .flash2Lite:
            return "gemini-2.0-flash-lite"
        case .flash2:
            return "gemini-2.0-flash"
        }
    }
    
    var displayName: String {
        switch self {
        case .flashLite:
            return "Gemini 2.5 Flash-Lite"
        case .flash:
            return "Gemini 2.5 Flash"
        case .pro:
            return "Gemini 2.5 Pro"
        case .flash2Lite:
            return "Gemini 2.0 Flash-Lite"
        case .flash2:
            return "Gemini 2.0 Flash"
        }
    }
    
    // Regular API pricing per 1M tokens in USD
    var regularInputPrice: Double {
        switch self {
        case .flashLite:
            return 0.10
        case .flash:
            return 0.30
        case .pro:
            return 1.25 // <=200K tokens
        case .flash2Lite:
            return 0.075
        case .flash2:
            return 0.10
        }
    }
    
    var regularOutputPrice: Double {
        switch self {
        case .flashLite:
            return 0.40
        case .flash:
            return 2.50
        case .pro:
            return 10.00 // <=200K tokens
        case .flash2Lite:
            return 0.30
        case .flash2:
            return 0.40
        }
    }
    
    // Pro model has different pricing for >200K tokens
    var regularInputPriceHighVolume: Double? {
        switch self {
        case .pro:
            return 2.50 // >200K tokens
        default:
            return nil
        }
    }
    
    var regularOutputPriceHighVolume: Double? {
        switch self {
        case .pro:
            return 15.00 // >200K tokens
        default:
            return nil
        }
    }
    
    var batchInputPrice: Double {
        return regularInputPrice * 0.5
    }
    
    var batchOutputPrice: Double {
        return regularOutputPrice * 0.5
    }
    
    var batchInputPriceHighVolume: Double? {
        guard let highVolumePrice = regularInputPriceHighVolume else { return nil }
        return highVolumePrice * 0.5
    }
    
    var batchOutputPriceHighVolume: Double? {
        guard let highVolumePrice = regularOutputPriceHighVolume else { return nil }
        return highVolumePrice * 0.5
    }
}
