//
//  BatchJobMessageType.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/11/25.
//

import Foundation

enum BatchJobMessageType: String, Codable, CaseIterable {
    case success
    case error
    case pending
    
    var systemImageName: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .pending:
            return "clock.fill"
        }
    }
    
    var color: String {
        switch self {
        case .success:
            return "green"
        case .error:
            return "red"
        case .pending:
            return "orange"
        }
    }
}
