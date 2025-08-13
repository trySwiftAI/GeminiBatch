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
    
    private var geminiAPIKey: String
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
        self.geminiAPIKey = geminiAPIKey
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
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID, 
                message: "Failed to fetch batch job information. Please retry the operation.",
                type: .error
            )
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        try await batchJobActor.addBatchJobMessage(
            id: batchJobID,
            message: "Uploading file \(batchJobInfo.batchFileName) to Gemini...",
            type: .pending
        )
        
        let fileURL = batchJobInfo.batchFileStoredURL
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID, 
                message: "File not found locally. Please ensure the file is properly stored and retry.",
                type: .error
            )
            throw BatchJobError.fileNotStored
        }
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            
            let geminiFile: GeminiFile = try await geminiService.uploadFile(
                fileData: fileData,
                mimeType: "application/jsonl"
            )
            
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID,
                message: "File uploaded successfully. Waiting for Gemini to process...",
                type: .pending
            )
            
            let geminiFileActive: GeminiFile = try await geminiService.pollForFileUploadComplete(fileURL: geminiFile.uri)
            
            try await batchJobActor.updateBatchJobAndFile(id: batchJobID, from: geminiFileActive)
            
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID,
                message: "File uploaded and processed successfully. Gemini File Name: \(geminiFile.uri.absoluteString)",
                type: .success
            )
        } catch {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID, 
                message: "Failed to upload file to Gemini: \(error.localizedDescription)",
                type: .error
            )
            throw error
        }
    }
    
    nonisolated private func startBatchJob() async throws {
        try await batchJobActor.addBatchJobMessage(
            id: batchJobID,
            message: "Starting batch job with Gemini...",
            type: .pending
        )
        
        let batchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let batchJobInfo else {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID, 
                message: "Failed to fetch batch job information. Please retry the operation.",
                type: .error
            )
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        if batchJobInfo.geminiFileURI == nil || batchJobInfo.isGeminiFileExpired || batchJobInfo.geminiFileStatus == .failed {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID,
                message: "File needs to be re-uploaded before starting batch job...",
                type: .pending
            )
            try await uploadFile()
        }
        
        let updatedBatchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let updatedBatchJobInfo else {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID, 
                message: "Failed to fetch updated batch job information. Please retry the operation.",
                type: .error
            )
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        guard let geminiFileName = updatedBatchJobInfo.geminiFileName else {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID, 
                message: "File upload failed - no Gemini file available. Please retry the upload.",
                type: .error
            )
            throw BatchJobError.fileCouldNotBeUploaded
        }
        
        do {
            let displayName = updatedBatchJobInfo.displayJobName
//            let geminiBatchJobBody: GeminiBatchRequestBody = .init(
//                fileURI: geminiFileURI,
//                displayName: displayName
//            )
            let geminiService = await GeminiClient(
                apiKey: geminiAPIKey,
                model: geminiModel.rawValue,
                displayName: displayName
                )
            
            let response = try await geminiService.createBatchJob(fileId: geminiFileName)
                
//                let response: GeminiBatchResponseBody = try await geminiService.createBatchJob(
//                    body: geminiBatchJobBody,
//                    model: geminiModel.rawValue
//                )
//                if let responseString = String(data: response.data, encoding: .utf8) {
//                    print("Raw JSON Response:")
//                    print(responseString)
//                }
                
                try await batchJobActor.updateBatchJobFromResponse(id: batchJobID, response: response)
                
                try await batchJobActor.addBatchJobMessage(
                    id: batchJobID,
                    message: "Batch job started successfully. Job Name: \(response.name). Status: \(response.state?.rawValue ?? "pending")",
                    type: .success
                )
            
            
        } catch {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID, 
                message: "Failed to start batch job: \(String(describing: error))",
                type: .error
            )
            throw error
        }
    }
    
    nonisolated private func pollBatchJobStatus() async throws {
        let batchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let batchJobInfo else {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID, 
                message: "Failed to fetch batch job information during status check. Please retry.",
                type: .error
            )
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        if batchJobInfo.jobStatus == .succeeded {
            return
        }
        
        guard let batchJobName = batchJobInfo.geminiJobName else {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID, 
                message: "No batch job name available for status polling. Please restart the batch job.",
                type: .error
            )
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        try await batchJobActor.addBatchJobMessage(
            id: batchJobID,
            message: "Checking batch job status...",
            type: .pending
        )
        
        do {
            let response = try await geminiService.pollForBatchJobComplete(batchJobName: batchJobName)
            print("RESPONSE: \(response)")
            print(String(describing: response.state))
                        
            if batchJobInfo.resultsFileName == nil, let responseFile = response.response?.responsesFile {
                try await batchJobActor.updateBatchJobResult(id: batchJobID, resultsFileName: responseFile)
            }
            
            if let responseState = response.state {
                let status = BatchJobStatus(from: responseState)
                try await batchJobActor.updateBatchJobStatus(id: batchJobID, status: status)
                
                // Add status update message
                switch status {
                case .pending:
                    try await batchJobActor.addBatchJobMessage(
                        id: batchJobID,
                        message: "Batch job is pending - waiting to be processed by Gemini...",
                        type: .pending
                    )
                case .running:
                    try await batchJobActor.addBatchJobMessage(
                        id: batchJobID,
                        message: "Batch job is running - Gemini is processing your requests...",
                        type: .pending
                    )
                case .succeeded:
                    try await batchJobActor.addBatchJobMessage(
                        id: batchJobID,
                        message: "Batch job completed successfully! Ready to download results.",
                        type: .success
                    )
                case .failed:
                    try await batchJobActor.addBatchJobMessage(
                        id: batchJobID,
                        message: "Batch job failed. Please check your input file format and retry with a new job.",
                        type: .error
                    )
                case .cancelled:
                    try await batchJobActor.addBatchJobMessage(
                        id: batchJobID,
                        message: "Batch job was cancelled. You can retry with a new job if needed.",
                        type: .error
                    )
                case .expired:
                    try await batchJobActor.addBatchJobMessage(
                        id: batchJobID,
                        message: "Batch job expired after 48 hours. Please create a new job to retry.",
                        type: .error
                    )
                default:
                    try await batchJobActor.addBatchJobMessage(
                        id: batchJobID,
                        message: "Batch job status: \(responseState)",
                        type: .pending
                    )
                }
            }
        } catch {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID, 
                message: "Failed to check batch job status: \(error.localizedDescription). Will retry automatically.",
                type: .error
            )
            throw error
        }
    }

    nonisolated private func downloadBatchResult() async throws {
        try await batchJobActor.addBatchJobMessage(
            id: batchJobID,
            message: "Downloading batch job results...",
            type: .pending
        )
        
        let batchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let batchJobInfo else {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID, 
                message: "Failed to fetch batch job information for download. Please retry.",
                type: .error
            )
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        if batchJobInfo.geminiJobName == nil {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID,
                message: "No job name available, attempting to start batch job first...",
                type: .pending
            )
            try await startBatchJob()
        }
        
        // Refresh batch job info after potential job start
        let updatedBatchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let updatedBatchJobInfo else {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID, 
                message: "Failed to fetch updated batch job information for download. Please retry.",
                type: .error
            )
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        guard let batchJobName = updatedBatchJobInfo.geminiJobName else {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID, 
                message: "No batch job name available for download. Please restart the batch job.",
                type: .error
            )
            throw BatchJobError.batchJobCouldNotBeFetched
        }
        
        guard updatedBatchJobInfo.jobStatus == .succeeded else {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID, 
                message: "Batch job has not succeeded yet (current status: \(updatedBatchJobInfo.jobStatus)). Cannot download results until job completes successfully.",
                type: .error
            )
            throw BatchJobError.batchJobNotCompleted
        }
        
        do {
            // Create GeminiClient for file download
            let geminiClient = await GeminiClient(
                apiKey: geminiAPIKey,
                model: geminiModel.rawValue,
                displayName: updatedBatchJobInfo.displayJobName
            )
            
            
            guard let resultsFileName = updatedBatchJobInfo.resultsFileName else {
                try await batchJobActor.addBatchJobMessage(
                    id: batchJobID,
                    message: "The batch results file in unavailable. Will attempt to retry.",
                    type: .error
                )
                try await pollBatchJobStatus() // TODO GET IMMEDIATE STATUS, no need to poll
                throw BatchJobError.resultsFileNotStored
            }
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID,
                message: "Attempting to download results for batch results file: \(resultsFileName)",
                type: .pending
            )
            
            // Use the new GeminiClient download method instead of AIProxy
            let batchResultsData = try await geminiClient.downloadFile(fileName: resultsFileName)
            try await batchJobActor.saveResult(id: batchJobID, data: batchResultsData)
            
            let resultSize = ByteCountFormatter.string(fromByteCount: Int64(batchResultsData.count), countStyle: .file)
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID,
                message: "Results downloaded successfully! File size: \(resultSize). Batch job complete.",
                type: .success
            )
        } catch let geminiError as GeminiBatchError {
            // Handle GeminiBatchError from our custom client
            let errorMessage = switch geminiError {
            case .invalidResponse:
                "Invalid response from Gemini API"
            case .httpError(let statusCode):
                "HTTP \(statusCode) error from Gemini API"
            case .decodingError(let error):
                "Failed to decode response: \(error.localizedDescription)"
            case .apiError(let message, let code):
                "Gemini API Error (\(code)): \(message)"
            }
            
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID, 
                message: "Failed to download batch results: \(errorMessage). Please check your connection and retry.",
                type: .error
            )
            throw geminiError
        } catch {
            // Handle other errors
            let errorDescription = String(describing: error)
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID, 
                message: "Failed to download batch results: \(errorDescription). Please check your connection and retry.",
                type: .error
            )
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
    case resultsFileNotStored
    
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
        case .resultsFileNotStored:
            return "resultsFileNotStored"
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
        case .resultsFileNotStored:
            return "Results file name not stored."
        }
    }
}
