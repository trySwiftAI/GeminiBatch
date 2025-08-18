//
//  TokenResultsView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/18/25.
//

import SwiftUI

struct TokenResultsView: View {
    
    private let viewModel: TokenResultViewModel
    
    init(
        geminiModel: GeminiModel,
        totalTokenCount: Int,
        promptTokenCount: Int,
        thoughtsTokenCount: Int,
        candidatesTokenCount: Int
    ) {
        self.viewModel = TokenResultViewModel(
            geminiModel: geminiModel,
            totalTokenCount: totalTokenCount,
            inputTokenCount: promptTokenCount,
            thoughtsTokenCount: thoughtsTokenCount,
            outputTokenCount: candidatesTokenCount
        )
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                captionText("Estimated Total Cost:")
                Text(viewModel.totalPrice)
                    .font(.title3)
                    .foregroundColor(.green)
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    captionText("Input Tokens:")
                    copyableText(viewModel.inputPriceCalculationText)
                }
                HStack {
                    captionText("Thought Tokens:")
                    copyableText(viewModel.thoughtPriceCalculationText)
                }
                HStack {
                    captionText("Output Tokens:")
                    copyableText(viewModel.outputPriceCalculationText)
                }
            }
            .padding(5)
            .overlay(
                Rectangle()
                    .stroke(Color(.separatorColor), lineWidth: 0.5)
            )
        }
    }
}

extension TokenResultsView {
    @ViewBuilder
    private func captionText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    @ViewBuilder
    private func copyableText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .textSelection(.enabled)
            .onTapGesture {
                copyToClipboard(text)
            }
            .help("Tap to copy")
    }
    
    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

#Preview("Normal Volume") {
    TokenResultsView(
        geminiModel: .flash,
        totalTokenCount: 45_320,
        promptTokenCount: 12_450,
        thoughtsTokenCount: 8_120,
        candidatesTokenCount: 24_750
    )
    .padding()
}

#Preview("High Volume - Pro Model") {
    TokenResultsView(
        geminiModel: .pro,
        totalTokenCount: 50_000,
        promptTokenCount: 500_000,
        thoughtsTokenCount: 750_000,
        candidatesTokenCount: 125_000
    )
    .padding()
}

#Preview("Flash Lite Model") {
    TokenResultsView(
        geminiModel: .flashLite,
        totalTokenCount: 15_200,
        promptTokenCount: 5_400,
        thoughtsTokenCount: 0,
        candidatesTokenCount: 9_800
    )
    .padding()
}
