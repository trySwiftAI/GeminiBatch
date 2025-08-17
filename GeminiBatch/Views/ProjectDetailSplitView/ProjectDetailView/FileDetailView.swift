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
    
    let file: BatchFile
    
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
    
    /*

         case .pending:
             return "clock.fill"
         case .running:
             return "gearshape.2.fill"
         case .succeeded:
             return "checkmark.circle.fill"
         case .jobFileDownloaded:
             return "arrow.down.circle.fill"
         }
     */
    @ViewBuilder
    private var fileDetailView: some View {
        if let batchJob = file.batchJob {
            switch batchJob.jobStatus {
            case .notStarted:
                fileNotStartedDetailView
            case .fileUploaded:
                fileUploadedDetailView
            case .pending:
                Text(file.storedURL.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            case .running:
                Text(file.storedURL.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            case .succeeded:
                Text(file.storedURL.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            case .jobFileDownloaded:
                Text(file.storedURL.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
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
                    text: "Job was cancelled. Clikc retry to start a new batch job.",
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
                HStack(spacing: 8) {
                    Text(geminiFileName)
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
                        NSPasteboard.general.setString(geminiFileName, forType: .string)
                        toastPresenter.showSuccessToast(withMessage: "Gemini file name copied to clipboard")
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption2)
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
