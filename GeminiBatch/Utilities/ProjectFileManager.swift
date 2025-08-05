//
//  ProjectFileManager.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

struct ProjectFileManager {
    
    static private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static private let projectsDirectory = documentsDirectory.appendingPathComponent("GeminiBatch", isDirectory: true)
    
    static func processBatchFiles(
        fromURLs urls: [URL],
        forProject project: Project
    ) async throws -> [BatchFile] {
        do {
            let projectDirectory = projectDirectory(for: project)
            
            var processedBatchFiles: [BatchFile] = []
            for url in urls {
                guard url.pathExtension.lowercased() == "jsonl" else {
                    continue
                }
                
                let fileName = url.lastPathComponent
                let destinationURL = projectDirectory.appendingPathComponent(fileName)
                
                let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
                
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                try FileManager.default.copyItem(at: url, to: destinationURL)
                
                let batchFile = BatchFile(
                    name: fileName,
                    originalURL: url,
                    storedURL: destinationURL,
                    fileSize: fileSize,
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
    ) async throws {
        if FileManager.default.fileExists(atPath: file.storedURL.path) {
            try FileManager.default.removeItem(at: file.storedURL)
        }
        modelContext.delete(file)
        try modelContext.save()
    }
    
    static func deleteProjectDirectory(for project: Project) async throws {
        let projectDirectory = projectDirectory(for: project)
        if FileManager.default.fileExists(atPath: projectDirectory.path) {
            try FileManager.default.removeItem(at: projectDirectory)
        }
    }
}

extension ProjectFileManager {
    
    private static func projectDirectory(
        for project: Project
    ) -> URL {
        let projectDirectoryName = projectDirectoryName(from: project.name)
        let projectDirectory = projectsDirectory.appendingPathComponent(projectDirectoryName, isDirectory: true)
        
        if FileManager.default.fileExists(atPath: projectDirectory.path) {
            return projectDirectory
        }
        
        createProjectsDirectoryIfNeeded()
        try? FileManager.default.createDirectory(at: projectDirectory, withIntermediateDirectories: true)
        return projectDirectory
    }
    
    private static func createProjectsDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: Self.projectsDirectory.path) {
            try? FileManager.default.createDirectory(
                at: Self.projectsDirectory,
                withIntermediateDirectories: true
            )
        }
    }
    
    private static func projectDirectoryName(from name: String) -> String {
        // Remove special characters, keep only alphanumeric and spaces
        let cleaned = name.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: " ")
        
        // Split by spaces, filter out empty strings, and join with underscores
        let words = cleaned.components(separatedBy: " ").filter { !$0.isEmpty }
        
        return words.joined(separator: "_").lowercased()
    }
}
