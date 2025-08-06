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
    
    @MainActor
    func deleteBatchFile(
        _ file: BatchFile,
        inModelContext modelContext: ModelContext
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
            throw ProjectFileError.fileRemovalFailed(path: file.storedURL.path)
        }
        
        do {
            try await MainActor.run {
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
