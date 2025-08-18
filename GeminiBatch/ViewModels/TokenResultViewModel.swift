//
//  TokenResultViewModel.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/18/25.
//

import Foundation

struct TokenResultViewModel {
    
    let geminiModel: GeminiModel
    
    let totalTokenCount: Int
    let inputTokenCount: Int
    let thoughtsTokenCount: Int
    let outputTokenCount: Int
    
    var isHighVolumeInput: Bool {
        return inputTokenCount > 200_000
    }
    
    var isHighVolumeOutput: Bool {
        return (thoughtsTokenCount + outputTokenCount) > 200_000
    }
    
    var inputTokenPrice: String {
        let cost = batchCostForInputTokens(inputTokenCount)
        return String(format: "$%.4f", cost)
    }
    
    var thoughtsTokenPrice: String {
        let cost = batchCostForOutputTokens(thoughtsTokenCount)
        return String(format: "$%.4f", cost)
    }
    
    var outputTokenPrice: String {
        let cost = batchCostForOutputTokens(outputTokenCount)
        return String(format: "$%.4f", cost)
    }
    
    var totalPrice: String {
        let inputCost = batchCostForInputTokens(inputTokenCount)
        let totalOutputTokens = thoughtsTokenCount + outputTokenCount
        let outputCost = batchCostForOutputTokens(totalOutputTokens)
        let totalCost = inputCost + outputCost
        
        return String(format: "$%.4f", totalCost)
    }
    
    var inputPriceCalculationText: String {
        if isHighVolumeInput, let highRegularInputPrice = geminiModel.regularInputPriceHighVolume {
            return "( \(inputTokenCount.formatted()) / 1,000,000 ) * $\(String(format: "%.2f", highRegularInputPrice)) * 0.5 = \(inputTokenPrice)"
        } else {
            return "( \(inputTokenCount.formatted()) / 1,000,000 ) * $\(String(format: "%.2f", geminiModel.regularInputPrice)) * 0.5 = \(inputTokenPrice)"
        }
    }
    
    var thoughtPriceCalculationText: String {
        if isHighVolumeOutput, let highRegularOutputPrice = geminiModel.regularOutputPriceHighVolume {
            return "( \(thoughtsTokenCount.formatted()) / 1,000,000 ) * $\(String(format: "%.2f", highRegularOutputPrice)) * 0.5 = \(thoughtsTokenPrice)"
        } else {
            return "( \(thoughtsTokenCount.formatted()) / 1,000,000 ) * $\(String(format: "%.2f", geminiModel.regularOutputPrice)) * 0.5 = \(thoughtsTokenPrice)"
        }
    }
    
    var outputPriceCalculationText: String {
        if isHighVolumeOutput, let highRegularOutputPrice = geminiModel.regularOutputPriceHighVolume {
            return "( \(outputTokenCount.formatted()) / 1,000,000 ) * $\(String(format: "%.2f", highRegularOutputPrice)) * 0.5 = \(outputTokenPrice)"
        } else {
            return "( \(outputTokenCount.formatted()) / 1,000,000 ) * $\(String(format: "%.2f", geminiModel.regularOutputPrice)) * 0.5 = \(outputTokenPrice)"
        }
    }
}

extension TokenResultViewModel {
    
    private func batchCostForInputTokens(_ inputTokens: Int) -> Double {
        let cost: Double
        if isHighVolumeInput, let highBatchInputPrice = geminiModel.regularInputPriceHighVolume {
            cost = (Double(inputTokens) / 1_000_000) * highBatchInputPrice
        } else {
            cost = (Double(inputTokens) / 1_000_000) * geminiModel.batchInputPrice
        }
        return cost
    }
    
    private func batchCostForOutputTokens(_ outputTokens: Int) -> Double {
        let cost: Double
        if isHighVolumeOutput, let highBatchOutputPrice = geminiModel.batchOutputPriceHighVolume {
            cost = (Double(outputTokens) / 1_000_000) * highBatchOutputPrice
        } else {
            cost = (Double(outputTokens) / 1_000_000) * geminiModel.batchOutputPrice
        }
        return cost
    }
}
