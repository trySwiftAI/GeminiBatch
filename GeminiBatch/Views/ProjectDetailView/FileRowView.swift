//
//  FileRowView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/31/25.
//

import SwiftUI

struct FileRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow

    let file: BatchFile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        Label(file.formattedFileSize, systemImage: "info.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label(file.uploadedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button {
                        openFile(file)
                    } label: {
                        Image(systemName: "eye")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.borderless)
                    .help("View file")
                    
                    Button {
                        Task {
                            await deleteFile(file)
                        }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete file")
                }
            }
            
            // File path info
            Text(file.storedURL.path)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding()
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func openFile(_ file: BatchFile) {
        // TODO: Implement file viewing functionality
        NSWorkspace.shared.open(file.storedURL)
    }
    
    private func deleteFile(_ file: BatchFile) async {
        do {
            try await ProjectFileManager.deleteBatchFile(file, modelContext: modelContext)
        } catch {
            // TODO: Handle error - maybe show an alert
            print("Failed to delete file: \(error.localizedDescription)")
        }
    }
}
