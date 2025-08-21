//
//  FileRowView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/31/25.
//

import SplitView
import SwiftData
import SwiftUI
import AppKit

struct FileRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ToastPresenter.self) private var toastPresenter
    
    let file: BatchFile
    let fileBatchJob: BatchJob?
    
    @State private var viewModel: BatchFileViewModel
    @State private var taskManager = TaskManager.shared
    @Binding private var selectedBatchFile: BatchFile?
    
    private var isSelected: Bool {
        selectedBatchFile?.id == file.id
    }
        
    private var actionButtonDisabled: Bool {
        return viewModel.apiKeyIsEmpty
    }
    
    init(
        file: BatchFile,
        fileBatchJob: BatchJob?,
        selectedBatchFile: Binding<BatchFile?>
    ) {
        self.file = file
        self.fileBatchJob = fileBatchJob
        self._selectedBatchFile = selectedBatchFile
        self._viewModel = State(
            initialValue: BatchFileViewModel(
                batchFile: file,
                fileBatchJob: fileBatchJob
            )
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.accentColor)
                FileDetailView(file: file, fileBatchJob: fileBatchJob)
                Spacer()
                if let batchJob = fileBatchJob {
                    BatchJobStatusView(status: batchJob.jobStatus)
                        .padding(.trailing, 10)
                }
                actionButton
            }
        }
        .padding()
        .background(isSelected ? .gray.opacity(0.1) : .clear)
        .contentShape(Rectangle())
        .cornerRadius(8)
        .onTapGesture {
            selectedBatchFile = file
        }
        .focusable()
        .focusEffectDisabled()
        .task {
            setupBatchJobIfNeeded()
            viewModel.updateStatus(forBatchJob: fileBatchJob)
        }
        .onChange(of: taskManager.runningTasks) {
            viewModel.updateStatus(forBatchJob: fileBatchJob)
        }
        .onChange(of: fileBatchJob?.jobStatus) {
            viewModel.updateStatus(forBatchJob: fileBatchJob)
        }
    }
}

// MARK: Action Buttons
extension FileRowView {
    
    @ViewBuilder
    private var actionButton: some View {
        switch viewModel.batchJobAction {
        case .run:
            runBatchJobButton
        case .running:
            stopBatchJobButton
        case .retry:
            retryBatchJobButton
        case .downloadFile:
            downloadResultFileButton
        }
    }
    
