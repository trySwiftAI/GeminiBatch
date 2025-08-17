//
//  ProjectViewModel.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/15/25.
//

import SwiftData
import SwiftUI

struct ProjectViewModel {
    
    let project: Project
    var keychainManager: ProjectKeychainManager
    
    init(project: Project) {
        self.project = project
        self.keychainManager = ProjectKeychainManager(project: project)
    }
    
    var canRunAll: Bool {
        if keychainManager.geminiAPIKey.isEmpty {
            return false
        }
        
        let batchJobs = project.batchFiles.compactMap(\.batchJob)
        
        return batchJobs.contains { batchJob in
            switch batchJob.jobStatus {
            case .notStarted, .fileUploaded, .running, .pending, .succeeded:
                if TaskManager.shared.isTaskRunning(forBatchJobID: batchJob.persistentModelID) {
                    return false
                }
                return true
            default:
                return false
            }
        }
    }
    
    var canDownloadAll: Bool {
        let filesToDownload = project.batchFiles.filter { $0.resultPath != nil }
        if !filesToDownload.isEmpty {
            return true
        }
        return false
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
                    geminiModel: project.geminiModel,
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
        for file in batchFiles {
            let batchFileViewModel = BatchFileViewModel(batchFile: file)
            if batchFileViewModel.batchJobAction == .run {
                try await batchFileViewModel.runJob(inModelContext: modelContext)
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
