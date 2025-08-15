//
//  BatchJobActor.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/10/25.
//

@preconcurrency import AIProxy
import Foundation
import SwiftData

@ModelActor
actor BatchJobActor {
    
    func fetchBatchJob(id: PersistentIdentifier) -> BatchJob? {
        return modelContext.model(for: id) as? BatchJob
    }
    
    func updateBatchJobAndFile(
        id: PersistentIdentifier,
        from geminiFile: GeminiFile
    ) throws {
        guard let batchJob = modelContext.model(for: id) as? BatchJob else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        let createdDate: Date
        if let geminiFileCreateTime = geminiFile.createTime {
            createdDate = DateFormatter.rfc3339.date(from: geminiFileCreateTime) ?? Date()
        } else {
            createdDate = Date()
        }

        let expirationDate: Date
        if let geminiFileExpirationTime = geminiFile.expirationTime {
            expirationDate = DateFormatter.rfc3339.date(from: geminiFileExpirationTime) ?? createdDate.addingTimeInterval(48 * 60 * 60)
        } else {
            expirationDate = createdDate.addingTimeInterval(48 * 60 * 60)
        }
        
        batchJob.batchFile.geminiFileName = geminiFile.name
        batchJob.batchFile.geminiFileURI = geminiFile.uri
        batchJob.batchFile.geminiFileCreatedAt = createdDate
        batchJob.batchFile.geminiFileExpirationTime = expirationDate
        batchJob.batchFile.geminiFileStatus = BatchFileStatus(from: geminiFile.state)
        batchJob.jobStatus = .fileUploaded
        
        try modelContext.save()
    }
    
    func updateBatchJobFromResponse(
        id: PersistentIdentifier,
        response: GeminiBatchResponseBody
    ) throws {
        guard let batchJob = modelContext.model(for: id) as? BatchJob else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        batchJob.geminiJobName = response.name
        if let responseState = response.state {
            batchJob.jobStatus = BatchJobStatus(from: responseState)
        } else {
            batchJob.jobStatus = .pending
        }
        if let batchCreatedTime = response.createTime {
            batchJob.startedAt = DateFormatter.rfc3339.date(from: batchCreatedTime) ?? Date()
        } else {
            batchJob.startedAt = Date()
        }
        
        try modelContext.save()
    }
    
    func updateBatchJobStatus(
        id: PersistentIdentifier,
        status: BatchJobStatus
    ) throws {
        guard let batchJob = modelContext.model(for: id) as? BatchJob else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        batchJob.jobStatus = status
        try modelContext.save()
    }
    
    func updateBatchJobResult(id: PersistentIdentifier, resultsFileName: String) throws {
        guard let batchJob = modelContext.model(for: id) as? BatchJob else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        batchJob.resultsFileName = resultsFileName
        try modelContext.save()
    }
    
    func updateTokenCounts(
        id: PersistentIdentifier,
        totalTokenCount: Int?,
        thoughtsTokenCount: Int?,
        promptTokenCount: Int?,
        candidatesTokenCount: Int?
    ) throws {
        guard let batchJob = modelContext.model(for: id) as? BatchJob else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        batchJob.totalTokenCount = totalTokenCount
        batchJob.thoughtsTokenCount = thoughtsTokenCount
        batchJob.promptTokenCount = promptTokenCount
        batchJob.candidatesTokenCount = candidatesTokenCount
        
        try modelContext.save()
    }
    
    func updateBatchJobStatusMessage(id: PersistentIdentifier, statusMessage: String, type: BatchJobMessageType) throws {
        guard let batchJob = modelContext.model(for: id) as? BatchJob else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        batchJob.addMessage(statusMessage, type: type)
        try modelContext.save()
    }
    
    func addBatchJobMessage(
        id: PersistentIdentifier,
        message: String,
        type: BatchJobMessageType
    ) throws {
        guard let batchJob = modelContext.model(for: id) as? BatchJob else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        batchJob.addMessage(message, type: type)
        try modelContext.save()
    }
    
    func getBatchJobInfo(id: PersistentIdentifier) -> BatchJobInfo? {
        guard let batchJob = modelContext.model(for: id) as? BatchJob else {
            return nil
        }
        
        return BatchJobInfo(
            batchFileName: batchJob.batchFile.name,
            jobStatus: batchJob.jobStatus,
            geminiJobName: batchJob.geminiJobName,
            displayJobName: batchJob.displayJobName,
            geminiFileName: batchJob.batchFile.geminiFileName,
            geminiFileURI: batchJob.batchFile.geminiFileURI,
            isGeminiFileExpired: batchJob.batchFile.isGeminiFileExpired,
            geminiFileStatus: batchJob.batchFile.geminiFileStatus,
            batchFileStoredURL: batchJob.batchFile.storedURL,
            resultsFileName: batchJob.resultsFileName
        )
    }
    
    func saveResult(id: PersistentIdentifier, data: Data) async throws {
        guard let batchJob = modelContext.model(for: id) as? BatchJob else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        let projectID = batchJob.batchFile.project.id.uuidString
        let fileManager = ProjectFileManager(projectID: projectID)
        try await fileManager
            .saveBatchFileResult(
                resultData: data,
                batchFileId: batchJob.batchFile.id,
                using: .init(
                    modelContainer: modelContainer
                )
            )
        
        // Update batch job status to indicate file has been downloaded
        batchJob.jobStatus = .jobFileDownloaded
        try modelContext.save()
    }
}
extension BatchJobActor {
    struct BatchJobInfo: Sendable {
        let batchFileName: String
        let jobStatus: BatchJobStatus
        let geminiJobName: String?
        let displayJobName: String
        let geminiFileName: String?
        let geminiFileURI: URL?
        let isGeminiFileExpired: Bool
        let geminiFileStatus: BatchFileStatus?
        let batchFileStoredURL: URL
        let resultsFileName: String?
    }
}
