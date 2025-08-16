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
    
    let batchFile: BatchFile
    
    var batchJobAction: BatchJobAction
    
    enum BatchJobAction {
        case run
        case running
        case retry
        case downloadFile
    }
    
    init(batchFile: BatchFile) {
        self.batchFile = batchFile
        let isRunning = TaskManager.shared.isTaskRunning(for: batchFile.persistentModelID)
        if isRunning {
            batchJobAction = .running
            return
        }
        if let batchJob = batchFile.batchJob {
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
