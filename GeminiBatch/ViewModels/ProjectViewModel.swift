//
//  ProjectViewModel.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/15/25.
//

import SwiftData
import SwiftUI

@Observable
final class ProjectViewModel {
    
    let project: Project
    
    var selectedBatchFile: BatchFile?
    var selectedGeminiModel: GeminiModel = .pro
    var keychainManager: ProjectKeychainManager
    
    init(project: Project) {
        self.project = project
        self.keychainManager = ProjectKeychainManager(project: project)
        
        if let geminiModel = GeminiModel(rawValue: project.geminiModel) {
            self.selectedGeminiModel = geminiModel
        }
    }
    
    func runJob(
        forFile file: BatchFile,
        inModelContext modelContext: ModelContext
    ) async throws {
        selectedBatchFile = file
        
        let batchJob: BatchJob
        if let fileBatchJob = file.batchJob {
            batchJob = fileBatchJob
        } else {
            batchJob = BatchJob(batchFile: file)
            file.batchJob = batchJob
            try modelContext.save()
        }
        
        let batchJobManager = BatchJobManager(
            geminiAPIKey: keychainManager.geminiAPIKey,
            geminiModel: selectedGeminiModel,
            batchJobID: batchJob.id,
            modelContainer: modelContext.container
        )
        
        let batchJobID = batchJob.persistentModelID
        
        // Create a background quality task to ensure it continues running
        let task = Task.detached(priority: .background) {
            try await batchJobManager.run()
        }
        
        TaskManager.shared.addTask(for: batchJobID, task: task)
    }
    
    func retryJob(
        forFile file: BatchFile,
        inModelContext modelContext: ModelContext
    ) async throws {
        selectedBatchFile = file
        
        if let existingBatchJob = file.batchJob {
            TaskManager.shared.cancelTask(for: existingBatchJob.persistentModelID)
            modelContext.delete(existingBatchJob)
        }
        try modelContext.save()
        try await runJob(forFile: file, inModelContext: modelContext)
    }
    
    func cancelJob(forFile file: BatchFile, inModelContext modelContext: ModelContext) {
        selectedBatchFile = file
        if let batchJob = file.batchJob {
            switch batchJob.jobStatus {
            case .pending, .running:
                let batchJobManager = BatchJobManager(
                    geminiAPIKey: keychainManager.geminiAPIKey,
                    geminiModel: selectedGeminiModel,
                    batchJobID: batchJob.id,
                    modelContainer: modelContext.container
                )
                let task = Task.detached(priority: .background) {
                    try await batchJobManager.cancel()
                }
                
                TaskManager.shared.addTask(for: batchJob.persistentModelID, task: task)
            default:
                TaskManager.shared.cancelTask(for: batchJob.persistentModelID)
                batchJob.jobStatus = .cancelled
                try? modelContext.save()
            }
        }
    }
    
    func cancelAllJobs() {
        TaskManager.shared.cancelAllTasks()
    }
    
    var hasRunningTasks: Bool {
        TaskManager.shared.hasRunningTasks
    }
    
    func isJobRunning(for batchJobID: PersistentIdentifier) -> Bool {
        TaskManager.shared.isTaskRunning(for: batchJobID)
    }
}
