//
//  ProjectError.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import Foundation

struct ProjectError: Error, Identifiable, Equatable, LocalizedError {
    let id = UUID()
    let type: ErrorType
    let underlyingError: Error?
    
    enum ErrorType {
        case createProject
        case updateProject
        case deleteProject
        case saveChanges
        case loadProjects
        case validation(String)
        
        var title: String {
            switch self {
            case .createProject:
                return "Create Project Failed"
            case .updateProject:
                return "Update Project Failed"
            case .deleteProject:
                return "Delete Project Failed"
            case .saveChanges:
                return "Save Changes Failed"
            case .loadProjects:
                return "Load Projects Failed"
            case .validation:
                return "Validation Error"
            }
        }
        
        var message: String {
            switch self {
            case .createProject:
                return "Unable to create a new project. Please try again."
            case .updateProject:
                return "Unable to update the project. Your changes may not be saved."
            case .deleteProject:
                return "Unable to delete the project. Please try again."
            case .saveChanges:
                return "Unable to save your changes. Please try again."
            case .loadProjects:
                return "Unable to load projects. Please restart the app."
            case .validation(let message):
                return message
            }
        }
    }
    
    init(type: ErrorType, underlyingError: Error? = nil) {
        self.type = type
        self.underlyingError = underlyingError
    }
    
    @MainActor
    var errorDescription: String {
        return type.message
    }
    
    var failureReason: String? {
        return String(describing: underlyingError)
    }
    
    // MARK: - Equatable
    static func == (lhs: ProjectError, rhs: ProjectError) -> Bool {
        return lhs.id == rhs.id
    }
}
