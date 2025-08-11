//
//  BatchJobMessage.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/11/25.
//

import Foundation
import SwiftData

@Model
final class BatchJobMessage {
    var id: UUID
    var message: String
    var type: BatchJobMessageType
    var timestamp: Date
    
    var batchJob: BatchJob?
    
    init(message: String, type: BatchJobMessageType) {
        self.id = UUID()
        self.message = message
        self.type = type
        self.timestamp = Date()
    }
}