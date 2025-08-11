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
    @State private var selectedGeminiModel: GeminiModel = .flash
    @State private var keychainManager: ProjectKeychainManager
    
    init(project: Project) {
        self.project = project
        self._keychainManager = State(initialValue: ProjectKeychainManager(project: project))
    }
    
    var body: some View {
        Split(
            primary: {
                ProjectDetailView(
                    project: project, 
                    selectedBatchFile: $selectedBatchFile,
                    selectedGeminiModel: $selectedGeminiModel,
                    keychainManager: $keychainManager
                )
                .environmentObject(hide)
            },
            secondary: {
                Text("Running")
//                RunView(
//                    project: project, 
//                    selectedBatchFile: $selectedBatchFile, 
//                    selectedGeminiModel: $selectedGeminiModel
//                )
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
