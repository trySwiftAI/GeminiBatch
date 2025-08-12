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
    @Binding var runningBatchJob: BatchJob?
    
    @Query private var allBatchJobs: [BatchJob]
    
    private var observedBatchJob: BatchJob? {
        guard let runningBatchJob else { return nil }
        return allBatchJobs.first { $0.id == runningBatchJob.id }
    }
    
    var body: some View {
        if let batchJob = observedBatchJob {
            VStack(spacing: 0) {
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
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "gearshape.2.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("Batch Job Status")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                statusBadge(for: batchJob)
            }
            
            jobInfoCard(for: batchJob)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
    }
    
    private func statusBadge(for batchJob: BatchJob) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor(for: batchJob))
                .frame(width: 8, height: 8)
            
            Text(batchJob.jobStatus.geminiStatusTitle)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor(for: batchJob).opacity(0.1))
        .cornerRadius(12)
    }
    
    private func statusColor(for batchJob: BatchJob) -> Color {
        switch batchJob.jobStatus {
        case .notStarted, .fileUploaded:
            return .blue
        case .pending, .running, .unspecified:
            return .orange
        case .succeeded, .jobFileDownloaded:
            return .green
        case .failed, .cancelled, .expired:
            return .red
        }
    }
    
    private func jobInfoCard(for batchJob: BatchJob) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.accentColor)
                
                Text(batchJob.displayJobName)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
            }
            
            Text(batchJob.jobStatus.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            if let expirationTime = batchJob.expirationTimeRemaining {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    Text(expirationTime)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .cornerRadius(8)
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
                
                if !batchJob.jobStatusMessages.isEmpty {
                    Text("\(batchJob.jobStatusMessages.count) messages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            if batchJob.jobStatusMessages.isEmpty {
                emptyMessagesView
            } else {
                messagesList(for: batchJob)
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
    
    private func messagesList(for batchJob: BatchJob) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(batchJob.jobStatusMessages, id: \.id) { message in
                        BatchJobMessageRow(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .onAppear {
                if let lastMessage = batchJob.jobStatusMessages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
            .onChange(of: batchJob.jobStatusMessages.count) { _, newCount in
                // Auto-scroll to bottom when new messages arrive
                if let lastMessage = batchJob.jobStatusMessages.last {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

// MARK: - Batch Job Message Row
struct BatchJobMessageRow: View {
    let message: BatchJobMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status Icon
            Image(systemName: message.type.systemImageName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(messageTypeColor)
                .frame(width: 20)
            
            // Message Content
            VStack(alignment: .leading, spacing: 4) {
                Text(message.message)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 0)
        }
        .padding()
        .cornerRadius(8)
    }
    
    private var messageTypeColor: Color {
        switch message.type {
        case .success:
            return .green
        case .error:
            return .red
        case .pending:
            return .orange
        }
    }
}

// MARK: - Preview
#Preview("Running Job with Messages") {
    let batchFile = BatchFile(
        name: "batch_file",
        originalURL: URL(string: "http://")!,
        storedURL: URL(string: "http://")!,
        fileSize: 400,
        project: Project(name: "New Project")
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
    
    return RunView(runningBatchJob: .constant(runningJob))
        .frame(width: 600, height: 500)
}

#Preview("Job with No Messages") {
    let batchFile = BatchFile(
        name: "batch_file",
        originalURL: URL(string: "http://")!,
        storedURL: URL(string: "http://")!,
        fileSize: 400,
        project: Project(name: "New Project")
    )
    let job = BatchJob(batchFile: batchFile)
    job.jobStatus = .pending
    job.startedAt = Date()
    
    return RunView(runningBatchJob: .constant(job))
        .frame(width: 600, height: 500)
}

#Preview("Completed Job") {
    let batchFile = BatchFile(
        name: "batch_file",
        originalURL: URL(string: "http://")!,
        storedURL: URL(string: "http://")!,
        fileSize: 400,
        project: Project(name: "New Project")
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
    
    return RunView(runningBatchJob: .constant(completedJob))
        .frame(width: 600, height: 500)
}

#Preview("Failed Job") {
    let batchFile = BatchFile(
        name: "batch_file",
        originalURL: URL(string: "http://")!,
        storedURL: URL(string: "http://")!,
        fileSize: 400,
        project: Project(name: "New Project")
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
    
    return RunView(runningBatchJob: .constant(failedJob))
        .frame(width: 600, height: 500)
}
