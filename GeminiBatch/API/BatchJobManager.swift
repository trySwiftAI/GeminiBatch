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
    
    nonisolated struct BatchResultResponse: Decodable, Sendable {
      let response: GeminiGenerateContentResponseBody
    }
    
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
            try await handleError(error, fallbackMessage: "Failed to upload file to Gemini")
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
        
        if batchJobInfo.geminiFileURI == nil || batchJobInfo.isGeminiFileExpired || batchJobInfo.geminiFileStatus == nil {
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
        
        let geminiBatchJobBody: GeminiBatchRequestBody = .init(
            fileName: geminiFileName,
            displayName: updatedBatchJobInfo.displayJobName
        )
        
        do {
            let response: GeminiBatchResponseBody = try await geminiService.createBatchJob(
                body: geminiBatchJobBody,
                model: geminiModel.rawValue
            )
            
            try await batchJobActor.updateBatchJobFromResponse(id: batchJobID, response: response)
            
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID,
                message: "Batch job started successfully. Job Name: \(response.name). Status: \(response.state?.rawValue ?? "pending")",
                type: .success
            )
        } catch {
            try await handleError(error, fallbackMessage: "Failed to start batch job")
        }
    }
    
    nonisolated private func getJobStatus() async throws {
        let batchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let batchJobInfo else {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID,
                message: "Failed to fetch batch job information during status check. Please retry.",
                type: .error
            )
            throw BatchJobError.batchJobCouldNotBeFetched
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
            let response = try await geminiService.getBatchJobStatus(batchJobName: batchJobName)
            
            try await processJobStatus(
                fromResponse: response,
                forBatchJob: batchJobInfo
            )
        } catch {
            try await handleError(error, fallbackMessage: "Failed to get job status")
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
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID,
                message: "The batch job has succeeded!",
                type: .success
            )
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
            message: "Checking batch job status in 5 minutes...",
            type: .pending
        )
        
        do {
            let response = try await geminiService.pollForBatchJobComplete(batchJobName: batchJobName)
                        
            try await processJobStatus(
                fromResponse: response,
                forBatchJob: batchJobInfo
            )
        } catch {
            try await handleError(error, fallbackMessage: "Failed to get batch job status")
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
        
        let updatedBatchJobInfo = await batchJobActor.getBatchJobInfo(id: batchJobID)
        guard let updatedBatchJobInfo else {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID, 
                message: "Failed to fetch updated batch job information for download. Please retry.",
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
            guard let resultsFileName = updatedBatchJobInfo.resultsFileName else {
                try await batchJobActor.addBatchJobMessage(
                    id: batchJobID,
                    message: "The batch results file in unavailable. Will attempt to retry.",
                    type: .error
                )
                try await getJobStatus()
                throw BatchJobError.resultsFileNotStored
            }
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID,
                message: "Attempting to download results for batch results file: \(resultsFileName)",
                type: .pending
            )

            let batchResultsData = try await geminiService.downloadBatchResults(responsesFileName: resultsFileName)
            
            // Save results and parse token counts in parallel
            async let saveResultTask: Void = batchJobActor.saveResult(id: batchJobID, data: batchResultsData)
            async let parseTokenCounts = parseTokenCounts(from: batchResultsData)
                    
            _ = try await saveResultTask
            let parsedTokenCounts = await parseTokenCounts
            
            try await batchJobActor.updateTokenCounts(
                id: batchJobID,
                totalTokenCount: parsedTokenCounts.totalTokenCount,
                thoughtsTokenCount: parsedTokenCounts.thoughtsTokenCount,
                promptTokenCount: parsedTokenCounts.promptTokenCount,
                candidatesTokenCount: parsedTokenCounts.candidatesTokenCount
            )
            
            let resultSize: String = ByteCountFormatter.string(fromByteCount: Int64(batchResultsData.count), countStyle: .file)
            try await sendResultsDownloadedMessage(
                resultFileSize: resultSize,
                tokenCounts: parsedTokenCounts
            )
            
        } catch {
            try await handleError(error, fallbackMessage: "Failed to download batch results")
        }
    }
}

extension BatchJobManager {
    
