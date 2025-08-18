//
//  FileStatusView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/18/25.
//

import SwiftUI

struct BatchFileJobStatusView: View {
    
    let batchJob: BatchJob
    
    var body: some View {
        switch batchJob.jobStatus {
        case .notStarted:
            fileCaptionMessageView(text: "File ready. Click play to upload and start batch processing")
        case .fileUploaded:
            fileUploadedDetailView
        case .pending:
            jobActiveDetailView(statusMessage: "Batch job queued and waiting to start")
        case .running:
            jobActiveDetailView(statusMessage: "Batch job is currently running")
        case .succeeded:
            jobSucceededDetailView
        case .jobFileDownloaded:
            fileDownloadedView
        case .unspecified:
            fileIssueDetailView(
                text: "Job status unknown. Please check the job details or retry.",
                iconName: "questionmark.circle.fill"
            )
        case .failed:
            fileIssueDetailView(
                text: "Job failed. Review the error details and retry with corrections.",
                iconName: "xmark.circle.fill"
            )
        case .cancelled:
            fileIssueDetailView(
                text: "Job was cancelled. Click retry to start a new batch job.",
                iconName: "stop.circle.fill"
            )
        case .expired:
            fileIssueDetailView(
                text: "Job expired after 48 hours. Click play to start a new job.",
                iconName: "timer.circle.fill"
            )
        }
    }
}

extension BatchFileJobStatusView {
    @ViewBuilder
    private var fileUploadedDetailView: some View {
        VStack(alignment: .leading, spacing: 6) {
            fileCaptionMessageView(text: "File successfully uploaded to Gemini")
            if let geminiFileName = batchJob.batchFile.geminiFileName {
                fileNameView(geminiFileName)
            }
        }
    }
    
    @ViewBuilder
    private func jobActiveDetailView(statusMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fileCaptionMessageView(text: statusMessage)
            
            if let geminiFileName = batchJob.batchFile.geminiFileName {
                fileNameView(geminiFileName)
            }
            
            if let batchJobName = batchJob.geminiJobName {
                jobNameView(batchJobName)
            }
        }
    }
    
    private var jobSucceededDetailView: some View {
        VStack(alignment: .leading, spacing: 6) {
            fileCaptionMessageView(text: "Batch job completed successfully! Results ready to download.")
            
            if let batchJobName = batchJob.geminiJobName {
                jobNameView(batchJobName)
            }
            if let resultPath = batchJob.batchFile.resultPath {
                resultPathView(resultPath)
            }
        }
    }
    
    @ViewBuilder
    private func fileIssueDetailView(
        text: String,
        iconName: String
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .foregroundColor(.red)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var fileDownloadedView: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            fileCaptionMessageView(
                text: "Job completed successfully! Results are ready to download."
            )
            
            if let geminiModel = GeminiModel(
                rawValue: batchJob.batchFile.project.geminiModel),
               let totalTokenCount = batchJob.totalTokenCount,
               let promptTokenCount = batchJob.promptTokenCount,
               let thoughtsTokenCount = batchJob.thoughtsTokenCount,
               let candidatesTokenCount = batchJob.candidatesTokenCount {
                
                TokenResultsView(
                    geminiModel: geminiModel,
                    totalTokenCount: totalTokenCount,
                    promptTokenCount: promptTokenCount,
                    thoughtsTokenCount: thoughtsTokenCount,
                    candidatesTokenCount: candidatesTokenCount
                )
            }
        }
    }
}

extension BatchFileJobStatusView {
    @ViewBuilder
    private func fileCaptionMessageView(
        text: String,
        color: Color? = nil
    ) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(color != nil ? color : .secondary)
    }
    
    @ViewBuilder
    private func fileNameView(_ name: String) -> some View {
        HStack(spacing: 8) {
            fileCaptionMessageView(text: "Gemini File Name:")
            CopyLinkView(
                copyContent: name,
                helpText: "Copy Gemini file name",
                successMessage: "Gemini file name copied to clipboard"
            )
            
            if let fileExpirationText = batchJob.batchFile.geminiFileExpirationTimeRemaining {
                fileCaptionMessageView(text: fileExpirationText, color: .orange)
            }
        }
    }
    
    @ViewBuilder
    private func jobNameView(_ name: String) -> some View {
        HStack(spacing: 8) {
            fileCaptionMessageView(text: "Gemini Batch Job Name:")
            CopyLinkView(
                copyContent: name,
                helpText: "Copy Gemini batch job name",
                successMessage: "Gemini batch job name copied to clipboard"
            )
        }
    }
    
    @ViewBuilder
    private func resultPathView(_ path: String) -> some View {
        HStack(spacing: 8) {
            fileCaptionMessageView(text: "Gemini Batch Job Result Path:")
            CopyLinkView(
                copyContent: path,
                helpText: "Copy Gemini results path",
                successMessage: "Gemini results path copied to clipboard"
            )
            
            if let jobExpirationText = batchJob.expirationTimeRemaining {
                fileCaptionMessageView(text: jobExpirationText, color: .orange)
            }
        }
    }
}

