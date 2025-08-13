//
//  JobStatus.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/10/25.
//

import AIProxy

enum BatchJobStatus: String, CaseIterable, Codable, Sendable {
    case notStarted
    case fileUploaded
    case unspecified
    case pending
    case running
    case succeeded
    case failed
    case cancelled
    case expired
    case jobFileDownloaded
    
    nonisolated init(from geminiState: GeminiBatchResponseBody.BatchMetadata.State) {
        switch geminiState {
        case .unspecified:
            self = .unspecified
        case .pending:
            self = .pending
        case .running:
            self = .running
        case .succeeded:
            self = .succeeded
        case .failed:
            self = .failed
        case .cancelled:
            self = .cancelled
        case .expired:
            self = .expired
        }
    }
    
    var geminiStatusTitle: String {
        switch self {
        case .notStarted:
            return "BATCH_NOT_STARTED"
        case .fileUploaded:
            return "BATCH_FILE_UPLOADED"
        case .unspecified:
            return "BATCH_STATE_UNSPECIFIED"
        case .pending:
            return "BATCH_STATE_PENDING"
        case .running:
            return "BATCH_STATE_RUNNING"
        case .succeeded:
            return "BATCH_STATE_SUCCEEDED"
        case .failed:
            return "BATCH_STATE_FAILED"
        case .cancelled:
            return "BATCH_STATE_CANCELLED"
        case .expired:
            return "BATCH_STATE_EXPIRED"
        case .jobFileDownloaded:
            return "BATCH_FILE_SAVED"
        }
    }
    
    var description: String {
        switch self {
        case .notStarted:
            return "The job has not been started yet"
        case .fileUploaded:
            return "The batch job file has been uploaded and is ready for processing"
        case .unspecified:
            return "The job status is not specified or unknown"
        case .pending:
            return "The job has been created and is waiting to be processed by the service."
        case .running:
            return "The job is in progress."
        case .succeeded:
            return "The job completed successfully. You can now retrieve the results."
        case .failed:
            return "The job failed. Check the error details for more information."
        case .cancelled:
            return "The job was cancelled by the user."
        case .expired:
            return "The job has expired because it was running or pending for more than 48 hours. The job will not have any results to retrieve. You can try submitting the job again or splitting up the requests into smaller batches."
        case .jobFileDownloaded:
            return "The job completed successfully and the job file has been saved."
        }
    }
}