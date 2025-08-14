//
//  BatchFileModelActor.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/10/25.
//

import Foundation
import SwiftData

@ModelActor
actor BatchFileModelActor {
    
    func fetchBatchFile(id: PersistentIdentifier) -> BatchFile? {
        return modelContext.model(for: id) as? BatchFile
    }
    
    func deleteBatchFile(id: PersistentIdentifier) throws {
        guard let batchFile = modelContext.model(for: id) as? BatchFile else {
            throw BatchFileModelActorError.batchFileNotFound
        }
        
        modelContext.delete(batchFile)
        try modelContext.save()
    }
    
    func updateResultPath(id: PersistentIdentifier, resultPath: String) throws {
        guard let batchFile = modelContext.model(for: id) as? BatchFile else {
            throw BatchFileModelActorError.batchFileNotFound
        }
        
        batchFile.resultPath = resultPath
        try modelContext.save()
    }
    
    func getBatchFileInfo(id: PersistentIdentifier) -> BatchFileInfo? {
        guard let batchFile = modelContext.model(for: id) as? BatchFile else {
            return nil
        }
        
        return BatchFileInfo(
            id: batchFile.id,
            name: batchFile.name,
            storedURL: batchFile.storedURL,
            resultPath: batchFile.resultPath,
            fileSize: batchFile.fileSize,
            uploadedAt: batchFile.uploadedAt,
            projectId: batchFile.project.id
        )
    }
}

enum BatchFileModelActorError: Error, LocalizedError {
    case batchFileNotFound
    case modelContextSaveFailed(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .batchFileNotFound:
            return "Batch file could not be found"
        case .modelContextSaveFailed(let reason):
            return "Failed to save model context: \(reason)"
        }
    }
}

extension BatchFileModelActor {
    struct BatchFileInfo: Sendable {
        let id: UUID
        let name: String
        let storedURL: URL
        let resultPath: String?
        let fileSize: Int64
        let uploadedAt: Date
        let projectId: UUID
    }
}
