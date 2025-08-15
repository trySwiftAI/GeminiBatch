//
//  ProjectViewModel.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/15/25.
//

import SwiftUI

@Observable
final class ProjectViewModel {
    
    let project: Project
    
    var hideSideView: Bool = true
    var selectedBatchFile: BatchFile?
    var selectedGeminiModel: GeminiModel = .pro
    var keychainManager: ProjectKeychainManager
    var runningBatchJob: BatchJob?
    
    init(project: Project) {
        self.project = project
        self.keychainManager = ProjectKeychainManager(project: project)
        
        if let geminiModel = GeminiModel(rawValue: project.geminiModel) {
            self.selectedGeminiModel = geminiModel
        }
    }
}
