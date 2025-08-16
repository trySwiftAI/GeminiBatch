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
    
    func updateStatus(forBatchFile batchFile: BatchFile) {
        if let batchJob = batchFile.batchJob {
            let isRunning = TaskManager.shared.isTaskRunning(for: batchJob.persistentModelID)
            if isRunning {
                batchJobAction = .running
                return
            }
            switch batchJob.jobStatus {
            case .notStarted, .fileUploaded, .pending, .running, .succeeded:
                batchJobAction = .run
                return
            case .unspecified, .failed, .cancelled, .expired:
                batchJobAction = .retry
                return
            case .jobFileDownloaded:
                batchJobAction = .downloadFile
                return
            }
        } else {
            batchJobAction = .run
            return
        }
    }
}
