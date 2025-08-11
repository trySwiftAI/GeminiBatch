//
//  BatchJobManager.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/10/25.
//

@preconcurrency import AIProxy
import Foundation
import SwiftData

class BatchJobManager {
    
    private var geminiService: GeminiService
    private var geminiModel: GeminiModel
    private var batchJobID: PersistentIdentifier
    private var batchJobActor: BatchJobActor
    
    init(
        geminiAPIKey: String,
        geminiModel: GeminiModel,
        batchJobID: PersistentIdentifier,
        modelContainer: ModelContainer
    ) {
        geminiService = AIProxy.geminiDirectService(
                 unprotectedAPIKey: geminiAPIKey
        )
        self.geminiModel = geminiModel
        self.batchJobID = batchJobID
        self.batchJobActor = BatchJobActor(modelContainer: modelContainer)
    }
    
    func updateGeminiAPIKey(_ geminiAPIKey: String) {
        geminiService = AIProxy.geminiDirectService(
                 unprotectedAPIKey: geminiAPIKey
        )
    }
    
    func updateGeminiModel(_ geminiModel: GeminiModel) {
        self.geminiModel = geminiModel
    }
    
    nonisolated func run() async throws {
        while true {
            let batchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
            guard let batchJobInfo else {
                throw BatchJobError.batchJobCouldNotBeFetched
            }
            
            switch batchJobInfo.jobStatus {
            case .notStarted, .failed, .cancelled, .expired:
                try await uploadFile()
            case .fileUploaded:
                try await startBatchJob()
            case .pending, .running, .unspecified:
                try await pollBatchJobStatus()
            case .succeeded:
                try await downloadBatchResult()
                return
            case .jobFileDownloaded:
                return
            }
        }
    }
}

extension BatchJobManager {
    
    nonisolated private func uploadFile() async throws {
        let batchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let batchJobInfo else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        let fileURL = batchJobInfo.batchFileStoredURL
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw BatchJobError.fileNotStored
        }
        let fileData = try Data(contentsOf: fileURL)
        
        let geminiFile: GeminiFile = try await geminiService.uploadFile(
            fileData: fileData,
            mimeType: "application/jsonl"
        )
        let geminiFileActive: GeminiFile = try await geminiService.pollForFileUploadComplete(fileURL: geminiFile.uri)
        
        try await batchJobActor.updateBatchJobAndFile(id: batchJobID, from: geminiFileActive)
    }
    
    nonisolated private func startBatchJob() async throws {
        let batchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let batchJobInfo else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        if batchJobInfo.geminiFileURI == nil || batchJobInfo.isGeminiFileExpired || batchJobInfo.geminiFileStatus == .failed {
            try await uploadFile()
        }
        
        // Refresh batch job info after potential file upload
        let updatedBatchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let updatedBatchJobInfo else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        guard let geminiFileName = updatedBatchJobInfo.geminiFileURI else {
            throw BatchJobError.fileCouldNotBeUploaded
        }
        
        let displayName = updatedBatchJobInfo.displayJobName
        let geminiBatchJobBody: GeminiBatchRequestBody = .init(
            fileName: geminiFileName.absoluteString,
            displayName: displayName
        )
        let response: GeminiBatchResponseBody = try await geminiService.createBatchJob(
            body: geminiBatchJobBody,
            model: geminiModel.rawValue
        )
        
        try await batchJobActor.updateBatchJobFromResponse(id: batchJobID, response: response)
    }
    
    nonisolated private func pollBatchJobStatus() async throws {
        let batchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let batchJobInfo else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        if batchJobInfo.jobStatus == .succeeded {
            return
        }
        
        guard let batchJobName = batchJobInfo.geminiJobName else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        let response = try await geminiService.pollForBatchJobComplete(batchJobName: batchJobName)
        
        if let responseState = response.state {
            let status = BatchJobStatus(from: responseState)
            try await batchJobActor.updateBatchJobStatus(id: batchJobID, status: status)
        }
    }
    
    nonisolated private func getBatchJobStatus() async throws {
        let batchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let batchJobInfo else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        if batchJobInfo.geminiJobName == nil {
            try await startBatchJob()
        }
        
        // Refresh batch job info after potential job start
        let updatedBatchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let updatedBatchJobInfo else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        guard let batchJobName = updatedBatchJobInfo.geminiJobName else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        let response: GeminiBatchResponseBody = try await geminiService.getBatchJobStatus(batchJobName: batchJobName)
        if let responseState = response.state {
            let status = BatchJobStatus(from: responseState)
            try await batchJobActor.updateBatchJobStatus(id: batchJobID, status: status)
        }
    }
    
    nonisolated private func downloadBatchResult() async throws {
        let batchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let batchJobInfo else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        if batchJobInfo.geminiJobName == nil {
            try await startBatchJob()
        }
        
        // Refresh batch job info after potential job start
        let updatedBatchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let updatedBatchJobInfo else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        guard let batchJobName = updatedBatchJobInfo.geminiJobName else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        guard updatedBatchJobInfo.jobStatus == .succeeded else {
            throw BatchJobError.batchJobNotCompleted
        }
        
        let batchResultsData = try await geminiService.downloadBatchResults(responsesFileName: batchJobName)
        try await batchJobActor.saveResult(id: batchJobID, data: batchResultsData)
    }
}

enum BatchJobError: Error, Identifiable, Equatable, LocalizedError {
    case fileNotStored
    case fileReadError(String)
    case fileCouldNotBeUploaded
    case batchJobCouldNotBeFetched
    case batchJobNotCompleted
    
    var id: String {
        switch self {
        case .fileNotStored:
            return "fileNotStored"
        case .fileReadError(let message):
            return "fileReadError_\(message)"
        case .fileCouldNotBeUploaded:
            return "fileCouldNotBeUploaded"
        case .batchJobCouldNotBeFetched:
            return "batchJobCouldNotBeFetched"
        case .batchJobNotCompleted:
            return "batchJobNotCompleted"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .fileNotStored:
            return "The file is not stored locally and cannot be uploaded."
        case .fileReadError(let message):
            return "Failed to read file: \(message)"
        case .fileCouldNotBeUploaded:
            return "Failed to upload the file to Gemini. Please try again"
        case .batchJobCouldNotBeFetched:
            return "Batch job could not be fetched. Please try again"
        case .batchJobNotCompleted:
            return "Batch job has not yet succeeded, so the file cannot be downloaded"
        }
    }
}
