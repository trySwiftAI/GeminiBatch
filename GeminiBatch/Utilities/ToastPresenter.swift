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
        self.message = message
        self.type = type
        self.isPresented = true
    }
    
    func hideToast() {
        self.message = ""
        withAnimation {
            self.isPresented = false
        }
    }
}
