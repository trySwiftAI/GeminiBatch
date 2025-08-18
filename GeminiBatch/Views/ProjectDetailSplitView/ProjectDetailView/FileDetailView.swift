//
//  FileDetailView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/8/25.
//

import SwiftUI
import SwiftData

struct FileDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @Environment(ToastPresenter.self) private var toastPresenter
    
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
            HStack(alignment: .center, spacing: 2) {
                Text(file.name)
                    .font(.headline)
                    .lineLimit(1)
                viewFileButton
                deleteFileButton
            }
            
            HStack(spacing: 12) {
                Label(file.formattedFileSize, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label(file.uploadedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
            }
            .padding(.bottom, 4)
            
            fileDetailView
        }
    }
}

extension FileDetailView {
    @ViewBuilder
    private var fileDetailView: some View {
        if let batchJob = observedFile?.batchJob {
            switch batchJob.jobStatus {
            case .notStarted:
                fileNotStartedDetailView
            case .fileUploaded:
                fileUploadedDetailView
            case .pending:
                jobPendingDetailView
            case .running:
                jobRunningDetailView
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
    
    @ViewBuilder
    private var fileNotStartedDetailView: some View {
        Text("File ready. Click play to upload and start batch processing")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    @ViewBuilder
    private var fileUploadedDetailView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("File successfully uploaded to Gemini")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let geminiFileName = file.geminiFileName {
                fileNameView(geminiFileName)
            }
        }
    }
    
    private var jobPendingDetailView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text("Batch job queued and waiting to start")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let geminiFileName = file.geminiFileName {
                fileNameView(geminiFileName)
            }
            
            if let batchJobName = file.batchJob?.geminiJobName {
                jobNameView(batchJobName)
            }
        }
    }
    
    @ViewBuilder
    private var jobRunningDetailView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "gearshape.2.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text("Batch job is currently running")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
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
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("Batch job completed successfully! Results ready to download.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
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
    private func fileNameView(_ name: String) -> some View {
        HStack(spacing: 8) {
            Text("Gemini File Name:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(name)
                .font(.caption)
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.separatorColor), lineWidth: 0.5)
                )
            
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(name, forType: .string)
                toastPresenter.showSuccessToast(withMessage: "Gemini file name copied to clipboard")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Copy Gemini file name")
            
            
            if let fileExpirationText = file.geminiFileExpirationTimeRemaining {
                HStack(spacing: 6) {
                    Text(fileExpirationText)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    @ViewBuilder
    private func jobNameView(_ name: String) -> some View {
        HStack(spacing: 8) {
            Text("Gemini Batch Job Name:")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(name)
                .font(.caption)
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.separatorColor), lineWidth: 0.5)
                )
            
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(name, forType: .string)
                toastPresenter.showSuccessToast(withMessage: "Gemini batch job name copied to clipboard")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Copy Gemini batch job name")
        }
    }
    
    @ViewBuilder
    private func resultPathView(_ path: String) -> some View {
        HStack(spacing: 8) {
            Text("Gemini Batch Job Result Path:")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(path)
                .font(.caption)
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.separatorColor), lineWidth: 0.5)
                )
            
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(path, forType: .string)
                toastPresenter.showSuccessToast(withMessage: "Gemini results path copied to clipboard")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Copy Gemini results path")
            
            
            if let jobExpirationText = file.batchJob?.expirationTimeRemaining {
                HStack(spacing: 6) {
                    Text(jobExpirationText)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}

extension FileDetailView {
    
    @ViewBuilder
    private var viewFileButton: some View {
        Button {
            openFile(file)
        } label: {
            Image(systemName: "eye")
                .foregroundColor(.blue)
        }
        .buttonStyle(.borderless)
        .buttonBorderShape(.circle)
        .help("View file")
        .tint(.blue)
        .padding(4)
    }
    
    @ViewBuilder
    private var deleteFileButton: some View {
        Button {
            Task {
                await deleteFile(file)
            }
        } label: {
            Image(systemName: "trash")
        }
        .buttonStyle(.borderless)
        .tint(.red)
        .buttonBorderShape(.circle)
        .help("Delete file")
        .padding(4)
    }
}

// MARK: File Actions
extension FileDetailView {
    
    private func openFile(_ file: BatchFile) {
        NSWorkspace.shared.open(file.storedURL)
    }
    
    private func deleteFile(_ file: BatchFile) async {
        do {
            try await ProjectFileManager(
                projectID: file.project.id.uuidString).deleteBatchFile(fileId: file.id, using: .init(modelContainer: modelContext.container))
        } catch {
            let errorMessage = "Failed to delete file: \(error.localizedDescription)"
            toastPresenter.showErrorToast(withMessage: errorMessage)
        }
    }
}

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
