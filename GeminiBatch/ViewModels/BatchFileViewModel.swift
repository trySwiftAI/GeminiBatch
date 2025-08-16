//
//  BatchFileViewModel.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/16/25.
//

import SwiftData
import SwiftUI

@Observable
class BatchFileViewModel {
        
    var batchJobAction: BatchJobAction = .run
    
    enum BatchJobAction {
        case run
        case running
        case retry
        case downloadFile
    }
    
    init(batchFile: BatchFile) {
        self.batchJobAction = determineAction(for: batchFile)
    }
    
    func updateStatus(forBatchFile batchFile: BatchFile) {
        let newAction = determineAction(for: batchFile)
        
        withAnimation {
            batchJobAction = newAction
        }
    }
    
    private func determineAction(for batchFile: BatchFile) -> BatchJobAction {
        guard let batchJob = batchFile.batchJob else {
            return .run
        }
        
        // Check if task is currently running
        if TaskManager.shared.isTaskRunning(forBatchJobID: batchJob.persistentModelID) {
            return .running
        }
        
        // Determine action based on job status
        switch batchJob.jobStatus {
        case .notStarted, .fileUploaded, .pending, .running, .succeeded:
            return .run
        case .unspecified, .failed, .cancelled, .expired:
            return .retry
        case .jobFileDownloaded:
            return .downloadFile
        }
    }
}
