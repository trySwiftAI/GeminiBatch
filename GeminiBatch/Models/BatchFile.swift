//
//  JSONLFile.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import Foundation
import SwiftData

@Model
final class BatchFile {
    
    var id: UUID = UUID()
    var name: String
    var originalPath: String
    var storedPath: String
    var resultPath: String? = nil
    var fileSize: Int64
    var uploadedAt: Date
    var project: Project
    
    @Relationship(deleteRule: .cascade, inverse: \BatchJob.batchFile)
    var batchJob: BatchJob
    var geminiFileURI: URL? = nil
    var geminiFileStatus: BatchFileStatus? = nil
    var geminiFileCreatedAt: Date? = nil
    var geminiFileExpirationTime: Date? = nil
    
    init(
        name: String,
        originalURL: URL,
        storedURL: URL,
        fileSize: Int64,
        project: Project
    ) {
        self.name = name
        self.originalPath = originalURL.path
        self.storedPath = storedURL.path
        self.fileSize = fileSize
        self.uploadedAt = Date()
        self.project = project
    }
}

extension BatchFile {
    
    var originalURL: URL {
        URL(fileURLWithPath: originalPath)
    }
    
    var storedURL: URL {
        URL(fileURLWithPath: storedPath)
    }
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var isGeminiFileExpired: Bool {
        guard let expirationTime = geminiFileExpirationTime else {
            return true // If no expiration time is set, consider it expired
        }
        return Date() > expirationTime
    }
    
}
