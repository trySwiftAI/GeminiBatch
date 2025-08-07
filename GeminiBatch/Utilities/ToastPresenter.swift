//
//  ToastManager.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/7/25.
//

import SwiftUI

@Observable
class ToastPresenter {
    var message: String = ""
    var type: ToastType = .success
    var isPresented: Bool = false
    
    init() {
        
    }
    
    init(message: String, type: ToastType, isPresented: Bool) {
        self.message = message
        self.type = type
        self.isPresented = isPresented
    }
    
    func showToast(_ type: ToastType, withMessage message: String) {
        withAnimation {
            self.message = message
            self.type = type
            self.isPresented = true
        }
    }
    
    func showErrorToast(withMessage message: String) {
        showToast(.error, withMessage: message)
    }
    
    func showSuccessToast(withMessage message: String) {
        showToast(.success, withMessage: message)
    }
    
    func showInfoToast(withMessage message: String) {
        showToast(.info, withMessage: message)
    }
    
    func showWarningToast(withMessage message: String) {
        showToast(.warning, withMessage: message)
    }
    
    func hideToast() {
        self.message = ""
        withAnimation {
            self.isPresented = false
        }
    }
}
