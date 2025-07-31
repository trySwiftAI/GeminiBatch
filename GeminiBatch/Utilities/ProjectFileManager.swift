//
//  ProjectFileManager.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import Foundation
import UniformTypeIdentifiers
import SwiftData

class ProjectFileManager {
    static let shared = ProjectFileManager()
    
    private let documentsDirectory: URL
    private let projectsDirectory: URL
    
    private init() {
        self.documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.projectsDirectory = documentsDirectory.appendingPathComponent("GeminiBatch", isDirectory: true)
        
        createProjectsDirectoryIfNeeded()
    }
    
    private func createProjectsDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: projectsDirectory.path) {
            try? FileManager.default.createDirectory(at: projectsDirectory, withIntermediateDirectories: true)
        }
    }
    
    func createProjectDirectory(for project: Project) -> URL {
        let projectDir = projectsDirectory.appendingPathComponent(project.persistentModelID.hashValue.description, isDirectory: true)
        try? FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        return projectDir
    }
    
    func storeJSONLFiles(
        for project: Project,
        from urls: [URL],
        modelContext: ModelContext
    ) async throws -> [BatchFile] {
        let projectDir = createProjectDirectory(for: project)
        var jsonlFiles: [BatchFile] = []
        
        for url in urls {
            // Check if it's a JSONL file
            guard url.pathExtension.lowercased() == "jsonl" else {
                continue
            }
            
            let fileName = url.lastPathComponent
            let destinationURL = projectDir.appendingPathComponent(fileName)
            
            // Get file size
            let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
            
            // Copy file to project directory
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            let jsonlFile = BatchFile(
                name: fileName,
                originalURL: url,
                storedURL: destinationURL,
                fileSize: fileSize,
                project: project
            )
            
            modelContext.insert(jsonlFile)
            jsonlFiles.append(jsonlFile)
        }
        
        try modelContext.save()
        return jsonlFiles
    }
    
    func deleteJSONLFile(_ file: BatchFile, modelContext: ModelContext) throws {
        if FileManager.default.fileExists(atPath: file.storedURL.path) {
            try FileManager.default.removeItem(at: file.storedURL)
        }
        modelContext.delete(file)
        try modelContext.save()
    }
    
    func deleteProjectDirectory(for project: Project) throws {
        let projectDir = projectsDirectory.appendingPathComponent(project.persistentModelID.hashValue.description, isDirectory: true)
        if FileManager.default.fileExists(atPath: projectDir.path) {
            try FileManager.default.removeItem(at: projectDir)
        }
    }
    
    func getFileContent(for file: BatchFile) throws -> String {
        return try String(contentsOf: file.storedURL, encoding: .utf8)
    }
    
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
