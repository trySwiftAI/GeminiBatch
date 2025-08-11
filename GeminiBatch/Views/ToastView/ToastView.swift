//
//  ToastView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/6/25.
//

import SwiftUI

struct ToastView: View {
    @Environment(ToastPresenter.self) var toastPresenter: ToastPresenter
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: toastPresenter.type.iconName)
                .foregroundColor(toastPresenter.type.color)
                .font(.title2)
                .frame(width: 24, height: 24)
            
            Text(toastPresenter.message)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                toastPresenter.hideToast()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .padding(2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
        }
        .padding(16)
        .background(
            ConcentricRectangle(corners: .fixed(12), isUniform: true)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            ConcentricRectangle(corners: .fixed(12), isUniform: true)
                .stroke(toastPresenter.type.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .frame(maxWidth: 500)
        .padding(.horizontal)
        .onAppear {
            Task {
                try await Task.sleep(for: .seconds(4))
                toastPresenter.hideToast()
            }
        }
    }
}

#Preview("Success") {
    let toastPresenter = ToastPresenter(
        message: "Success!! Your files have been saved",
        type: .success,
        isPresented: true
    )
    
    ToastView()
        .environment(toastPresenter)
}

#Preview("Error") {
    let toastPresenter = ToastPresenter(
        message: "Error!! Something went wrong!",
        type: .error,
        isPresented: true
    )
    
    ToastView()
        .environment(toastPresenter)
}

#Preview("Info") {
    let toastPresenter = ToastPresenter(
        message: "Info: Upload files to get started",
        type: .info,
        isPresented: true
    )
    
    ToastView()
        .environment(toastPresenter)
}

#Preview("Warning") {
    let toastPresenter = ToastPresenter(
        message: "Warning: You're out of credit limits",
        type: .warning,
        isPresented: true
    )
    
    ToastView()
        .environment(toastPresenter)
}

#Preview("Long Multiline Message") {
    let toastPresenter = ToastPresenter(
        message: "This is a very long error message that spans multiple lines to demonstrate how the toast view handles longer content. It should wrap properly and display the full message without truncation. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        type: .error,
        isPresented: true
    )
    
    ToastView()
        .environment(toastPresenter)
        .frame(width: 400)
}