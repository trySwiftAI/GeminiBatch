//
//  ProjectFileError.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/6/25.
//

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
