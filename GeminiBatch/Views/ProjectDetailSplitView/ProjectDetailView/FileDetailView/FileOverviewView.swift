//
//  FileOverviewView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/18/25.
//

import SwiftData
import SwiftUI

struct FileOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @Environment(ToastPresenter.self) private var toastPresenter
    
    let file: BatchFile
    
    var body: some View {
        VStack(alignment: .leading) {
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
        }
    }
}

extension FileOverviewView {
    
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
        .tint(.gray)
        .buttonBorderShape(.circle)
        .help("Delete file")
        .padding(4)
    }
}

extension FileOverviewView {
    
    private func openFile(_ file: BatchFile) {
        NSWorkspace.shared.open(file.storedURL)
    }
    
    private func deleteFile(_ file: BatchFile) async {
        do {
            try await ProjectFileManager(
                projectID: file.project.id.uuidString
            ).deleteBatchFile(
                fileId: file.id,
                using: .init(modelContainer: modelContext.container)
            )
        } catch {
            let errorMessage = "Failed to delete file: \(error.localizedDescription)"
            toastPresenter.showErrorToast(withMessage: errorMessage)
        }
    }
}

#Preview {
    let sampleProject = Project(name: "Sample Project")
    
    let sampleFile = BatchFile(
        name: "sample_data.jsonl",
        originalURL: URL(fileURLWithPath: "/path/to/sample_data.jsonl"),
        storedURL: URL(fileURLWithPath: "/stored/path/sample_data.jsonl"),
        fileSize: 2048576, // 2 MB
        project: sampleProject
    )
    
    return FileOverviewView(file: sampleFile)
        .environment(ToastPresenter())
        .padding()
}
