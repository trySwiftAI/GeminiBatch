//
//  ProjectView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import SwiftData
import SwiftUI

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ToastPresenter.self) private var toastPresenter
    
    @State private var isAPIKeyVisible: Bool = false
    @FocusState private var isAPIKeyFocused
    
    @Binding var selectedBatchFile: BatchFile?

    @State private var viewModel: ProjectViewModel
    @State private var selectedGeminiModel: GeminiModel = .flash
    
    private var batchJobsMap: [UUID: BatchJob] {
        Dictionary(uniqueKeysWithValues: batchJobs.map { ($0.batchFile.id, $0) })
    }
    
    private let project: Project
    private let batchFiles: [BatchFile]
    private let batchJobs: [BatchJob]
    
    init(
        project: Project,
        batchFiles: [BatchFile],
        batchJobs: [BatchJob],
        selectedBatchFile: Binding<BatchFile?>
    ) {
        self.project = project
        self._viewModel = State(
            initialValue: ProjectViewModel(
                project: project,
                batchFiles: batchFiles,
                batchJobs: batchJobs
            )
        )
        self.batchFiles = batchFiles
        self.batchJobs = batchJobs
        self._selectedBatchFile = selectedBatchFile
        if let geminiModel = GeminiModel(rawValue: project.geminiModel) {
            self._selectedGeminiModel = State(initialValue: geminiModel)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            projectHeader(project)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    apiKeySection
                    modelSelectionPicker
                    if !batchFiles.isEmpty {
                        fileListView(batchFiles)
                    }
                    FileUploadView(project: project)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .padding(.leading, 10)
            }
            .padding(.horizontal)
            .scrollIndicators(.hidden)
            .edgesIgnoringSafeArea(.bottom)
        }
        .task {
            do {
                try await viewModel.continueRunningJobs(inModelContext: modelContext)
            } catch {
                toastPresenter.showErrorToast(withMessage: error.localizedDescription)
            }
        }
        .overlay(alignment: .top) {
            if toastPresenter.isPresented && !toastPresenter.message.isEmpty {
                ToastView()
            }
        }
        .onChange(of: selectedGeminiModel) {
            project.geminiModel = selectedGeminiModel.rawValue
            try? modelContext.save()
        }
    }
}

extension ProjectDetailView {
    
    @ViewBuilder
    private func projectHeader(_ project: Project) -> some View {
        HStack {
            Text(project.name)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
            
            HStack(spacing: 30) {
                downloadAllButton
                runAllButton
            }
            .padding(.trailing, 20)
        }
        .padding()
    }
    
    @ViewBuilder
    private var downloadAllButton: some View {
        Button {
            downloadAllResultFiles()
        } label: {
            Label("Download all", systemImage: "square.and.arrow.down")
                .labelStyle(.titleAndIcon)
        }
        .buttonStyle(.glassProminent)
        .tint(.blue.opacity(colorScheme == .dark ? 0.5 : 0.8))
        .help("Download all result files")
        .scaleEffect(1.2)
        .disabled(!viewModel.canDownloadAll)
    }
    
    @ViewBuilder
    private var runAllButton: some View {
        Button {
            Task {
                do {
                    try await viewModel.runAllJobs(inModelContext: modelContext)
                } catch {
                    toastPresenter.showErrorToast(withMessage: error.localizedDescription)
                }
            }
        } label: {
            Label("Run all", systemImage: "play")
                .labelStyle(.titleAndIcon)
        }
        .buttonStyle(.glassProminent)
        .tint(.orange.opacity(colorScheme == .dark ? 0.5 : 0.8))
        .help("Run all files")
        .scaleEffect(1.2)
        .disabled(!viewModel.canRunAll)
    }
    
