//
//  FileDetailView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/8/25.
//

import SwiftUI
import SwiftData

struct FileDetailView: View {
    @Query private var batchFiles: [BatchFile]
    
    private var observedFile: BatchFile? {
        batchFiles.first
    }
    
    let file: BatchFile
    
    init(file: BatchFile) {
        self.file = file
        let fileID = file.id
        self._batchFiles = Query(filter: #Predicate { $0.id == fileID })
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            FileOverviewView(file: file)
            if let batchJob = observedFile?.batchJob {
                fileDetailView(forBatchJob: batchJob)
            }
        }
    }
}

extension FileDetailView {
    
    @ViewBuilder
    private func fileDetailView(forBatchJob batchJob: BatchJob) -> some View {
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

extension FileDetailView {
    @ViewBuilder
    private var fileUploadedDetailView: some View {
        VStack(alignment: .leading, spacing: 6) {
            fileCaptionMessageView(text: "File successfully uploaded to Gemini")
            if let geminiFileName = file.geminiFileName {
                fileNameView(geminiFileName)
            }
        }
    }
    
    @ViewBuilder
    private func jobActiveDetailView(statusMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fileCaptionMessageView(text: statusMessage)
            
            if let geminiFileName = file.geminiFileName {
                fileNameView(geminiFileName)
            }
            
            if let batchJobName = file.batchJob?.geminiJobName {
                jobNameView(batchJobName)
            }
        }
    }
    
    private var jobSucceededDetailView: some View {
        VStack(alignment: .leading, spacing: 6) {
            fileCaptionMessageView(text: "Batch job completed successfully! Results ready to download.")
            
            if let batchJobName = file.batchJob?.geminiJobName {
                jobNameView(batchJobName)
            }
            if let resultPath = file.resultPath {
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("Job completed successfully! Results are ready to download.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let batchJob = file.batchJob {
                // Token usage and cost information
                if let totalTokens = batchJob.totalTokenCount,
                   let promptTokens = batchJob.promptTokenCount,
                   let candidatesTokens = batchJob.candidatesTokenCount {
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "textformat")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("\(totalTokens.formatted()) total tokens")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Calculate and display cost
                            if let geminiModel = GeminiModel(rawValue: file.project.geminiModel) {
                                let cost = geminiModel.calculateBatchCost(
                                    inputTokens: promptTokens,
                                    outputTokens: candidatesTokens
                                )
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "dollarsign.circle")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                    Text("~\(String(format: "$%.4f", cost))")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        
                        // Breakdown of token usage
                        HStack(spacing: 12) {
                            Text("Input: \(promptTokens.formatted())")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("Output: \(candidatesTokens.formatted())")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            if let thoughtsTokens = batchJob.thoughtsTokenCount, thoughtsTokens > 0 {
                                Text("Thoughts: \(thoughtsTokens.formatted())")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(.separatorColor), lineWidth: 0.5)
                    )
                }
            }
        }
    }
}

extension FileDetailView {
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
            
            if let fileExpirationText = file.geminiFileExpirationTimeRemaining {
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
            
            if let jobExpirationText = file.batchJob?.expirationTimeRemaining {
                fileCaptionMessageView(text: jobExpirationText, color: .orange)
            }
        }
    }
}



// MARK: File Actions

#Preview {
    let project = Project(name: "Sample Project")
    let file = BatchFile(
        name: "sample_data.jsonl",
        originalURL: URL(fileURLWithPath: "/Users/example/Documents/sample_data.jsonl"),
        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/sample_data.jsonl"),
        fileSize: 2048576, // 2MB
        project: project
    )
    let batchJob = BatchJob(batchFile: file)
    batchJob.jobStatus = .fileUploaded
    file.batchJob = batchJob
    
    
    return FileDetailView(file: file)
        .environment(ToastPresenter())
        .modelContainer(
            for: [Project.self, BatchFile.self],
            inMemory: true
        )
        .frame(width: 400)
        .padding()
}

#Preview("Not Started") {
    let project = Project(name: "Sample Project")
    let file = BatchFile(
        name: "not_started.jsonl",
        originalURL: URL(fileURLWithPath: "/Users/example/Documents/not_started.jsonl"),
        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/not_started.jsonl"),
        fileSize: 1024000,
        project: project
    )
    let batchJob = BatchJob(batchFile: file)
    batchJob.jobStatus = .notStarted
    file.batchJob = batchJob
    
    return FileDetailView(file: file)
        .environment(ToastPresenter())
        .modelContainer(for: [Project.self, BatchFile.self], inMemory: true)
        .frame(width: 400)
        .padding()
}

#Preview("File Uploaded") {
    let project = Project(name: "Sample Project")
    let file = BatchFile(
        name: "uploaded_file.jsonl",
        originalURL: URL(fileURLWithPath: "/Users/example/Documents/uploaded_file.jsonl"),
        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/uploaded_file.jsonl"),
        fileSize: 2048576,
        project: project
    )
    let batchJob = BatchJob(batchFile: file)
    batchJob.jobStatus = .fileUploaded
    file.batchJob = batchJob
    file.geminiFileName = "gemini_path_to_file"
    file.geminiFileExpirationTime = Date.now.addingTimeInterval(2 * 3600)


    
    return FileDetailView(file: file)
        .environment(ToastPresenter())
        .modelContainer(for: [Project.self, BatchFile.self], inMemory: true)
        .frame(width: 400)
        .padding()
}

