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
    let batchFiles: [BatchFile]
    let batchJobs: [BatchJob]
    var keychainManager: ProjectKeychainManager
    
    init(
        project: Project,
        batchFiles: [BatchFile],
        batchJobs: [BatchJob]
    ) {
        self.project = project
        self.batchFiles = batchFiles
        self.batchJobs = batchJobs
        self.keychainManager = ProjectKeychainManager(project: project)
    }
    
    var canRunAll: Bool {
        if keychainManager.geminiAPIKey.isEmpty {
            return false
        }
                
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
        let filesToDownload = batchFiles.filter { $0.resultPath != nil }
        if !filesToDownload.isEmpty {
            return true
        }
        return false
    }
    
    func continueRunningJobs(inModelContext modelContext: ModelContext) async throws {
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
        for file in batchFiles {
            let fileBatchJob = batchJobs.first { $0.batchFile.id == file.id }
            let batchFileViewModel = BatchFileViewModel(batchFile: file, fileBatchJob: fileBatchJob)
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
