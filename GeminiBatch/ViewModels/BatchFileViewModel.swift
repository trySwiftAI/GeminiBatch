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
    
    private let file: BatchFile
    private let fileBatchJob: BatchJob?
    private let keychainManager: ProjectKeychainManager
    
    var apiKeyIsEmpty: Bool {
        keychainManager.geminiAPIKey.isEmpty
    }
    
    init(batchFile: BatchFile, fileBatchJob: BatchJob?) {
        self.file = batchFile
        self.fileBatchJob = fileBatchJob
        self.keychainManager = ProjectKeychainManager(project: batchFile.project)
        self.batchJobAction = determineAction(for: fileBatchJob)
    }
    
    func updateStatus(forBatchJob batchJob: BatchJob?) {
        let newAction = determineAction(for: batchJob)
        
        withAnimation {
            batchJobAction = newAction
        }
    }
    
    func runJob(
        inModelContext modelContext: ModelContext
    ) async throws {
        let batchJob: BatchJob
        if let fileBatchJob = fileBatchJob {
            batchJob = fileBatchJob
            if TaskManager.shared.isTaskRunning(forBatchJobID: batchJob.persistentModelID) {
                return
            }
        } else {
            batchJob = BatchJob(batchFile: file)
            file.batchJob = batchJob
        }
        
        batchJob.jobStatus = .started
        try modelContext.save()
        
        if !keychainManager.geminiAPIKey.isEmpty {
            let batchJobManager = BatchJobManager(
                geminiAPIKey: keychainManager.geminiAPIKey,
                geminiModel: file.project.geminiModel,
                batchJobID: batchJob.id,
                modelContainer: modelContext.container
            )
            
            let batchJobID = batchJob.persistentModelID
            
            let task = Task.detached(priority: .background) {
                try await batchJobManager.run()
            }
            
            TaskManager.shared.addTask(for: batchJobID, task: task)
        } else {
            throw ProjectViewModelError.geminiAPIKeyEmpty
        }
    }
    
    func retryJob(
        inModelContext modelContext: ModelContext
    ) async throws {
        if let existingBatchJob = fileBatchJob {
            TaskManager.shared.cancelTask(forBatchJobID: existingBatchJob.persistentModelID)
            modelContext.delete(existingBatchJob)
        }
        try modelContext.save()
        try await runJob(inModelContext: modelContext)
    }
    
    func cancelJob(inModelContext modelContext: ModelContext) {
        if let batchJob = fileBatchJob {
            switch batchJob.jobStatus {
            case .pending, .running:
                let batchJobManager = BatchJobManager(
                    geminiAPIKey: keychainManager.geminiAPIKey,
                    geminiModel: file.project.geminiModel,
                    batchJobID: batchJob.id,
                    modelContainer: modelContext.container
                )
                let task = Task.detached(priority: .background) {
                    try await batchJobManager.cancel()
                }
                
                TaskManager.shared.addTask(for: batchJob.persistentModelID, task: task)
            default:
                TaskManager.shared.cancelTask(forBatchJobID: batchJob.persistentModelID)
                batchJob.jobStatus = .cancelled
                try? modelContext.save()
            }
        }
    }
}

extension BatchFileViewModel {
    
    private func determineAction(for batchJob: BatchJob?) -> BatchJobAction {
        guard let batchJob = fileBatchJob else {
            return .run
        }
        
        // Check if task is currently running
        if TaskManager.shared.isTaskRunning(forBatchJobID: batchJob.persistentModelID) {
            return .running
        }
        
        // Determine action based on job status
        switch batchJob.jobStatus {
        case .notStarted, .started, .running, .fileUploaded, .pending, .succeeded:
            return .run
        case .unspecified, .failed, .cancelled, .expired:
            return .retry
        case .jobFileDownloaded:
            return .downloadFile
        }
    }
}
