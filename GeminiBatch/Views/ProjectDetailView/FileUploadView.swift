import Foundation
import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct FileUploadView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ToastPresenter.self) private var toastPresenter
    
    let project: Project
    
    @State private var isDragOver = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var showingFilePicker = false
        
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Text("Upload Files")
                .font(.title2)
                .fontWeight(.semibold)
            
            uploadArea
            
            if isUploading {
                uploadProgressView
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.jsonl],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
    }
    
    private var uploadArea: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(isDragOver ? .accentColor : .secondary)
            
            Text("Drop JSONL files here")
                .font(.headline)
                .foregroundColor(isDragOver ? .accentColor : .primary)
            
            Text("or")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Browse Files") {
                showingFilePicker = true
            }
            .buttonStyle(.borderedProminent)
            
            Text("Supported format: .jsonl")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDragOver ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isDragOver ? Color.accentColor : Color.gray.opacity(0.5),
                            style: StrokeStyle(lineWidth: 2, dash: [10, 5])
                        )
                )
        )
        .onDrop(of: [UTType.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers)
        }
    }
    
    private var uploadProgressView: some View {
        VStack(spacing: 8) {
            ProgressView("Uploading files...", value: uploadProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("\(Int(uploadProgress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard !providers.isEmpty else { return false }
    
        Task {
            var collectedURLs: [URL] = []
            
            for provider in providers {
                do {
                    if let url = try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<URL?, Error>) in
                        _ = provider.loadObject(ofClass: URL.self) { url, error in
                            if let error = error {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume(returning: url)
                            }
                        }
                    }) {
                        collectedURLs.append(url)
                    }
                } catch {
                    // Continue with other providers if one fails
                    continue
                }
            }
            
            if !collectedURLs.isEmpty {
                await MainActor.run {
                    processFiles(collectedURLs, for: project)
                }
            }
        }
        
        return true
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            processFiles(urls, for: project)
        case .failure(let error):
            let errorMessage = "Failed to import files: \(error.localizedDescription)"
            toastPresenter.showErrorToast(withMessage: errorMessage)
        }
    }
    
    private func processFiles(_ urls: [URL], for project: Project) {
        guard !urls.isEmpty else { return }
        isUploading = true
        uploadProgress = 0.0
        toastPresenter.hideToast()
        
        Task {
            do {
                let processedBatchFiles = try await ProjectFileManager(project: project).processBatchFiles(fromURLs: urls)
                
                try await MainActor.run {
                    for processedBatchFile in processedBatchFiles {
                        modelContext.insert(processedBatchFile)
                    }
                    try modelContext.save()
                    
                    let uploadedBatchFilesCount = processedBatchFiles.count
                    if uploadedBatchFilesCount > 0 {
                        let successMessage = "Successfully uploaded \(uploadedBatchFilesCount) file\(uploadedBatchFilesCount == 1 ? "" : "s")"
                        toastPresenter.showSuccessToast(withMessage: successMessage)
                    }
                    
                    uploadProgress = 1.0
                    
                    // Hide progress after a short delay
                    Task {
                        try await Task.sleep(for: .seconds(1))
                        isUploading = false
                    }
                }
            } catch {
                await MainActor.run {
                    let errorMessage = "Failed to upload files: \(String(describing: error))"
                    toastPresenter.showErrorToast(withMessage: errorMessage)
                    isUploading = false
                }
            }
        }
    }
}

#Preview {
    let project = Project(name: "Sample Project")
    
    FileUploadView(project: project)
    .modelContainer(
        for: [Project.self],
        inMemory: true
    )
    .environment(ToastPresenter())
}
