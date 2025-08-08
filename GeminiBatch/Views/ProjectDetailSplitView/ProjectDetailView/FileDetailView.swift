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
            
            Text(file.storedURL.path)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
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
                projectID: file.project.id.uuidString)
            .deleteBatchFile(file, inModelContext: modelContext)
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
    
    return FileDetailView(file: file)
        .environment(ToastPresenter())
        .modelContainer(
            for: [Project.self, BatchFile.self],
            inMemory: true
        )
        .frame(width: 400)
        .padding()
}
