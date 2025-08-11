//
//  RunView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/11/25.
//

//import SwiftUI
//import SwiftData
//
//struct RunView: View {
//    @Environment(\.modelContainer) private var modelContainer
//    @Environment(ToastPresenter.self) private var toastPresenter
//    
//    let project: Project
//    @Binding var selectedBatchFile: BatchFile?
//    @Binding var selectedGeminiModel: GeminiModel
//    
//    @State private var runViewModel: RunViewModel?
//    
//    init(project: Project, selectedBatchFile: Binding<BatchFile?>, selectedGeminiModel: Binding<GeminiModel>) {
//        self.project = project
//        self._selectedBatchFile = selectedBatchFile
//        self._selectedGeminiModel = selectedGeminiModel
//    }
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            if let viewModel = runViewModel {
//                headerSection(viewModel)
//                
//                if viewModel.selectedBatchFile != nil {
//                    contentSection(viewModel)
//                } else {
//                    emptyStateSection
//                }
//            } else {
//                ProgressView("Loading...")
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            }
//        }
//        .onChange(of: selectedBatchFile) { _, newFile in
//            if let newFile {
//                runViewModel?.selectBatchFile(newFile)
//            }
//        }
//        .onChange(of: selectedGeminiModel) { _, newModel in
//            runViewModel?.selectedGeminiModel = newModel
//        }
//        .onChange(of: runViewModel?.showError ?? false) { _, showError in
//            if showError, let errorMessage = runViewModel?.errorMessage, !errorMessage.isEmpty {
//                toastPresenter.showErrorToast(withMessage: errorMessage)
//            }
//        }
//        .onAppear {
//            if runViewModel == nil {
//                runViewModel = RunViewModel(project: project, modelContainer: modelContainer)
//                runViewModel?.selectedGeminiModel = selectedGeminiModel
//                if let selectedFile = selectedBatchFile {
//                    runViewModel?.selectBatchFile(selectedFile)
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Header Section
//extension RunView {
//    @ViewBuilder
//    private func headerSection(_ viewModel: RunViewModel) -> some View {
//        VStack(spacing: 12) {
//            HStack {
//                Image(systemName: "play.circle.fill")
//                    .font(.title2)
//                    .foregroundColor(.orange)
//                
//                Text("Batch Job Runner")
//                    .font(.title2)
//                    .fontWeight(.bold)
//                
//                Spacer()
//                
//                if viewModel.isRunning {
//                    ProgressView()
//                        .scaleEffect(0.8)
//                        .controlSize(.small)
//                }
//            }
//            
//            if let selectedFile = viewModel.selectedBatchFile {
//                fileInfoCard(selectedFile, viewModel: viewModel)
//            }
//        }
//        .padding()
//        .background(Color(.controlBackgroundColor))
//    }
//    
//    @ViewBuilder
//    private func fileInfoCard(_ file: BatchFile, viewModel: RunViewModel) -> some View {
//        HStack {
//            Image(systemName: "doc.text.fill")
//                .foregroundColor(.accentColor)
//            
//            VStack(alignment: .leading, spacing: 2) {
//                Text(file.name)
//                    .font(.headline)
//                    .lineLimit(1)
//                
//                Text("\(file.formattedFileSize) • Uploaded \(file.uploadedAt, style: .date)")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//            
//            Spacer()
//            
//            statusBadge(viewModel: viewModel)
//        }
//        .padding()
//        .background(Color(.tertiarySystemBackground))
//        .cornerRadius(8)
//    }
//    
//    @ViewBuilder
//    private func statusBadge(viewModel: RunViewModel) -> some View {
//        HStack(spacing: 4) {
//            Circle()
//                .fill(statusColor(viewModel: viewModel))
//                .frame(width: 8, height: 8)
//            
//            Text(viewModel.jobStatusText)
//                .font(.caption)
//                .fontWeight(.medium)
//        }
//        .padding(.horizontal, 8)
//        .padding(.vertical, 4)
//        .background(statusColor(viewModel: viewModel).opacity(0.1))
//        .cornerRadius(12)
//    }
//    
//    private func statusColor(viewModel: RunViewModel) -> Color {
//        guard let batchJob = viewModel.currentBatchJob else { return .secondary }
//        
//        switch batchJob.jobStatus {
//        case .notStarted, .fileUploaded:
//            return .blue
//        case .pending, .running, .unspecified:
//            return .orange
//        case .succeeded, .jobFileDownloaded:
//            return .green
//        case .failed, .cancelled, .expired:
//            return .red
//        }
//    }
//}
//
//// MARK: - Content Section
//extension RunView {
//    @ViewBuilder
//    private func contentSection(_ viewModel: RunViewModel) -> some View {
//        VStack(spacing: 16) {
//            modelDisplaySection(viewModel)
//            actionButtonsSection(viewModel)
//            messagesSection(viewModel)
//        }
//    }
//    
//    @ViewBuilder
//    private func modelDisplaySection(_ viewModel: RunViewModel) -> some View {
//        VStack(spacing: 8) {
//            HStack {
//                Text("Selected Model:")
//                    .font(.headline)
//                    .fontWeight(.semibold)
//                
//                Spacer()
//                
//                Text(selectedGeminiModel.displayName)
//                    .font(.subheadline)
//                    .fontWeight(.medium)
//                    .foregroundColor(.accentColor)
//            }
//            
//            Text(selectedGeminiModel.description)
//                .font(.caption)
//                .foregroundColor(.secondary)
//                .multilineTextAlignment(.leading)
//                .frame(maxWidth: .infinity, alignment: .leading)
//        }
//        .padding()
//        .background(Color(.controlBackgroundColor))
//    }
//    
//    @ViewBuilder
//    private func actionButtonsSection(_ viewModel: RunViewModel) -> some View {
//        HStack(spacing: 12) {
//            Button {
//                viewModel.startBatchJob()
//            } label: {
//                HStack {
//                    if viewModel.isRunning {
//                        ProgressView()
//                            .scaleEffect(0.8)
//                            .controlSize(.small)
//                    } else {
//                        Image(systemName: "play.fill")
//                    }
//                    Text(viewModel.isRunning ? "Running..." : "Start Job")
//                }
//                .frame(maxWidth: .infinity)
//            }
//            .buttonStyle(.borderedProminent)
//            .disabled(!viewModel.canStartJob)
//            
//            if viewModel.isRunning {
//                Button {
//                    viewModel.stopCurrentJob()
//                } label: {
//                    HStack {
//                        Image(systemName: "stop.fill")
//                        Text("Stop")
//                    }
//                    .frame(maxWidth: .infinity)
//                }
//                .buttonStyle(.bordered)
//            }
//            
//            Button {
//                viewModel.refreshJobMessages()
//            } label: {
//                HStack {
//                    Image(systemName: "arrow.clockwise")
//                    Text("Refresh")
//                }
//                .frame(maxWidth: .infinity)
//            }
//            .buttonStyle(.bordered)
//            .disabled(viewModel.isRunning)
//        }
//        .padding()
//        .background(Color(.controlBackgroundColor))
//    }
//}
//
//// MARK: - Messages Section
//extension RunView {
//    @ViewBuilder
//    private func messagesSection(_ viewModel: RunViewModel) -> some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                Text("Job Messages")
//                    .font(.headline)
//                    .fontWeight(.semibold)
//                
//                Spacer()
//                
//                if !viewModel.jobMessages.isEmpty {
//                    Text("\(viewModel.jobMessages.count) messages")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//            }
//            .padding(.horizontal)
//            
//            if viewModel.jobMessages.isEmpty {
//                emptyMessagesView
//            } else {
//                messagesList(viewModel)
//            }
//        }
//    }
//    
//    @ViewBuilder
//    private var emptyMessagesView: some View {
//        VStack(spacing: 8) {
//            Image(systemName: "message")
//                .font(.largeTitle)
//                .foregroundColor(.secondary)
//            
//            Text("No messages yet")
//                .font(.headline)
//                .foregroundColor(.secondary)
//            
//            Text("Start a batch job to see status messages")
//                .font(.caption)
//                .foregroundColor(.secondary)
//                .multilineTextAlignment(.center)
//        }
//        .frame(maxWidth: .infinity, minHeight: 150)
//        .padding()
//    }
//    
//    @ViewBuilder
//    private func messagesList(_ viewModel: RunViewModel) -> some View {
//        ScrollViewReader { proxy in
//            ScrollView {
//                LazyVStack(spacing: 8) {
//                    ForEach(viewModel.jobMessages, id: \.id) { message in
//                        JobMessageView(message: message)
//                            .id(message.id)
//                    }
//                }
//                .padding(.horizontal)
//            }
//            .onChange(of: viewModel.jobMessages.count) { _, _ in
//                if let lastMessage = viewModel.jobMessages.last {
//                    withAnimation(.easeInOut(duration: 0.5)) {
//                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
//                    }
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Empty State Section
//extension RunView {
//    @ViewBuilder
//    private var emptyStateSection: some View {
//        VStack(spacing: 16) {
//            Image(systemName: "doc.text.magnifyingglass")
//                .font(.system(size: 48))
//                .foregroundColor(.secondary)
//            
//            Text("No File Selected")
//                .font(.title2)
//                .fontWeight(.bold)
//                .foregroundColor(.secondary)
//            
//            Text("Select a JSONL file from the project to run a batch job")
//                .font(.body)
//                .foregroundColor(.secondary)
//                .multilineTextAlignment(.center)
//                .padding(.horizontal)
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .padding()
//    }
//}
//
//// MARK: - Job Message View
//struct JobMessageView: View {
//    let message: BatchJobMessage
//    
//    var body: some View {
//        HStack(alignment: .top, spacing: 12) {
//            Image(systemName: message.type.systemImageName)
//                .font(.system(size: 14, weight: .semibold))
//                .foregroundColor(messageTypeColor)
//                .frame(width: 20)
//            
//            VStack(alignment: .leading, spacing: 4) {
//                Text(message.message)
//                    .font(.body)
//                    .fixedSize(horizontal: false, vertical: true)
//                
//                Text(message.timestamp, style: .time)
//                    .font(.caption2)
//                    .foregroundColor(.secondary)
//            }
//            
//            Spacer(minLength: 0)
//        }
//        .padding()
//        .background(Color(.tertiarySystemBackground))
//        .cornerRadius(8)
//    }
//    
//    private var messageTypeColor: Color {
//        switch message.type {
//        case .success:
//            return .green
//        case .error:
//            return .red
//        case .pending:
//            return .orange
//        }
//    }
//}
