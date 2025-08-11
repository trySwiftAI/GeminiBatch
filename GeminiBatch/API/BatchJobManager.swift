//
//  BatchJobManager.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/10/25.
//

import AIProxy
import Foundation
import SwiftData

@Observable
class BatchJobManager {
    
    private var geminiService: GeminiService
    private var geminiModel: GeminiModel
    var batchJob: BatchJob
    
    init(
        geminiAPIKey: String,
        geminiModel: GeminiModel,
        batchJob: BatchJob
    ) {
        geminiService = AIProxy.geminiDirectService(
                 unprotectedAPIKey: geminiAPIKey
        )
        self.geminiModel = geminiModel
        self.batchJob = batchJob
    }
    
    func updateGeminiAPIKey(_ geminiAPIKey: String) {
        geminiService = AIProxy.geminiDirectService(
                 unprotectedAPIKey: geminiAPIKey
        )
    }
    
    func updateGeminiModel(_ geminiModel: GeminiModel) {
        self.geminiModel = geminiModel
    }
    
    func run() async throws {
        switch batchJob.jobStatus {
        case .notStarted, .failed, .cancelled, .expired:
            try await uploadFile()
            try await startBatchJob()
            try await pollBatchJobStatus()
        case .fileUploaded:
            try await startBatchJob()
            try await pollBatchJobStatus()
        case .pending, .running:
            try await pollBatchJobStatus()
        case .succeeded:
            try await pollBatchJobStatus()
        case .jobFileDownloaded:
            return
        case .unspecified:
            return
        }
    }
}

extension BatchJobManager {
    
    private func uploadFile() async throws {
        let fileURL = batchJob.batchFile.storedURL
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw BatchJobError.fileNotStored
        }
        let fileData = try Data(contentsOf: fileURL)
        
        let geminiFile: GeminiFile = try await geminiService.uploadFile(
            fileData: fileData,
            mimeType: "application/jsonl"
        )
        let geminiFileActive: GeminiFile = try await geminiService.pollForFileUploadComplete(fileURL: geminiFile.uri)
        
        await MainActor.run {
            updateBatchJobAndFile(from: geminiFileActive)
        }
    }
    
    private func updateBatchJobAndFile(from geminiFile: GeminiFile) {
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
        
        batchJob.batchFile.geminiFileURI = geminiFile.uri
        batchJob.batchFile.geminiFileCreatedAt = createdDate
        batchJob.batchFile.geminiFileExpirationTime = expirationDate
        batchJob.batchFile.geminiFileStatus = BatchFileStatus(from: geminiFile.state)
        batchJob.jobStatus = .fileUploaded
    }
    
    private func startBatchJob() async throws {
        if batchJob.batchFile.geminiFileURI == nil || batchJob.batchFile.isGeminiFileExpired || batchJob.batchFile.geminiFileStatus == .failed {
            try await uploadFile()
        }
        
        guard let geminiFileName = batchJob.batchFile.geminiFileURI else {
            throw BatchJobError.fileCouldNotBeUploaded
        }
        
        let geminiBatchJobBody: GeminiBatchRequestBody = .init(
            fileName: geminiFileName.absoluteString,
            displayName: batchJob.displayJobName
        )
        let response: GeminiBatchResponseBody = try await geminiService.createBatchJob(
            body: geminiBatchJobBody,
            model: geminiModel.rawValue
        )
        
        await MainActor.run {
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
        }
    }
    
    private func pollBatchJobStatus() async throws {
        if batchJob.jobStatus == .succeeded {
            return
        }
        
        guard let batchJobName = batchJob.geminiJobName else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        let response = try await geminiService.pollForBatchJobComplete(batchJobName: batchJobName)
        
        await MainActor.run {
            if let responseState = response.state {
                batchJob.jobStatus = BatchJobStatus(from: responseState)
            }
        }
    }
    
    
    private func getBatchJobStatus() async throws {
        if batchJob.geminiJobName == nil {
            try await startBatchJob()
        }
        
        guard let batchJobName = batchJob.geminiJobName else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        let response: GeminiBatchResponseBody = try await geminiService.getBatchJobStatus(batchJobName: batchJobName)
        await MainActor.run {
            if let responseState = response.state {
                batchJob.jobStatus = BatchJobStatus(from: responseState)
            }
        }
    }
    
    private func downloadBatchResult() async throws {
        if batchJob.geminiJobName == nil {
            try await startBatchJob()
        }
        
        guard let batchJobName = batchJob.geminiJobName else {
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        guard batchJob.jobStatus == .succeeded else {
            throw BatchJobError.batchJobNotCompleted
        }
        
        let batchResultsData = try await geminiService.downloadBatchResults(responsesFileName: batchJobName)
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
