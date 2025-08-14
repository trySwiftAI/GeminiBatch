//
//  BatchFileStatus.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/10/25.
//

import AIProxy

nonisolated enum BatchFileStatus: String, CaseIterable, Codable {
    case processing
    case active
    
    init(from geminiState: GeminiFile.State) {
        switch geminiState {
        case .processing:
            self = .processing
        case .active:
            self = .active
        }
    }
    
    var geminiStatusTitle: String {
        switch self {
        case .processing:
            return "FILE_PROCESSING"
        case .active:
            return "FILE_ACTIVE"
        }
    }
    
    var description: String {
        switch self {
        case .processing:
            return "File is being processed and cannot be used for inference yet"
        case .active:
            return "File is processed and available for inference"
        }
    }
}