#Preview("Pending") {
    let project = Project(name: "Sample Project")
    let file = BatchFile(
        name: "pending_job.jsonl",
        originalURL: URL(fileURLWithPath: "/Users/example/Documents/pending_job.jsonl"),
        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/pending_job.jsonl"),
        fileSize: 3145728,
        project: project
    )
    let batchJob = BatchJob(batchFile: file)
    batchJob.jobStatus = .pending
    file.batchJob = batchJob
    
    return FileDetailView(file: file)
        .environment(ToastPresenter())
        .modelContainer(for: [Project.self, BatchFile.self], inMemory: true)
        .frame(width: 400)
        .padding()
}

#Preview("Running") {
    let project = Project(name: "Sample Project")
    let file = BatchFile(
        name: "running_batch.jsonl",
        originalURL: URL(fileURLWithPath: "/Users/example/Documents/running_batch.jsonl"),
        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/running_batch.jsonl"),
        fileSize: 5242880,
        project: project
    )
    let batchJob = BatchJob(batchFile: file)
    batchJob.jobStatus = .running
    file.batchJob = batchJob
    
    return FileDetailView(file: file)
        .environment(ToastPresenter())
        .modelContainer(for: [Project.self, BatchFile.self], inMemory: true)
        .frame(width: 400)
        .padding()
}

#Preview("Succeeded") {
    let project = Project(name: "Sample Project")
    let file = BatchFile(
        name: "completed_job.jsonl",
        originalURL: URL(fileURLWithPath: "/Users/example/Documents/completed_job.jsonl"),
        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/completed_job.jsonl"),
        fileSize: 4194304,
        project: project
    )
    let batchJob = BatchJob(batchFile: file)
    batchJob.jobStatus = .succeeded
    file.batchJob = batchJob
    
    return FileDetailView(file: file)
        .environment(ToastPresenter())
        .modelContainer(for: [Project.self, BatchFile.self], inMemory: true)
        .frame(width: 400)
        .padding()
}

#Preview("Failed") {
    let project = Project(name: "Sample Project")
    let file = BatchFile(
        name: "failed_batch.jsonl",
        originalURL: URL(fileURLWithPath: "/Users/example/Documents/failed_batch.jsonl"),
        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/failed_batch.jsonl"),
        fileSize: 1572864,
        project: project
    )
    let batchJob = BatchJob(batchFile: file)
    batchJob.jobStatus = .failed
    file.batchJob = batchJob
    
    return FileDetailView(file: file)
        .environment(ToastPresenter())
        .modelContainer(for: [Project.self, BatchFile.self], inMemory: true)
        .frame(width: 400)
        .padding()
}

#Preview("Cancelled") {
    let project = Project(name: "Sample Project")
    let file = BatchFile(
        name: "cancelled_job.jsonl",
        originalURL: URL(fileURLWithPath: "/Users/example/Documents/cancelled_job.jsonl"),
        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/cancelled_job.jsonl"),
        fileSize: 2097152,
        project: project
    )
    let batchJob = BatchJob(batchFile: file)
    batchJob.jobStatus = .cancelled
    file.batchJob = batchJob
    
    return FileDetailView(file: file)
        .environment(ToastPresenter())
        .modelContainer(for: [Project.self, BatchFile.self], inMemory: true)
        .frame(width: 400)
        .padding()
}

#Preview("Expired") {
    let project = Project(name: "Sample Project")
    let file = BatchFile(
        name: "expired_batch.jsonl",
        originalURL: URL(fileURLWithPath: "/Users/example/Documents/expired_batch.jsonl"),
        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/expired_batch.jsonl"),
        fileSize: 6291456,
        project: project
    )
    let batchJob = BatchJob(batchFile: file)
    batchJob.jobStatus = .expired
    file.batchJob = batchJob
    
    return FileDetailView(file: file)
        .environment(ToastPresenter())
        .modelContainer(for: [Project.self, BatchFile.self], inMemory: true)
        .frame(width: 400)
        .padding()
}

#Preview("Job File Downloaded") {
    let project = Project(name: "Sample Project")
    let file = BatchFile(
        name: "downloaded_result.jsonl",
        originalURL: URL(fileURLWithPath: "/Users/example/Documents/downloaded_result.jsonl"),
        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/downloaded_result.jsonl"),
        fileSize: 8388608,
        project: project
    )
    let batchJob = BatchJob(batchFile: file)
    batchJob.jobStatus = .jobFileDownloaded
    file.batchJob = batchJob
    
    return FileDetailView(file: file)
        .environment(ToastPresenter())
        .modelContainer(for: [Project.self, BatchFile.self], inMemory: true)
        .frame(width: 400)
        .padding()
}

#Preview("Unspecified") {
    let project = Project(name: "Sample Project")
    let file = BatchFile(
        name: "unknown_status.jsonl",
        originalURL: URL(fileURLWithPath: "/Users/example/Documents/unknown_status.jsonl"),
        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/unknown_status.jsonl"),
        fileSize: 1048576,
        project: project
    )
    let batchJob = BatchJob(batchFile: file)
    batchJob.jobStatus = .unspecified
    file.batchJob = batchJob
    
    return FileDetailView(file: file)
        .environment(ToastPresenter())
        .modelContainer(for: [Project.self, BatchFile.self], inMemory: true)
        .frame(width: 400)
        .padding()
}
