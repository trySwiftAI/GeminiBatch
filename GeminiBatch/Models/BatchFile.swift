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
    
    var name: String
    var originalPath: String
    var storedPath: String
    var fileSize: Int64
    var uploadedAt: Date
    var project: Project
    
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
}
