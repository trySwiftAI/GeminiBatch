//
//  RunView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/11/25.
//

import SwiftUI
import SwiftData

struct RunView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allBatchJobs: [BatchJob]
    
    private var batchJob: BatchJob? {
        allBatchJobs.first
    }
    
    init(batchFileID: UUID) {
        self._allBatchJobs = Query(filter: #Predicate { $0.batchFile.id == batchFileID })
    }
    
    var body: some View {
        if let batchJob = batchJob {
            VStack(alignment: .leading, spacing: 0) {
                headerSection(for: batchJob)
                Divider()
                messagesSection(for: batchJob)
            }
        } else {
            EmptyView()
        }
    }
}

// MARK: - Header Section
extension RunView {
    
    private func headerSection(for batchJob: BatchJob) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(batchJob.batchFile.name)
                    .font(.title2)
                    .fontWeight(.semibold)
            
                BatchJobStatusView(status: batchJob.jobStatus)
                if let latestMessage = batchJob.latestMessage {
                    Text(latestMessage.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if [.pending, .running, .succeeded].contains(batchJob.jobStatus) {
                    if let expirationTimeRemaining = batchJob.expirationTimeRemaining {
                        Text(expirationTimeRemaining)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
    }
}

// MARK: - Messages Section
extension RunView {
    
    private func messagesSection(for batchJob: BatchJob) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Job Updates")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            if batchJob.jobStatusMessages.isEmpty {
                emptyMessagesView
            } else {
                BatchJobMessagesView(batchJob: batchJob)
            }
        }
    }
    
    private var emptyMessagesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "message.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No updates yet...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Job updates will appear here as the batch job progresses")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Batch Job Message Row


//// MARK: - Preview
#Preview("Running Job with Messages") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Project.self, BatchFile.self, BatchJob.self, BatchJobMessage.self, configurations: config)
    let context = container.mainContext
    
    let project = Project(name: "Sample Project")
    let batchFile = BatchFile(
        name: "batch_file",
        originalURL: URL(string: "http://")!,
        storedURL: URL(string: "http://")!,
        fileSize: 400,
        project: project
    )
    
    let runningJob = BatchJob(batchFile: batchFile)
    runningJob.geminiJobName = "sample_batch_job_123"
    runningJob.jobStatus = .running
    runningJob.startedAt = Date().addingTimeInterval(-3600) // Started 1 hour ago
    
    // Add sample messages
    runningJob.addMessage("Batch job file uploaded successfully", type: .success)
    runningJob.addMessage("Job submitted to Gemini API", type: .success)
    runningJob.addMessage("Processing batch requests...", type: .pending)
    runningJob.addMessage("Completed 150 out of 500 requests", type: .pending)
    runningJob.addMessage("Warning: Rate limit encountered, retrying...", type: .error)
    runningJob.addMessage("Completed 300 out of 500 requests", type: .pending)
    
    batchFile.batchJob = runningJob
    
    context.insert(project)
    context.insert(batchFile)
    context.insert(runningJob)
    
    return RunView(batchFileID: batchFile.id)
        .frame(width: 600, height: 500)
        .modelContainer(container)
}

#Preview("Job with No Messages") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Project.self, BatchFile.self, BatchJob.self, BatchJobMessage.self, configurations: config)
    let context = container.mainContext
    
    let project = Project(name: "Sample Project")
    let batchFile = BatchFile(
        name: "batch_file",
        originalURL: URL(string: "http://")!,
        storedURL: URL(string: "http://")!,
        fileSize: 400,
        project: project
    )
    let job = BatchJob(batchFile: batchFile)
    job.jobStatus = .pending
    job.startedAt = Date()
    batchFile.batchJob = job
    
    context.insert(project)
    context.insert(batchFile)
    context.insert(job)
        
    return RunView(batchFileID: batchFile.id)
        .frame(width: 600, height: 500)
        .modelContainer(container)
}

#Preview("Completed Job") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Project.self, BatchFile.self, BatchJob.self, BatchJobMessage.self, configurations: config)
    let context = container.mainContext
    
    let project = Project(name: "Sample Project")
    let batchFile = BatchFile(
        name: "batch_file",
        originalURL: URL(string: "http://")!,
        storedURL: URL(string: "http://")!,
        fileSize: 400,
        project: project
    )
    let completedJob = BatchJob(batchFile: batchFile)
    completedJob.geminiJobName = "completed_batch_job_456"
    completedJob.jobStatus = .succeeded
    completedJob.startedAt = Date().addingTimeInterval(-7200) // Started 2 hours ago
    
    // Add completion messages
    completedJob.addMessage("Batch job started", type: .success)
    completedJob.addMessage("Processing 1000 requests", type: .pending)
    completedJob.addMessage("Completed 250 requests", type: .pending)
    completedJob.addMessage("Completed 500 requests", type: .pending)
    completedJob.addMessage("Completed 750 requests", type: .pending)
    completedJob.addMessage("All 1000 requests completed successfully", type: .success)
    completedJob.addMessage("Results file generated", type: .success)
    completedJob.addMessage("Batch job completed successfully", type: .success)
    batchFile.batchJob = completedJob
    
    context.insert(project)
    context.insert(batchFile)
    context.insert(completedJob)
    
    return RunView(batchFileID: batchFile.id)
        .frame(width: 600, height: 500)
        .modelContainer(container)
}

#Preview("Failed Job") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Project.self, BatchFile.self, BatchJob.self, BatchJobMessage.self, configurations: config)
    let context = container.mainContext
    
    let project = Project(name: "Sample Project")
    let batchFile = BatchFile(
        name: "batch_file",
        originalURL: URL(string: "http://")!,
        storedURL: URL(string: "http://")!,
        fileSize: 400,
        project: project
    )
    let failedJob = BatchJob(batchFile: batchFile)
    failedJob.geminiJobName = "failed_batch_job_789"
    failedJob.jobStatus = .failed
    failedJob.startedAt = Date().addingTimeInterval(-1800) // Started 30 minutes ago
    
    // Add failure messages
    failedJob.addMessage("Batch job started", type: .success)
    failedJob.addMessage("Processing requests...", type: .pending)
    failedJob.addMessage("Error: Invalid request format detected", type: .error)
    failedJob.addMessage("Retrying with corrected format...", type: .pending)
    failedJob.addMessage("Critical error: Unable to process batch file", type: .error)
    failedJob.addMessage("Batch job failed", type: .error)

    batchFile.batchJob = failedJob
    
    context.insert(project)
    context.insert(batchFile)
    context.insert(failedJob)
    
    return RunView(batchFileID: batchFile.id)
        .frame(width: 600, height: 500)
        .modelContainer(container)
}
