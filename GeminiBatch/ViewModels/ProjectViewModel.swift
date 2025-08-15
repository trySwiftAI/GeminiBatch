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
    
    var hideSideView: Bool = true
    var selectedBatchFile: BatchFile?
    var selectedGeminiModel: GeminiModel = .pro
    var keychainManager: ProjectKeychainManager
    var runningBatchJob: BatchJob?
    
    private var runningTasks: [PersistentIdentifier: Task<Void, Error>] = [:]
    
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
        hideSideView = false
        
        let batchJob: BatchJob
        if let fileBatchJob = file.batchJob {
            batchJob = fileBatchJob
        } else {
            batchJob = BatchJob(batchFile: file)
            file.batchJob = batchJob
            try modelContext.save()
        }
        
        runningBatchJob = batchJob
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
        
        runningTasks[batchJobID] = task
        
        Task { @MainActor in
            _ = await task.result
            runningTasks.removeValue(forKey: batchJobID)
        }
    }
    
    func cancelJob(for batchJobID: PersistentIdentifier) {
        runningTasks[batchJobID]?.cancel()
        runningTasks.removeValue(forKey: batchJobID)
    }
    
    func cancelAllJobs() {
        for task in runningTasks.values {
            task.cancel()
        }
        runningTasks.removeAll()
    }
    
    var hasRunningTasks: Bool {
        !runningTasks.isEmpty
    }
}
