//
//  ProjectKeychainManager.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import Foundation
import SwiftUI

@Observable
class ProjectKeychainManager {
    private let project: Project
    private let keychainStorage: KeychainStorage
    
    private var _geminiAPIKey: String = ""
    
    var geminiAPIKey: String {
        get {
            _geminiAPIKey
        }
        set {
            _geminiAPIKey = newValue
            keychainStorage.wrappedValue = newValue
        }
    }
    
    init(project: Project) {
        self.project = project
        self.keychainStorage = KeychainStorage(key: "GeminiAPIKey_\(project.id.uuidString)")
        // Load the initial value from keychain
        self._geminiAPIKey = keychainStorage.wrappedValue
    }
}
