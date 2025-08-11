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
            let errorMessage = "Failed to fetch batch job information. Please retry the operation."
            try await batchJobActor.updateBatchJobStatusMessage(id: batchJobID, statusMessage: errorMessage)
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        try await batchJobActor.updateBatchJobStatusMessage(
            id: batchJobID,
            statusMessage: "Uploading file \(batchJobInfo.batchFileName) to Gemini..."
        )
        
        let fileURL = batchJobInfo.batchFileStoredURL
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let errorMessage = "File not found locally. Please ensure the file is properly stored and retry."
            try await batchJobActor.updateBatchJobStatusMessage(id: batchJobID, statusMessage: errorMessage)
            throw BatchJobError.fileNotStored
        }
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            
            let geminiFile: GeminiFile = try await geminiService.uploadFile(
                fileData: fileData,
                mimeType: "application/jsonl"
            )
            
            try await batchJobActor.updateBatchJobStatusMessage(
                id: batchJobID,
                statusMessage: "File uploaded successfully. Waiting for Gemini to process..."
            )
            
            let geminiFileActive: GeminiFile = try await geminiService.pollForFileUploadComplete(fileURL: geminiFile.uri)
            
            try await batchJobActor.updateBatchJobAndFile(id: batchJobID, from: geminiFileActive)
            
            let fileName = geminiFileActive.uri.lastPathComponent
            try await batchJobActor.updateBatchJobStatusMessage(
                id: batchJobID,
                statusMessage: "File uploaded and processed successfully. Gemini File Name: \(fileName)"
            )
        } catch {
            let errorMessage = "Failed to upload file to Gemini: \(error.localizedDescription). Please check your connection and retry."
            try await batchJobActor.updateBatchJobStatusMessage(id: batchJobID, statusMessage: errorMessage)
            throw error
        }
    }
    
    nonisolated private func startBatchJob() async throws {
        try await batchJobActor.updateBatchJobStatusMessage(
            id: batchJobID,
            statusMessage: "Starting batch job with Gemini..."
        )
        
        let batchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let batchJobInfo else {
            let errorMessage = "Failed to fetch batch job information. Please retry the operation."
            try await batchJobActor.updateBatchJobStatusMessage(id: batchJobID, statusMessage: errorMessage)
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        if batchJobInfo.geminiFileURI == nil || batchJobInfo.isGeminiFileExpired || batchJobInfo.geminiFileStatus == .failed {
            try await batchJobActor.updateBatchJobStatusMessage(
                id: batchJobID,
                statusMessage: "File needs to be re-uploaded before starting batch job..."
            )
            try await uploadFile()
        }
        
        let updatedBatchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let updatedBatchJobInfo else {
            let errorMessage = "Failed to fetch updated batch job information. Please retry the operation."
            try await batchJobActor.updateBatchJobStatusMessage(id: batchJobID, statusMessage: errorMessage)
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        guard let geminiFileName = updatedBatchJobInfo.geminiFileURI else {
            let errorMessage = "File upload failed - no Gemini file URI available. Please retry the upload."
            try await batchJobActor.updateBatchJobStatusMessage(id: batchJobID, statusMessage: errorMessage)
            throw BatchJobError.fileCouldNotBeUploaded
        }
        
        do {
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
            
            try await batchJobActor.updateBatchJobStatusMessage(
                id: batchJobID,
                statusMessage: "Batch job started successfully. Job Name: \(response.name). Status: \(response.state?.rawValue ?? "pending")"
            )
        } catch {
            let errorMessage = "Failed to start batch job: \(error.localizedDescription). Please check your API key and retry."
            try await batchJobActor.updateBatchJobStatusMessage(id: batchJobID, statusMessage: errorMessage)
            throw error
        }
    }
    
    nonisolated private func pollBatchJobStatus() async throws {
        let batchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let batchJobInfo else {
            let errorMessage = "Failed to fetch batch job information during status check. Please retry."
            try await batchJobActor.updateBatchJobStatusMessage(id: batchJobID, statusMessage: errorMessage)
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        if batchJobInfo.jobStatus == .succeeded {
            return
        }
        
        guard let batchJobName = batchJobInfo.geminiJobName else {
            let errorMessage = "No batch job name available for status polling. Please restart the batch job."
            try await batchJobActor.updateBatchJobStatusMessage(id: batchJobID, statusMessage: errorMessage)
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        try await batchJobActor.updateBatchJobStatusMessage(
            id: batchJobID,
            statusMessage: "Checking batch job status..."
        )
        
        do {
            let response = try await geminiService.pollForBatchJobComplete(batchJobName: batchJobName)
            
            if let responseState = response.state {
                let status = BatchJobStatus(from: responseState)
                try await batchJobActor.updateBatchJobStatus(id: batchJobID, status: status)
                
                switch status {
                case .pending:
                    try await batchJobActor.updateBatchJobStatusMessage(
                        id: batchJobID,
                        statusMessage: "Batch job is pending - waiting to be processed by Gemini..."
                    )
                case .running:
                    try await batchJobActor.updateBatchJobStatusMessage(
                        id: batchJobID,
                        statusMessage: "Batch job is running - Gemini is processing your requests..."
                    )
                case .succeeded:
                    try await batchJobActor.updateBatchJobStatusMessage(
                        id: batchJobID,
                        statusMessage: "Batch job completed successfully! Ready to download results."
                    )
                case .failed:
                    try await batchJobActor.updateBatchJobStatusMessage(
                        id: batchJobID,
                        statusMessage: "Batch job failed. Please check your input file format and retry with a new job."
                    )
                case .cancelled:
                    try await batchJobActor.updateBatchJobStatusMessage(
                        id: batchJobID,
                        statusMessage: "Batch job was cancelled. You can retry with a new job if needed."
                    )
                case .expired:
                    try await batchJobActor.updateBatchJobStatusMessage(
                        id: batchJobID,
                        statusMessage: "Batch job expired after 48 hours. Please create a new job to retry."
                    )
                default:
                    try await batchJobActor.updateBatchJobStatusMessage(
                        id: batchJobID,
                        statusMessage: "Batch job status: \(responseState)"
                    )
                }
            }
        } catch {
            let errorMessage = "Failed to check batch job status: \(error.localizedDescription). Will retry automatically."
            try await batchJobActor.updateBatchJobStatusMessage(id: batchJobID, statusMessage: errorMessage)
            throw error
        }
    }

    nonisolated private func downloadBatchResult() async throws {
        try await batchJobActor.updateBatchJobStatusMessage(
            id: batchJobID,
            statusMessage: "Downloading batch job results..."
        )
        
        let batchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let batchJobInfo else {
            let errorMessage = "Failed to fetch batch job information for download. Please retry."
            try await batchJobActor.updateBatchJobStatusMessage(id: batchJobID, statusMessage: errorMessage)
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        if batchJobInfo.geminiJobName == nil {
            try await batchJobActor.updateBatchJobStatusMessage(
                id: batchJobID,
                statusMessage: "No job name available, attempting to start batch job first..."
            )
            try await startBatchJob()
        }
        
        let updatedBatchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let updatedBatchJobInfo else {
            let errorMessage = "Failed to fetch updated batch job information for download. Please retry."
            try await batchJobActor.updateBatchJobStatusMessage(id: batchJobID, statusMessage: errorMessage)
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        guard let batchJobName = updatedBatchJobInfo.geminiJobName else {
            let errorMessage = "No batch job name available for download. Please restart the batch job."
            try await batchJobActor.updateBatchJobStatusMessage(id: batchJobID, statusMessage: errorMessage)
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        guard updatedBatchJobInfo.jobStatus == .succeeded else {
            let errorMessage = "Batch job has not succeeded yet (current status: \(updatedBatchJobInfo.jobStatus)). Cannot download results until job completes successfully."
            try await batchJobActor.updateBatchJobStatusMessage(id: batchJobID, statusMessage: errorMessage)
            throw BatchJobError.batchJobNotCompleted
        }
        
        do {
            let batchResultsData = try await geminiService.downloadBatchResults(responsesFileName: batchJobName)
            try await batchJobActor.saveResult(id: batchJobID, data: batchResultsData)
            
            let resultSize = ByteCountFormatter.string(fromByteCount: Int64(batchResultsData.count), countStyle: .file)
            try await batchJobActor.updateBatchJobStatusMessage(
                id: batchJobID,
                statusMessage: "Results downloaded successfully! File size: \(resultSize). Batch job complete."
            )
        } catch {
            let errorMessage = "Failed to download batch results: \(error.localizedDescription). Please check your connection and retry."
            try await batchJobActor.updateBatchJobStatusMessage(id: batchJobID, statusMessage: errorMessage)
            throw error
        }
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
