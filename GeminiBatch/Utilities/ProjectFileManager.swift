//
//  ProjectFileManager.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

nonisolated struct ProjectFileManager {
    
    static private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static private let projectsDirectory = documentsDirectory.appendingPathComponent("GeminiBatch", isDirectory: true)
    
    static func processBatchFiles(
        fromURLs urls: [URL],
        forProject project: Project
    ) async throws -> [BatchFile] {
        let projectID = await MainActor.run { project.id }
        let projectDirectory = try projectDirectory(forProjectID: projectID.uuidString)
        let batchFilesData: [BatchFileData] = try await processFileURLs(urls, inProjectDirectory: projectDirectory)

        return await MainActor.run {
            var processedBatchFiles: [BatchFile] = []
            for fileData in batchFilesData {
                let batchFile = BatchFile(
                    name: fileData.name,
                    originalURL: fileData.originalURL,
                    storedURL: fileData.storedURL,
                    fileSize: fileData.fileSize,
                    project: project
                )
                processedBatchFiles.append(batchFile)
            }
            return processedBatchFiles
        }
    }
    
    @MainActor
    static func deleteBatchFile(
        _ file: BatchFile,
        modelContext: ModelContext
    ) async throws(ProjectFileError) {
        // Remove file from filesystem
        if FileManager.default.fileExists(atPath: file.storedURL.path) {
            do {
                try FileManager.default.removeItem(at: file.storedURL)
            } catch {
                if let nsError = error as NSError?, nsError.code == NSFileReadNoPermissionError {
                    throw ProjectFileError.permissionDenied(
                        operation: "file deletion",
                        path: file.storedURL.path
                    )
                } else {
                    throw ProjectFileError.fileRemovalFailed(path: file.storedURL.path)
                }
            }
        }
        
        // Remove from model context
        modelContext.delete(file)
        
        do {
            try modelContext.save()
        } catch {
            throw ProjectFileError.modelContextSaveFailed(reason: error.localizedDescription)
        }
    }
    
    static func deleteProjectDirectory(
        forProjectID projectID: UUID
    ) async throws(
        ProjectFileError
    ) {
        let projectDirectory = try projectDirectory(forProjectID: projectID.uuidString)
        
        if FileManager.default.fileExists(atPath: projectDirectory.path) {
            do {
                try FileManager.default.removeItem(at: projectDirectory)
            } catch {
                if let nsError = error as NSError?, nsError.code == NSFileReadNoPermissionError {
                    throw ProjectFileError.permissionDenied(
                        operation: "directory deletion",
                        path: projectDirectory.path
                    )
                } else {
                    throw ProjectFileError.fileRemovalFailed(path: projectDirectory.path)
                }
            }
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
    
    private static func processFileURLs(
        _ urls: [URL],
        inProjectDirectory projectDirectory: URL
    ) async throws -> [BatchFileData] {
        
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
            let destinationURL = projectDirectory.appendingPathComponent(fileName)
            
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
            } catch {
                if let nsError = error as NSError? {
                    switch nsError.code {
                    case NSFileNoSuchFileError:
                        throw ProjectFileError.fileNotFound(path: url.path)
                    case NSFileReadNoPermissionError, NSFileWriteNoPermissionError:
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
                } else {
                    throw ProjectFileError.fileCopyFailed(
                        source: url.path,
                        destination: destinationURL.path
                    )
                }
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
    }
    
    private static func projectDirectory(
        forProjectID projectID: String
    ) throws(ProjectFileError) -> URL {
        let projectDirectory = projectsDirectory.appendingPathComponent(
            projectID,
            isDirectory: true
        )
        
        if FileManager.default.fileExists(atPath: projectDirectory.path) {
            return projectDirectory
        }
        
        try createProjectsDirectoryIfNeeded()
        
        do {
            try FileManager.default.createDirectory(at: projectDirectory, withIntermediateDirectories: true)
        } catch {
            throw ProjectFileError.directoryCreationFailed(path: projectDirectory.path)
        }
        
        return projectDirectory
    }
    
    private static func createProjectsDirectoryIfNeeded() throws(ProjectFileError) {
        guard !FileManager.default.fileExists(atPath: Self.projectsDirectory.path) else {
            return
        }
        
        do {
            try FileManager.default.createDirectory(
                at: Self.projectsDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            throw ProjectFileError.directoryCreationFailed(path: Self.projectsDirectory.path)
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
