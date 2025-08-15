//
//  FileRowView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/31/25.
//

import SplitView
import SwiftData
import SwiftUI

struct FileRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ToastPresenter.self) private var toastPresenter
    @Environment(ProjectViewModel.self) private var viewModel
    
    let file: BatchFile
    
    @State private var batchJobManager: BatchJobManager? = nil
    @State private var canBeRun: Bool = false
    
    private var runButtonDisabled: Bool {
        return viewModel.keychainManager.geminiAPIKey.isEmpty ||
        !canBeRun
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.accentColor)
                FileDetailView(file: file)
                Spacer()
                runFileButton
            }
        }
        .padding()
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .task {
            setupBatchJobIfNeeded()
            updateCanBeRunState()
        }
    }
}

// MARK: Action Buttons
extension FileRowView {
    
    @ViewBuilder
    private var runFileButton: some View {
        Button {
            Task {
                do {
                    try await viewModel.runJob(forFile: file, inModelContext: modelContext)
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
        .disabled(runButtonDisabled)
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
    
    private func updateCanBeRunState() {
        guard let batchJob = file.batchJob else {
            canBeRun = true
            return
        }
        
        if batchJob.isExpired {
            canBeRun = false
            return
        }
        
        switch batchJob.jobStatus {
        case .failed, .cancelled, .expired, .jobFileDownloaded:
            canBeRun = false
        case .notStarted, .fileUploaded, .unspecified, .pending, .running, .succeeded:
            canBeRun = true
        }
    }
}
