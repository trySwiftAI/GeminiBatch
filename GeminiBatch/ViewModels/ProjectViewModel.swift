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
    
    func continueRunningJobs(inModelContext modelContext: ModelContext) async throws {
        let batchFiles = project.batchFiles
        
        let eligibleFiles = batchFiles.filter { batchFile in
            guard let batchJob = batchFile.batchJob else { return false }
            
            switch batchJob.jobStatus {
            case .running, .pending, .succeeded:
                return true
            default:
                return false
            }
        }

        for file in eligibleFiles {
            let batchJob: BatchJob
            if let fileBatchJob = file.batchJob {
                batchJob = fileBatchJob
            } else {
                batchJob = BatchJob(batchFile: file)
                file.batchJob = batchJob
                try modelContext.save()
            }
            
            if !keychainManager.geminiAPIKey.isEmpty {
                let batchJobManager = BatchJobManager(
                    geminiAPIKey: keychainManager.geminiAPIKey,
                    geminiModel: selectedGeminiModel,
                    batchJobID: batchJob.id,
                    modelContainer: modelContext.container
                )
                
                let batchJobID = batchJob.persistentModelID
                
                let task = Task.detached(priority: .background) {
                    try await batchJobManager.getJobStatus()
                    try await batchJobManager.run()
                }
                
                TaskManager.shared.addTask(for: batchJobID, task: task)
            }
        }
    }
    
    func runAllJobs(inModelContext modelContext: ModelContext) async throws {
        let batchFiles = project.batchFiles
        
        let eligibleFiles = batchFiles.filter { batchFile in
            guard let batchJob = batchFile.batchJob else { return false }
            
            switch batchJob.jobStatus {
            case .notStarted, .fileUploaded, .running, .pending, .succeeded:
                return true
            default:
                return false
            }
        }
        
        for file in eligibleFiles {
            try await runJob(forFile: file, inModelContext: modelContext)
        }
    }
    
    func runJob(
        forFile file: BatchFile,
        inModelContext modelContext: ModelContext
    ) async throws {
        let batchJob: BatchJob
        if let fileBatchJob = file.batchJob {
            batchJob = fileBatchJob
            if TaskManager.shared.isTaskRunning(forBatchJobID: batchJob.persistentModelID) {
                return
            }
        } else {
            batchJob = BatchJob(batchFile: file)
            file.batchJob = batchJob
            try modelContext.save()
        }
        
        if !keychainManager.geminiAPIKey.isEmpty {
            let batchJobManager = BatchJobManager(
                geminiAPIKey: keychainManager.geminiAPIKey,
                geminiModel: selectedGeminiModel,
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
        forFile file: BatchFile,
        inModelContext modelContext: ModelContext
    ) async throws {
        if let existingBatchJob = file.batchJob {
            TaskManager.shared.cancelTask(forBatchJobID: existingBatchJob.persistentModelID)
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
                TaskManager.shared.cancelTask(forBatchJobID: batchJob.persistentModelID)
                batchJob.jobStatus = .cancelled
                try? modelContext.save()
            }
        }
    }
}

enum ProjectViewModelError: Error, LocalizedError {
    case geminiAPIKeyEmpty
    
    var errorDescription: String {
        switch self {
        case .geminiAPIKeyEmpty:
            return "The Gemini API Key is missing. Please update the API key and try again."
        }
    }
}
