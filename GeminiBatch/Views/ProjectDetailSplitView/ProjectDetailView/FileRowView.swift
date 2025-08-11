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
    @EnvironmentObject private var hide: SideHolder

    let file: BatchFile
    @Binding var selectedBatchFile: BatchFile?
    @Binding var selectedGeminiModel: GeminiModel?
    @Binding var keychainManager: ProjectKeychainManager
    @Binding var runningBatchJob: BatchJob?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.accentColor)
                FileDetailView(file: file)
                Spacer()
                runFileButton
                    .padding(.horizontal, 30)
            }
        }
        .padding()
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: Action Buttons
extension FileRowView {
    
    @ViewBuilder
    private var runFileButton: some View {
        Button {
            if let geminiModel = selectedGeminiModel {
                selectedBatchFile = file
                let batchJobManager = BatchJobManager(
                    geminiAPIKey: keychainManager.geminiAPIKey,
                    geminiModel: geminiModel,
                    batchJobID: file.batchJob.id,
                    modelContainer: modelContext.container
                )
                Task {
                    do {
                        try await batchJobManager.run()
                    } catch {
                        toastPresenter.showErrorToast(withMessage: error.localizedDescription)
                    }
                }
                runningBatchJob = file.batchJob
                withAnimation {
                    hide.side = nil
                }
            } else {
                toastPresenter.showErrorToast(withMessage: "Oops! The Gemini Model has not been selected. Please select it and try again.")
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
        .disabled(keychainManager.geminiAPIKey.isEmpty || selectedGeminiModel == nil)
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
    
    return FileRowView(
        file: file, 
        selectedBatchFile: .constant(nil),
        selectedGeminiModel: .constant(nil),
        keychainManager: .constant(ProjectKeychainManager(project: project)),
        runningBatchJob: .constant(nil)
    )
        .environment(ToastPresenter())
        .modelContainer(
            for: [Project.self, BatchFile.self],
            inMemory: true
        )
        .frame(width: 400)
        .padding()
}
