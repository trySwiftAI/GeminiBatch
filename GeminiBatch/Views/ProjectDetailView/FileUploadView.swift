import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct FileUploadView: View {
    @Environment(\.modelContext) private var modelContext
    
    let project: Project
    
    @State private var isDragOver = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var showingFilePicker = false
    
    @State private var errorMessage: String?
    @State private var successMessage: String?
        
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Text("Upload Files")
                .font(.title2)
                .fontWeight(.semibold)
            
            uploadArea
            
            // Progress indicator
            if isUploading {
                uploadProgressView
            }
            
            // Messages
            if let errorMessage = errorMessage {
                errorMessageView(errorMessage)
            }
            
            if let successMessage = successMessage {
                successMessageView(successMessage)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.text],
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
            
            Text("Supported formats: .jsonl")
                .font(.caption)
                .foregroundColor(.secondary)
        }
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
    
    private func errorMessageView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
            
            Spacer()
            
            Button("Dismiss") {
                errorMessage = nil
            }
            .font(.caption)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func successMessageView(_ message: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.green)
            
            Spacer()
            
            Button("Dismiss") {
                successMessage = nil
            }
            .font(.caption)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        let urls = providers.compactMap { provider in
            provider.loadObject(ofClass: URL.self) { url, error in
                if let url = url {
                    DispatchQueue.main.async {
                        processFiles([url], for: project)
                    }
                }
            }
        }
        
        return !urls.isEmpty
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {        
        switch result {
        case .success(let urls):
            processFiles(urls, for: project)
        case .failure(let error):
            errorMessage = "Failed to import files: \(error.localizedDescription)"
        }
    }
    
    private func processFiles(_ urls: [URL], for project: Project) {
        guard !urls.isEmpty else { return }
        
        isUploading = true
        uploadProgress = 0.0
        errorMessage = nil
        successMessage = nil
        
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
                        successMessage = "Successfully uploaded \(uploadedBatchFilesCount) file\(uploadedBatchFilesCount == 1 ? "" : "s")"
                    }
                    
                    uploadProgress = 1.0
                    
                    // Hide progress after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isUploading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to upload files: \(error.localizedDescription)"
                    isUploading = false
                }
            }
        }
    }
}
