//
//  ToastView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/6/25.
//

import SwiftUI

struct ToastView: View {
    
    let message: String
    let type: ToastType
    
    @Binding var isPresented: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.iconName)
                .foregroundColor(type.color)
                .font(.title2)
            
            Text(message)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button {
                withAnimation {
                    isPresented = false
                }
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
            ConcentricRectangle(corners: .concentric, isUniform: true)
                .glassEffect(.regular.interactive(), in: .containerRelative)
        )
        .overlay(
            ConcentricRectangle(corners: .concentric, isUniform: true)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview("Success") {
    @Previewable @State var isPresented = true
    
    ToastView(
        message: "Success!! Your files have been saved",
        type: .success,
        isPresented: $isPresented
    )
}

#Preview("Error") {
    @Previewable @State var isPresented = true
    
    ToastView(
        message: "Error!! Something went wrong!",
        type: .error,
        isPresented: $isPresented
    )
}

#Preview("Info") {
    @Previewable @State var isPresented = true
    
    ToastView(
        message: "Info: Upload files to get started",
        type: .info,
        isPresented: $isPresented
    )
}

#Preview("Warning") {
    @Previewable @State var isPresented = true
    
    ToastView(
        message: "Warning: You're out of credit limits",
        type: .warning,
        isPresented: $isPresented
    )
}