    @ViewBuilder
    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("The Gemini API key for this project (required)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack {
                ZStack(alignment: .trailing) {
                    Group {
                        if isAPIKeyVisible {
                            TextField("Enter your Gemini API Key", text: $viewModel.keychainManager.geminiAPIKey)
                        } else {
                            SecureField("Enter your Gemini API Key", text: $viewModel.keychainManager.geminiAPIKey)
                        }
                    }
                    .textFieldStyle(.plain)
                    .padding(6)
                    .padding(.trailing, !viewModel.keychainManager.geminiAPIKey.isEmpty ? 30 : 6)
                    
                    if !viewModel.keychainManager.geminiAPIKey.isEmpty {
                        Button(action: {
                            viewModel.keychainManager.geminiAPIKey = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .background(.background)
                        }
                        .buttonStyle(.borderless)
                        .padding(.trailing, 6)
                    }
                }
                .overlay(
                    ConcentricRectangle(corners: .fixed(8), isUniform: true)
                        .stroke(viewModel.keychainManager.geminiAPIKey.isEmpty ? .red.opacity(0.5) : .mint.opacity(0.3), lineWidth: 2)
                )
                
                Button(action: {
                    isAPIKeyVisible.toggle()
                }) {
                    Image(systemName: isAPIKeyVisible ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var modelSelectionPicker: some View {
        Picker("Gemini Model (required):", selection: $selectedGeminiModel) {
            ForEach(GeminiModel.allCases, id: \.self) { model in
                Text(model.displayName)
                    .tag(model)
            }
        }
        .pickerStyle(.menu)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func fileListView(_ files: [BatchFile]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            
            Text("Project Batch Files (\(files.count))")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            LazyVStack(spacing: 0) {
                ForEach(files) { file in
                    VStack(spacing: 0) {
                        FileRowView(
                            file: file,
                            fileBatchJob: batchJobsMap[file.id],
                            selectedBatchFile: $selectedBatchFile
                        )
                        .id(file.id)
                        
                        if file != files.last {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Download All Files
extension ProjectDetailView {
    
    private func downloadAllResultFiles() {
        let filesToDownload = project.batchFiles.filter { $0.resultPath != nil }
        
        guard !filesToDownload.isEmpty else {
            toastPresenter.showErrorToast(withMessage: "No result files available for download")
            return
        }
        
        // Use NSOpenPanel configured for folder selection
        let folderPanel = NSOpenPanel()
        folderPanel.title = "Choose Download Location"
        folderPanel.prompt = "Choose Folder"
        folderPanel.canChooseDirectories = true
        folderPanel.canChooseFiles = false
        folderPanel.canCreateDirectories = true
        folderPanel.allowsMultipleSelection = false
        
        folderPanel.begin { response in
            if response == .OK, let destinationFolder = folderPanel.url {
                Task {
                    await self.copyAllFilesToDestination(filesToDownload, destinationFolder: destinationFolder)
                }
            }
        }
    }
    
    private func copyAllFilesToDestination(_ files: [BatchFile], destinationFolder: URL) async {
        var successCount = 0
        var errorCount = 0
        var errors: [String] = []
        
        for file in files {
            guard let resultPath = file.resultPath else {
                errorCount += 1
                errors.append("No result file for \(file.name)")
                continue
            }
            
            let sourceURL = URL(fileURLWithPath: resultPath)
            let destinationURL = destinationFolder.appendingPathComponent(sourceURL.lastPathComponent)
            
            // Check if source file exists
            guard FileManager.default.fileExists(atPath: resultPath) else {
                errorCount += 1
                errors.append("Result file not found for \(file.name)")
                continue
            }
            
            do {
                // Remove existing file if it exists
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                // Copy the file
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                successCount += 1
            } catch {
                errorCount += 1
                errors.append("Failed to copy \(file.name): \(error.localizedDescription)")
            }
        }
        
        // Show results on main thread
        await MainActor.run {
            if successCount > 0 && errorCount == 0 {
                toastPresenter.showSuccessToast(withMessage: "Successfully downloaded \(successCount) result files")
            } else if successCount > 0 && errorCount > 0 {
                toastPresenter.showErrorToast(withMessage: "Downloaded \(successCount) files, \(errorCount) failed")
            } else {
                let errorMessage = errors.isEmpty ? "Failed to download any files" : errors.joined(separator: "; ")
                toastPresenter.showErrorToast(withMessage: errorMessage)
            }
        }
    }
}