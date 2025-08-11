//
//  GeminiModel.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/8/25.
//

import Foundation

enum GeminiModel: Hashable, Identifiable, CaseIterable {
    case flashLite
    case flash
    case pro
    case flash2Lite
    case flash2
    case custom(String)
    
    var id: String { 
        switch self {
        case .flashLite, .flash, .pro, .flash2Lite, .flash2:
            return rawValue
        case .custom(let modelName):
            return modelName
        }
    }
    
    var rawValue: String {
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
        case .custom(let modelName):
            return modelName
        }
    }
    
    static var allCases: [GeminiModel] {
        return [.flashLite, .flash, .pro, .flash2Lite, .flash2, .custom("Custom")]
    }
    
    static var allPredefinedCases: [GeminiModel] {
        return [.flashLite, .flash, .pro, .flash2Lite, .flash2]
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
        case .custom(let modelName):
            if modelName == "Custom" {
                return "Custom Model"
            }
            return "Custom: \(modelName)"
        }
    }
    
    var description: String {
        switch self {
        case .flashLite:
            return "Large scale processing, low latency, high volume tasks which require thinking, lower cost"
        case .flash:
            return "Large scale processing (e.g. multiple pdfs), low latency, high volume tasks which require thinking, agentic use cases"
        case .pro:
            return "Coding, reasoning, multimodal understanding"
        case .flash2Lite:
            return "Long context, realtime streaming, native tool use"
        case .flash2:
            return "Multimodal understanding, realtime streaming, native tool use"
        case .custom:
            return "Custom model with user-defined pricing"
        }
    }
    
    var useCases: [String] {
        switch self {
        case .flashLite:
            return ["Data transformation", "Translation", "Summarization"]
        case .flash:
            return ["Reason over complex problems", "Show the thinking process of the model", "Call tools natively"]
        case .pro:
            return ["Reason over complex problems", "Tackle difficult code, math and STEM problems", "Use the long context for analyzing large datasets, codebases or documents"]
        case .flash2Lite:
            return ["Process 10,000 lines of code", "Call tools natively", "Stream images and video in realtime"]
        case .flash2:
            return ["Process 10,000 lines of code", "Call tools natively, like Search", "Stream images and video in realtime"]
        case .custom:
            return ["User-defined use cases"]
        }
    }
    
    var isCustom: Bool {
        if case .custom = self {
            return true
        }
        return false
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
        case .custom:
            return 0.0 // Default for custom, should be set by user
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
        case .custom:
            return 0.0 // Default for custom, should be set by user
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
    
    // Batch pricing (50% discount)
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
    
    // Rate limits
    var rateLimitRPM: Int {
        switch self {
        case .flashLite:
            return 4000
        case .flash:
            return 1000
        case .pro:
            return 150
        case .flash2Lite:
            return 4000
        case .flash2:
            return 2000
        case .custom:
            return 1000 // Default for custom
        }
    }
    
    var freeRateLimitRPM: Int {
        switch self {
        case .flashLite:
            return 15
        case .flash:
            return 10
        case .pro:
            return 0 // Pro doesn't have free tier shown
        case .flash2Lite:
            return 30
        case .flash2:
            return 15
        case .custom:
            return 0 // Default for custom
        }
    }
    
    var freeRateLimitRequestsPerDay: Int {
        switch self {
        case .flashLite, .flash:
            return 500
        case .pro:
            return 0
        case .flash2Lite, .flash2:
            return 1500
        case .custom:
            return 0
        }
    }
    
    // Knowledge cutoff
    var knowledgeCutoff: String {
        switch self {
        case .flashLite, .flash, .pro:
            return "Jan 2025"
        case .flash2Lite, .flash2:
            return "Aug 2024"
        case .custom:
            return "Unknown"
        }
    }
    
    // Helper methods for pricing display
    func formatPrice(_ price: Double) -> String {
        return String(format: "$%.3f", price)
    }
    
    func getBatchSavings() -> String {
        return "50% off regular pricing"
    }
    
    // Create custom model with pricing
    static func customModel(name: String, inputPrice: Double, outputPrice: Double) -> GeminiModel {
        return .custom(name)
    }
    
    // Update custom model pricing (would need to be implemented with external storage)
    func withCustomPricing(inputPrice: Double, outputPrice: Double) -> GeminiModel {
        switch self {
        case .custom(let name):
            return .custom(name) // In a real implementation, you'd store the pricing separately
        default:
            return self
        }
    }
    
    // Calculate cost for given token counts
    func calculateRegularCost(inputTokens: Int, outputTokens: Int, isHighVolume: Bool = false, customInputPrice: Double? = nil, customOutputPrice: Double? = nil) -> Double {
        let inputCost: Double
        let outputCost: Double
        
        // Use custom prices if provided (for custom models)
        let effectiveInputPrice = customInputPrice ?? regularInputPrice
        let effectiveOutputPrice = customOutputPrice ?? regularOutputPrice
        
        if isHighVolume, let highInputPrice = regularInputPriceHighVolume, let highOutputPrice = regularOutputPriceHighVolume, !isCustom {
            inputCost = (Double(inputTokens) / 1_000_000) * highInputPrice
            outputCost = (Double(outputTokens) / 1_000_000) * highOutputPrice
        } else {
            inputCost = (Double(inputTokens) / 1_000_000) * effectiveInputPrice
            outputCost = (Double(outputTokens) / 1_000_000) * effectiveOutputPrice
        }
        
        return inputCost + outputCost
    }
    
    func calculateBatchCost(inputTokens: Int, outputTokens: Int, isHighVolume: Bool = false, customInputPrice: Double? = nil, customOutputPrice: Double? = nil) -> Double {
        let inputCost: Double
        let outputCost: Double
        
        // Use custom prices if provided (for custom models)
        let effectiveInputPrice = customInputPrice ?? regularInputPrice
        let effectiveOutputPrice = customOutputPrice ?? regularOutputPrice
        
        if isHighVolume, let highInputPrice = batchInputPriceHighVolume, let highOutputPrice = batchOutputPriceHighVolume, !isCustom {
            inputCost = (Double(inputTokens) / 1_000_000) * highInputPrice
            outputCost = (Double(outputTokens) / 1_000_000) * highOutputPrice
        } else {
            // Apply 50% batch discount to custom prices
            inputCost = (Double(inputTokens) / 1_000_000) * (effectiveInputPrice * 0.5)
            outputCost = (Double(outputTokens) / 1_000_000) * (effectiveOutputPrice * 0.5)
        }
        
        return inputCost + outputCost
    }
}

// MARK: - Hashable Conformance
extension GeminiModel {
    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
    
    static func == (lhs: GeminiModel, rhs: GeminiModel) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}