    nonisolated private func processJobStatus(
        fromResponse response: GeminiBatchResponseBody,
        forBatchJob batchJobInfo: BatchJobActor.BatchJobInfo
    ) async throws {
        if batchJobInfo.resultsFileName == nil, let responseFile = response.response?.responsesFile {
            try await batchJobActor.updateBatchJobResult(id: batchJobID, resultsFileName: responseFile)
        }
        
        if let responseState = response.state {
            let status = BatchJobStatus(from: responseState)
            try await batchJobActor.updateBatchJobStatus(id: batchJobID, status: status)
            
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
    }
    
    nonisolated private func parseTokenCounts(
        from data: Data
    ) -> (
        totalTokenCount: Int?,
        thoughtsTokenCount: Int?,
        promptTokenCount: Int?,
        candidatesTokenCount: Int?
    ) {
        var totalTokenCount: Int?
        var thoughtsTokenCount: Int?
        var promptTokenCount: Int?
        var candidatesTokenCount: Int?
        
        guard let jsonlString = String(data: data, encoding: .utf8) else {
            return (nil, nil, nil, nil)
        }
        
        let lines = jsonlString.components(separatedBy: .newlines)
        let decoder = JSONDecoder()
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }
            
            guard let lineData = trimmedLine.data(using: .utf8) else { continue }
            
            do {
                let response = try decoder.decode(BatchResultResponse.self, from: lineData)

                if let usageMetadata = response.response.usageMetadata {
                    totalTokenCount = usageMetadata.totalTokenCount ?? nil
                    thoughtsTokenCount = usageMetadata.thoughtsTokenCount ?? nil
                    promptTokenCount = usageMetadata.promptTokenCount ?? nil
                    candidatesTokenCount = usageMetadata.candidatesTokenCount ?? nil
                    
                    // Stop parsing if we have all the required metadata
                    if usageMetadata.totalTokenCount != nil &&
                       usageMetadata.thoughtsTokenCount != nil &&
                       usageMetadata.promptTokenCount != nil &&
                       usageMetadata.candidatesTokenCount != nil {
                        break
                    }
                }
            } catch {
                // Continue processing other lines even if one fails to parse
                continue
            }
        }
        return (totalTokenCount, thoughtsTokenCount, promptTokenCount, candidatesTokenCount)
    }
    
    nonisolated private func sendResultsDownloadedMessage(
        resultFileSize: String,
        tokenCounts: (
            totalTokenCount: Int?,
            thoughtsTokenCount: Int?,
            promptTokenCount: Int?,
            candidatesTokenCount: Int?
        )
    ) async throws {
        guard let totalTokenCount = tokenCounts.totalTokenCount,
              let thoughtsTokenCount = tokenCounts.thoughtsTokenCount,
              let promptTokenCount = tokenCounts.promptTokenCount,
              let candidatesTokenCount = tokenCounts.candidatesTokenCount else {
            try await batchJobActor
                .updateBatchJobStatusMessage(
                    id: batchJobID,
                    statusMessage: "Results downloaded successfully! File size: \(resultFileSize). Sorry, couldn't extract the number of tokens from the file",
                    type: .success
                )
            return
        }
        
        let message = """
            Results downloaded successfully! File size: \(resultFileSize).
            
            Token usage: 
            Total - \(totalTokenCount)
            Input Tokens - \(promptTokenCount)
            Thought Output Tokens - \(thoughtsTokenCount)
            Output Tokens - \(candidatesTokenCount)
            """
        try await batchJobActor
            .updateBatchJobStatusMessage(
                id: batchJobID,
                statusMessage: message,
                type: .success
            )
    }
}

extension BatchJobManager {
    
    nonisolated private func handleError(
        _ error: Error,
        fallbackMessage: String
    ) async throws {
        if let aiProxyError = error as? AIProxyError {
            try await handleAIProxyError(aiProxyError)
        } else {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID,
                message: "\(fallbackMessage): \(error.localizedDescription)",
                type: .error
            )
        }
        throw error
    }
    
    nonisolated private func handleAIProxyError(
        _ aiProxyError: AIProxyError
    ) async throws {
        if case AIProxyError.unsuccessfulRequest(let statusCode, let responseBody) = aiProxyError {
            let errorMessage = "Received non-200 status code: \(statusCode) with response body: \(responseBody)"
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID,
                message: errorMessage,
                type: .error
            )
        } else {
            try await batchJobActor.addBatchJobMessage(
                id: batchJobID,
                message: "Error: \(aiProxyError.localizedDescription)",
                type: .error
            )
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