    @ViewBuilder
    private var runBatchJobButton: some View {
        Button {
            Task {
                do {
                    selectedBatchFile = file
                    try await viewModel.runJob(inModelContext: modelContext)
                } catch {
                    toastPresenter.showErrorToast(withMessage: error.localizedDescription)
                }
            }
        } label: {
            Image(systemName: "play")
                .padding(8)
                .font(.system(size: 16, weight: .semibold))
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .tint(.orange.opacity(colorScheme == .dark ? 0.5 : 0.8))
        .help("Run file")
        .scaleEffect(1.2)
        .disabled(actionButtonDisabled)
    }
    
    @ViewBuilder
    private var stopBatchJobButton: some View {
        Button {
            selectedBatchFile = file
            viewModel.cancelJob(inModelContext: modelContext)
        } label: {
            Image(systemName: "stop.circle")
                .padding(8)
                .font(.system(size: 16, weight: .semibold))
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .tint(.red.opacity(colorScheme == .dark ? 0.5 : 0.8))
        .help("Stop file batch job")
        .scaleEffect(1.2)
    }
    
    @ViewBuilder
    private var retryBatchJobButton: some View {
        Button {
            Task {
                do {
                    selectedBatchFile = file
                    try await viewModel.retryJob(inModelContext: modelContext)
                } catch {
                    toastPresenter.showErrorToast(withMessage: error.localizedDescription)
                }
            }
        } label: {
            Image(systemName: "arrow.clockwise")
                .padding(8)
                .font(.system(size: 16, weight: .semibold))
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .tint(.indigo.opacity(colorScheme == .dark ? 0.5 : 0.8))
        .help("Retry batch job")
        .scaleEffect(1.2)
        .disabled(actionButtonDisabled)
    }
    
    @ViewBuilder
    private var downloadResultFileButton: some View {
        Button {
            downloadResultFile()
        } label: {
            Image(systemName: "square.and.arrow.down")
                .padding(8)
                .font(.system(size: 16, weight: .semibold))
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .tint(.blue.opacity(colorScheme == .dark ? 0.5 : 0.8))
        .help("Download batch job result file")
        .scaleEffect(1.2)
        .disabled(file.batchJob?.resultsFileName == nil)
    }
}

extension FileRowView {
    private func setupBatchJobIfNeeded() {
        if file.batchJob == nil {
            let batchJob = BatchJob(batchFile: file)
            modelContext.insert(batchJob)
            file.batchJob = batchJob
            try? modelContext.save()
        }
    }
    
    private func downloadResultFile() {
        guard let resultPath = file.resultPath,
              let resultsFileName = fileBatchJob?.resultsFileName else {
            toastPresenter.showErrorToast(withMessage: "No result file available for download")
            return
        }
        
        let resultURL = URL(fileURLWithPath: resultPath)
        
        // Check if result file exists
        guard FileManager.default.fileExists(atPath: resultPath) else {
            toastPresenter.showErrorToast(withMessage: "Result file not found")
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.title = "Save Batch Job Result"
        savePanel.allowedContentTypes = [.jsonl]
        savePanel.nameFieldStringValue = resultsFileName
        savePanel.canCreateDirectories = true
        
        savePanel.begin { response in
            if response == .OK, let destinationURL = savePanel.url {
                do {
                    // Copy the result file to the chosen destination
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    try FileManager.default.copyItem(at: resultURL, to: destinationURL)
                    Task { @MainActor in
                        toastPresenter.showSuccessToast(withMessage: "Result file saved successfully")
                    }
                } catch {
                    Task { @MainActor in
                        toastPresenter.showErrorToast(withMessage: "Failed to save file: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

//#Preview("Run Button") {
//    let project = Project(name: "Sample Project")
//    let file = BatchFile(
//        name: "sample_data.jsonl",
//        originalURL: URL(fileURLWithPath: "/Users/example/Documents/sample_data.jsonl"),
//        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/sample_data.jsonl"),
//        fileSize: 2048576,
//        project: project
//    )
//    let batchJob = BatchJob(batchFile: file)
//    batchJob.jobStatus = .notStarted
//    file.batchJob = batchJob
//    
//    let projectViewModel = ProjectViewModel(project: project)
//    projectViewModel.keychainManager.geminiAPIKey = "key"
//    
//    return FileRowView(file: file)
//        .environment(ToastPresenter())
//        .environment(projectViewModel)
//        .modelContainer(
//            for: [Project.self, BatchFile.self, BatchJob.self],
//            inMemory: true
//        )
//        .frame(width: 600)
//        .padding()
//}
//
//#Preview("Stop Button - Running Job") {
//    let project = Project(name: "Sample Project")
//    let file = BatchFile(
//        name: "running_job.jsonl",
//        originalURL: URL(fileURLWithPath: "/Users/example/Documents/running_job.jsonl"),
//        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/running_job.jsonl"),
//        fileSize: 1024000,
//        project: project
//    )
//    
//    // Create a batch job in running state
//    let batchJob = BatchJob(batchFile: file)
//    batchJob.jobStatus = .running
//    batchJob.startedAt = Date()
//    file.batchJob = batchJob
//    
//    // Simulate running task with correct type
//    let mockTask: Task<Void, Error> = Task {
//        // Simulate a long-running task
//        try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
//    }
//    TaskManager.shared.addTask(for: file.persistentModelID, task: mockTask)
//    
//    return FileRowView(file: file)
//        .environment(ToastPresenter())
//        .environment(ProjectViewModel(project: project))
//        .modelContainer(
//            for: [Project.self, BatchFile.self, BatchJob.self],
//            inMemory: true
//        )
//        .frame(width: 600)
//        .padding()
//}
//
//#Preview("Retry Button - Failed Job") {
//    let project = Project(name: "Sample Project")
//    let file = BatchFile(
//        name: "failed_job.jsonl",
//        originalURL: URL(fileURLWithPath: "/Users/example/Documents/failed_job.jsonl"),
//        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/failed_job.jsonl"),
//        fileSize: 512000,
//        project: project
//    )
//    
//    // Create a failed batch job
//    let batchJob = BatchJob(batchFile: file)
//    batchJob.jobStatus = .failed
//    batchJob.startedAt = Date().addingTimeInterval(-3600) // 1 hour ago
//    file.batchJob = batchJob
//    
//    let projectViewModel = ProjectViewModel(project: project)
//    projectViewModel.keychainManager.geminiAPIKey = "key"
//    
//    return FileRowView(file: file)
//        .environment(ToastPresenter())
//        .environment(projectViewModel)
//        .modelContainer(
//            for: [Project.self, BatchFile.self, BatchJob.self],
//            inMemory: true
//        )
//        .frame(width: 600)
//        .padding()
//}
//
//#Preview("Download Button - Completed Job") {
//    let project = Project(name: "Sample Project")
//    let file = BatchFile(
//        name: "completed_job.jsonl",
//        originalURL: URL(fileURLWithPath: "/Users/example/Documents/completed_job.jsonl"),
//        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/completed_job.jsonl"),
//        fileSize: 3145728,
//        project: project
//    )
//    
//    // Create a completed batch job with results
//    let batchJob = BatchJob(batchFile: file)
//    batchJob.jobStatus = .jobFileDownloaded
//    batchJob.startedAt = Date().addingTimeInterval(-7200) // 2 hours ago
//    batchJob.resultsFileName = "completed_job_results.jsonl"
//    file.batchJob = batchJob
//    file.resultPath = "/Users/example/Projects/GeminiBatch/Results/completed_job_results.jsonl"
//    
//    return FileRowView(file: file)
//        .environment(ToastPresenter())
//        .environment(ProjectViewModel(project: project))
//        .modelContainer(
//            for: [Project.self, BatchFile.self, BatchJob.self],
//            inMemory: true
//        )
//        .frame(width: 600)
//        .padding()
//}
//
//#Preview("Retry Button - Cancelled Job") {
//    let project = Project(name: "Sample Project")
//    let file = BatchFile(
//        name: "cancelled_job.jsonl",
//        originalURL: URL(fileURLWithPath: "/Users/example/Documents/cancelled_job.jsonl"),
//        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/cancelled_job.jsonl"),
//        fileSize: 768000,
//        project: project
//    )
//    
//    // Create a cancelled batch job
//    let batchJob = BatchJob(batchFile: file)
//    batchJob.jobStatus = .cancelled
//    batchJob.startedAt = Date().addingTimeInterval(-1800) // 30 minutes ago
//    file.batchJob = batchJob
//    
//    return FileRowView(file: file)
//        .environment(ToastPresenter())
//        .environment(ProjectViewModel(project: project))
//        .modelContainer(
//            for: [Project.self, BatchFile.self, BatchJob.self],
//            inMemory: true
//        )
//        .frame(width: 600)
//        .padding()
//}
//
//#Preview("Retry Button - Expired Job") {
//    let project = Project(name: "Sample Project")
//    let file = BatchFile(
//        name: "expired_job.jsonl",
//        originalURL: URL(fileURLWithPath: "/Users/example/Documents/expired_job.jsonl"),
//        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/expired_job.jsonl"),
//        fileSize: 1536000,
//        project: project
//    )
//    
//    // Create an expired batch job
//    let batchJob = BatchJob(batchFile: file)
//    batchJob.jobStatus = .expired
//    batchJob.startedAt = Date().addingTimeInterval(-172800) // 48 hours ago
//    file.batchJob = batchJob
//    
//    return FileRowView(file: file)
//        .environment(ToastPresenter())
//        .environment(ProjectViewModel(project: project))
//        .modelContainer(
//            for: [Project.self, BatchFile.self, BatchJob.self],
//            inMemory: true
//        )
//        .frame(width: 600)
//        .padding()
//}
//
//#Preview("All Button States") {
//    let project = Project(name: "Preview Project")
//    
//    // Create files for different states
//    let runFile = BatchFile(
//        name: "run_job.jsonl",
//        originalURL: URL(fileURLWithPath: "/Users/example/Documents/run_job.jsonl"),
//        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/run_job.jsonl"),
//        fileSize: 1024000,
//        project: project
//    )
//    
//    let runningFile = BatchFile(
//        name: "running_job.jsonl",
//        originalURL: URL(fileURLWithPath: "/Users/example/Documents/running_job.jsonl"),
//        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/running_job.jsonl"),
//        fileSize: 2048000,
//        project: project
//    )
//    let runningJob = BatchJob(batchFile: runningFile)
//    runningJob.jobStatus = .running
//    runningJob.startedAt = Date()
//    runningFile.batchJob = runningJob
//    
//    let failedFile = BatchFile(
//        name: "failed_job.jsonl",
//        originalURL: URL(fileURLWithPath: "/Users/example/Documents/failed_job.jsonl"),
//        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/failed_job.jsonl"),
//        fileSize: 512000,
//        project: project
//    )
//    let failedJob = BatchJob(batchFile: failedFile)
//    failedJob.jobStatus = .failed
//    failedJob.startedAt = Date().addingTimeInterval(-3600)
//    failedFile.batchJob = failedJob
//    
//    let completedFile = BatchFile(
//        name: "completed_job.jsonl",
//        originalURL: URL(fileURLWithPath: "/Users/example/Documents/completed_job.jsonl"),
//        storedURL: URL(fileURLWithPath: "/Users/example/Projects/GeminiBatch/Storage/completed_job.jsonl"),
//        fileSize: 3145728,
//        project: project
//    )
//    let completedJob = BatchJob(batchFile: completedFile)
//    completedJob.jobStatus = .jobFileDownloaded
//    completedJob.startedAt = Date().addingTimeInterval(-7200)
//    completedJob.resultsFileName = "completed_job_results.jsonl"
//    completedFile.batchJob = completedJob
//    completedFile.resultPath = "/Users/example/Projects/GeminiBatch/Results/completed_job_results.jsonl"
//    
//    return VStack(spacing: 16) {
//        FileRowView(file: runFile)
//        FileRowView(file: runningFile)
//        FileRowView(file: failedFile)
//        FileRowView(file: completedFile)
//    }
//    .environment(ToastPresenter())
//    .environment(ProjectViewModel(project: project))
//    .modelContainer(
//        for: [Project.self, BatchFile.self, BatchJob.self],
//        inMemory: true
//    )
//    .frame(width: 700)
//    .padding()
//}
