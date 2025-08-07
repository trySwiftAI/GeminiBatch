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
        HStack(spacing: 12) {
            Image(systemName: toastPresenter.type.iconName)
                .foregroundColor(toastPresenter.type.color)
                .font(.title2)
            
            Text(toastPresenter.message)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
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
        .padding()
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .background(
            ConcentricRectangle(corners: .fixed(12), isUniform: true)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            ConcentricRectangle(corners: .fixed(12), isUniform: true)
                .stroke(toastPresenter.type.color.opacity(0.3), lineWidth: 1)
        )
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
