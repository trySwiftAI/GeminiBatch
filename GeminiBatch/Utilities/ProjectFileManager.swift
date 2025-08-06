//
//  ProjectFileManager.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

actor ProjectFileManager {
    
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let projectsDirectory: URL
    private let projectDirectory: URL
    
    private let project: Project
    
    @MainActor
    init(project: Project) {
        self.project = project
        self.projectsDirectory = documentsDirectory.appendingPathComponent("GeminiBatch", isDirectory: true)
        self.projectDirectory = self.projectsDirectory.appendingPathComponent(
            project.id.uuidString,
            isDirectory: true
        )
    }
        
    func processBatchFiles(
        fromURLs urls: [URL]
    ) async throws -> [BatchFile] {
        let projectID = await MainActor.run { project.id }
        let projectDirectory = try await createProjectDirectoryIfNeeded()
        let batchFilesData: [BatchFileData] = try await processFileURLs(urls)

        return await MainActor.run {
            batchFilesData.map { fileData in
                BatchFile(
                    name: fileData.name,
                    originalURL: fileData.originalURL,
                    storedURL: fileData.storedURL,
                    fileSize: fileData.fileSize,
                    project: project
                )
            }
        }
    }
    
    func deleteBatchFile(
        _ file: BatchFile
    ) async throws(ProjectFileError) {
        do {
            try await Task.detached {
                if await FileManager.default.fileExists(atPath: file.storedURL.path) {
                    do {
                        try await FileManager.default.removeItem(at: file.storedURL)
                    } catch let error as CocoaError {
                        switch error.code {
                        case .fileReadNoPermission, .fileWriteNoPermission:
                            throw await ProjectFileError.permissionDenied(
                                operation: "file deletion",
                                path: file.storedURL.path
                            )
                        default:
                            throw await ProjectFileError.fileRemovalFailed(path: file.storedURL.path)
                        }
                    } catch {
                        throw await ProjectFileError.fileRemovalFailed(path: file.storedURL.path)
                    }
                }
            }.value
        } catch let error as ProjectFileError {
            throw error
        } catch {
            throw await ProjectFileError.fileRemovalFailed(path: file.storedURL.path)
        }
        
        do {
            try await MainActor.run {
                guard let modelContext = file.modelContext else { return }
                modelContext.delete(file)
                try modelContext.save()
            }
        } catch {
            throw ProjectFileError.modelContextSaveFailed(reason: error.localizedDescription)
        }
    }
    
    func deleteProjectDirectory(
        forProjectID projectID: UUID
    ) async throws(ProjectFileError) {
        let projectDirectory = try await getProjectDirectory(forProjectID: projectID.uuidString)
        
        do {
            try await Task.detached {
                if FileManager.default.fileExists(atPath: projectDirectory.path) {
                    do {
                        try FileManager.default.removeItem(at: projectDirectory)
                    } catch let error as CocoaError {
                        switch error.code {
                        case .fileReadNoPermission, .fileWriteNoPermission:
                            throw ProjectFileError.permissionDenied(
                                operation: "directory deletion",
                                path: projectDirectory.path
                            )
                        default:
                            throw ProjectFileError.fileRemovalFailed(path: projectDirectory.path)
                        }
                    } catch {
                        throw ProjectFileError.fileRemovalFailed(path: projectDirectory.path)
                    }
                }
            }.value
        } catch let error as ProjectFileError {
            throw error
        } catch {
            throw ProjectFileError.fileRemovalFailed(path: projectDirectory.path)
        }
    }
}

// MARK: - Private Extensions

extension ProjectFileManager {
    
    private struct BatchFileData {
        var name: String
        var originalURL: URL
        var storedURL: URL
        var fileSize: Int64
    }
    
