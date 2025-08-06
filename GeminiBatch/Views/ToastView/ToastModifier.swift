//
//  ToastModifier.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/6/25.
//

import SwiftUI

struct ToastModifier: ViewModifier {
    let message: String
    let type: ToastType
    let duration: TimeInterval
    
    @Binding var isPresented: Bool
        
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if isPresented && !message.isEmpty {
                        VStack {
                            Spacer()
                            ToastView(
                                message: message,
                                type: type,
                                isPresented: $isPresented
                            )
                            .padding(.horizontal)
                            .padding(.bottom, 50)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        .zIndex(1000)
                    }
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8),
                           value: isPresented)
            )
    }
}

extension View {
    
    func toast(
        message: String,
        type: ToastType = .info,
        duration: TimeInterval = 3.0,
        isPresented: Binding<Bool>
    ) -> some View {
        modifier(
            ToastModifier(
                message: message,
                type: type,
                duration: duration,
                isPresented: isPresented
            )
        )
    }
    
    // Convenience methods for different toast types
    func successToast(
        message: String,
        isPresented: Binding<Bool>
    ) -> some View {
        toast(message: message, type: .success, isPresented: isPresented)
    }
    
    func errorToast(
        message: String,
        isPresented: Binding<Bool>
    ) -> some View {
        toast(message: message, type: .error, duration: 4.0, isPresented: isPresented)
    }
    
    func warningToast(
        message: String,
        isPresented: Binding<Bool>,
    ) -> some View {
        toast(message: message, type: .warning, duration: 3.5, isPresented: isPresented)
    }
    
    func infoToast(
        message: String,
        isPresented: Binding<Bool>
    ) -> some View {
        toast(message: message, type: .info, isPresented: isPresented)
    }
}

#Preview {
    @Previewable @State var isPresented = true
    
    VStack(spacing: 20) {
        ToastView(
            message: "Success! Your changes have been saved.",
            type: .success,
            isPresented: $isPresented
        )
        
        ToastView(
            message: "Error: Unable to connect to server.",
            type: .error,
            isPresented: $isPresented
        )
        
        ToastView(
            message: "Warning: This action cannot be undone.",
            type: .warning,
            isPresented: $isPresented
        )
        
        ToastView(
            message: "Info: New update available.",
            type: .info,
            isPresented: $isPresented
        )
    }
    .padding()
}
