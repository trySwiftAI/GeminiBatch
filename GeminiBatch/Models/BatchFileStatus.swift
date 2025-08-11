//
//  BatchFileStatus.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/10/25.
//

import AIProxy

nonisolated enum BatchFileStatus: String, CaseIterable, Codable {
    case unspecified
    case processing
    case active
    case failed
    
    init(from geminiState: GeminiFile.State) {
        switch geminiState {
        case .unspecified:
            self = .unspecified
        case .processing:
            self = .processing
        case .active:
            self = .active
        case .failed:
            self = .failed
        }
    }
    
    var geminiStatusTitle: String {
        switch self {
        case .unspecified:
            return "FILE_STATE_UNSPECIFIED"
        case .processing:
            return "FILE_PROCESSING"
        case .active:
            return "FILE_ACTIVE"
        case .failed:
            return "FILE_FAILED"
        }
    }
    
    var description: String {
        switch self {
        case .unspecified:
            return "The file status is not specified or unknown"
        case .processing:
            return "File is being processed and cannot be used for inference yet"
        case .active:
            return "File is processed and available for inference"
        case .failed:
            return "File failed processing"
        }
    }
}
