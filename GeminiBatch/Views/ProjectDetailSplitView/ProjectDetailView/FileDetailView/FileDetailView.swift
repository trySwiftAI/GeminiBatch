//
//  FileDetailView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/8/25.
//

import SwiftUI
import SwiftData

struct FileDetailView: View {
    
    let file: BatchFile
    let fileBatchJob: BatchJob?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            FileOverviewView(file: file)
            if let batchJob = fileBatchJob {
                BatchFileJobStatusView(batchJob: batchJob)
            }
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
    
    
    return FileDetailView(file: file, fileBatchJob: batchJob)
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
    
    return FileDetailView(file: file, fileBatchJob: batchJob)
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


    
    return FileDetailView(file: file, fileBatchJob: batchJob)
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
    
    return FileDetailView(file: file, fileBatchJob: batchJob)
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
    
    return FileDetailView(file: file, fileBatchJob: batchJob)
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
    
    return FileDetailView(file: file, fileBatchJob: batchJob)
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
    
    return FileDetailView(file: file, fileBatchJob: batchJob)
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
    
    return FileDetailView(file: file, fileBatchJob: batchJob)
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
    
    return FileDetailView(file: file, fileBatchJob: batchJob)
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
    
    return FileDetailView(file: file, fileBatchJob: batchJob)
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
    
    return FileDetailView(file: file, fileBatchJob: batchJob)
        .environment(ToastPresenter())
        .modelContainer(for: [Project.self, BatchFile.self], inMemory: true)
        .frame(width: 400)
        .padding()
}
