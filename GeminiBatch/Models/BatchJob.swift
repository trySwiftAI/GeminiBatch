//
//  BatchJob.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/10/25.
//

import Foundation
import SwiftData

@Model
final class BatchJob {
    var geminiJobName: String?
    var displayJobName: String
    var startedAt: Date? = nil
    var jobStatus: BatchJobStatus
    var resultsFileName: String?
    
    // usage
    var totalTokenCount: Int?
    var thoughtsTokenCount: Int?
    var promptTokenCount: Int?
    var candidatesTokenCount: Int?
    
    @Relationship(deleteRule: .cascade)
    var jobStatusMessages: [BatchJobMessage] = []
    
    var batchFile: BatchFile
    
    init(batchFile: BatchFile) {
        self.batchFile = batchFile
        self.jobStatus = .notStarted
        self.displayJobName = "batch_job_for_\(batchFile.id.uuidString)"
    }
}

extension BatchJob {
    
    var latestMessage: BatchJobMessage? {
        return jobStatusMessages.last
    }
    
    func addMessage(_ message: String, type: BatchJobMessageType) {
        let batchJobMessage = BatchJobMessage(message: message, type: type)
        batchJobMessage.batchJob = self
        jobStatusMessages.append(batchJobMessage)
    }
    
    var isExpired: Bool {
        guard let startedAt = startedAt else {
            return false
        }
        
        let expirationDate = startedAt.addingTimeInterval(48 * 60 * 60)
        return Date() > expirationDate
    }
    
    var expirationTimeRemaining: String? {
        guard let startedAt = startedAt,
              jobStatus == .pending || jobStatus == .running else {
            return nil
        }
        
        let expirationDate = startedAt.addingTimeInterval(48 * 60 * 60) // 48 hours in seconds
        let timeRemaining = expirationDate.timeIntervalSinceNow
        
        if timeRemaining <= 0 {
            return "Expiring soon..."
        }
        
        let hours = Int(timeRemaining / 3600)
        let minutes = Int((timeRemaining.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 2 {
            return "Expires in \(hours) hours"
        } else if hours >= 1 {
            return "Expires in \(hours) hour \(minutes) minutes"
        } else {
            return "Expires in \(minutes) minutes"
        }
    }
}