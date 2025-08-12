//
//  ProjectDetailSplitView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/7/25.
//

import SplitView
import SwiftUI

struct ProjectDetailSplitView: View {
    
    let project: Project
    
    @StateObject private var hide = SideHolder(.secondary)
    @State private var selectedBatchFile: BatchFile?
    @State private var selectedGeminiModel: GeminiModel = .pro
    @State private var keychainManager: ProjectKeychainManager
    @State private var runningBatchJob: BatchJob?
    
    init(project: Project) {
        self.project = project
        self._keychainManager = State(initialValue: ProjectKeychainManager(project: project))
        
        if let geminiModel = GeminiModel(rawValue: project.geminiModel) {
            self._selectedGeminiModel = State(initialValue: geminiModel)
        }
    }
    
    var body: some View {
        Split(
            primary: {
                ProjectDetailView(
                    project: project,
                    selectedBatchFile: $selectedBatchFile,
                    selectedGeminiModel: $selectedGeminiModel,
                    keychainManager: $keychainManager,
                    runningBatchJob: $runningBatchJob
                )
                .environmentObject(hide)
            },
            secondary: {
                RunView(runningBatchJob: $runningBatchJob)
            }
        )
        .splitter { Splitter.line() }
        .constraints(minPFraction: 0.3, minSFraction: 0.2, priority: .secondary, dragToHideS: true)
        .fraction(0.75)
        .hide(hide)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                toggleHideButton
            }
        }
        .onChange(of: project.id) {
            keychainManager = ProjectKeychainManager(project: project)
        }
        .onChange(of: selectedGeminiModel) {
            project.geminiModel = selectedGeminiModel.rawValue
        }
    }
}

extension ProjectDetailSplitView {
    @ViewBuilder
    private var toggleHideButton: some View {
        Button(
            action: {
                withAnimation {
                    hide.toggle(.secondary)
                }
            },
            label: {
                if hide.side == nil {
                    Image(systemName: "rectangle.righthalf.inset.filled.arrow.right")
                } else {
                    Image(systemName: "rectangle.lefthalf.inset.filled.arrow.left")
                }
            }
        )
    }
}