    private func processFileURLs(
        _ urls: [URL]
    ) async throws -> [BatchFileData] {
        
        do {
            return try await Task.detached {
                var processedBatchFilesData: [BatchFileData] = []
                
                for url in urls {
                    // Validate file type
                    guard url.pathExtension.lowercased() == "jsonl" else {
                        throw ProjectFileError.invalidFileType(
                            fileName: url.lastPathComponent,
                            expectedType: "JSONL"
                        )
                    }
                    
                    let fileName = url.lastPathComponent
                    let destinationURL = self.projectDirectory.appendingPathComponent(fileName)
                    
                    // Get file size
                    let fileSize: Int64
                    do {
                        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                        fileSize = attributes[.size] as? Int64 ?? 0
                    } catch {
                        throw ProjectFileError.fileAttributesUnavailable(path: url.path)
                    }
                    
                    // Remove existing file if it exists
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        do {
                            try FileManager.default.removeItem(at: destinationURL)
                        } catch {
                            throw ProjectFileError.fileRemovalFailed(path: destinationURL.path)
                        }
                    }
                    
                    // Copy file to destination
                    do {
                        try FileManager.default.copyItem(at: url, to: destinationURL)
                    } catch let error as CocoaError {
                        switch error.code {
                        case .fileNoSuchFile:
                            throw ProjectFileError.fileNotFound(path: url.path)
                        case .fileReadNoPermission, .fileWriteNoPermission:
                            throw ProjectFileError.permissionDenied(
                                operation: "file copy",
                                path: destinationURL.path
                            )
                        default:
                            throw ProjectFileError.fileCopyFailed(
                                source: url.path,
                                destination: destinationURL.path
                            )
                        }
                    } catch {
                        throw ProjectFileError.fileCopyFailed(
                            source: url.path,
                            destination: destinationURL.path
                        )
                    }

                    let batchFileData = BatchFileData(
                        name: fileName,
                        originalURL: url,
                        storedURL: destinationURL,
                        fileSize: fileSize
                    )
                    processedBatchFilesData.append(batchFileData)
                }
                
                return processedBatchFilesData
            }.value
        } catch let error as ProjectFileError {
            throw error
        } catch {
            throw ProjectFileError.fileCopyFailed(source: "multiple", destination: projectDirectory.path)
        }
    }
    
    private func createProjectDirectoryIfNeeded() async throws(ProjectFileError) -> URL {
        do {
            return try await Task.detached {
                if FileManager.default.fileExists(atPath: self.projectDirectory.path) {
                    return self.projectDirectory
                }
                
                try await self.createProjectsDirectoryIfNeeded()
                
                do {
                    try FileManager.default.createDirectory(at: self.projectDirectory, withIntermediateDirectories: true)
                } catch {
                    throw ProjectFileError.directoryCreationFailed(path: self.projectDirectory.path)
                }
                
                return self.projectDirectory
            }.value
        } catch let error as ProjectFileError {
            throw error
        } catch {
            throw ProjectFileError.directoryCreationFailed(path: projectsDirectory.path)
        }
    }
    
    private func getProjectDirectory(
        forProjectID projectID: String
    ) async throws(ProjectFileError) -> URL {
        do {
            return try await Task.detached {
                let projectDirectory = self.projectsDirectory.appendingPathComponent(
                    projectID,
                    isDirectory: true
                )
                
                guard FileManager.default.fileExists(atPath: projectDirectory.path) else {
                    throw ProjectFileError.fileNotFound(path: projectDirectory.path)
                }
                
                return projectDirectory
            }.value
        } catch let error as ProjectFileError {
            throw error
        } catch {
            throw ProjectFileError.fileNotFound(path: "project directory")
        }
    }
    
    private func createProjectsDirectoryIfNeeded() throws(ProjectFileError) {
        guard !FileManager.default.fileExists(atPath: self.projectsDirectory.path) else {
            return
        }
        
        do {
            try FileManager.default.createDirectory(
                at: self.projectsDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            throw ProjectFileError.directoryCreationFailed(path: self.projectsDirectory.path)
        }
    }
}

enum ProjectFileError: Error, CustomStringConvertible {
    case invalidFileType(fileName: String, expectedType: String)
    case fileNotFound(path: String)
    case permissionDenied(operation: String, path: String)
    case directoryCreationFailed(path: String)
    case fileCopyFailed(source: String, destination: String)
    case fileRemovalFailed(path: String)
    case fileAttributesUnavailable(path: String)
    case modelContextSaveFailed(reason: String)
    
    var description: String {
        switch self {
        case .invalidFileType(let fileName, let expectedType):
            return "Invalid file type for '\(fileName)'. Expected \(expectedType) files only."
        case .fileNotFound(let path):
            return "File not found at path: \(path)"
        case .permissionDenied(let operation, let path):
            return "Permission denied for \(operation) at path: \(path)"
        case .directoryCreationFailed(let path):
            return "Failed to create directory at path: \(path)"
        case .fileCopyFailed(let source, let destination):
            return "Failed to copy file from '\(source)' to '\(destination)'"
        case .fileRemovalFailed(let path):
            return "Failed to remove file at path: \(path)"
        case .fileAttributesUnavailable(let path):
            return "Unable to read file attributes for: \(path)"
        case .modelContextSaveFailed(let reason):
            return "Failed to save model context: \(reason)"
        }
    }
    
    var localizedDescription: String {
        return description
    }
    
    var failureReason: String {
        switch self {
        case .invalidFileType:
            return "The selected file is not a supported JSONL file."
        case .fileNotFound:
            return "The requested file could not be located."
        case .permissionDenied:
            return "You don't have permission to perform this operation."
        case .directoryCreationFailed:
            return "The system could not create the required directory."
        case .fileCopyFailed:
            return "The file could not be copied to the destination."
        case .fileRemovalFailed:
            return "The file could not be deleted."
        case .fileAttributesUnavailable:
            return "The file's information could not be read."
        case .modelContextSaveFailed:
            return "The data could not be saved to the database."
        }
    }
    
    var recoverySuggestion: String {
        switch self {
        case .invalidFileType:
            return "Please select only JSONL files for batch processing."
        case .fileNotFound:
            return "Please verify the file path and try again."
        case .permissionDenied:
            return "Please check file permissions or try running with appropriate privileges."
        case .directoryCreationFailed:
            return "Please check available disk space and permissions."
        case .fileCopyFailed:
            return "Please ensure there's enough disk space and try again."
        case .fileRemovalFailed:
            return "Please check if the file is in use by another application."
        case .fileAttributesUnavailable:
            return "Please verify the file exists and is accessible."
        case .modelContextSaveFailed:
            return "Please try the operation again or restart the application."
        }
    }
}
