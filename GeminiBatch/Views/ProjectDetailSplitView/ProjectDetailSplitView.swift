//
//  ProjectDetailSplitView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/7/25.
//

import SplitView
import SwiftUI
import SwiftData

struct ProjectDetailSplitView: View {
    @Environment(\.modelContext) private var modelContext
        
    @StateObject private var hide = SideHolder(.secondary)
    
    @State var viewModel: ProjectViewModel
        
    init(project: Project) {
        viewModel = .init(project: project)
    }
    
    var body: some View {
        Split(
            primary: {
                ProjectDetailView()
                .environment(viewModel)
            },
            secondary: {
                RunView()
                    .environment(viewModel)
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
        .onChange(of: viewModel.selectedBatchFile) {
            if viewModel.selectedBatchFile == nil {
                withAnimation {
                    hide.side = .secondary
                }
            } else {
                withAnimation {
                    hide.side = nil
                }
            }
        }
        .onChange(of: viewModel.project.id) {
            viewModel.keychainManager = ProjectKeychainManager(project: viewModel.project)
        }
        .onChange(of: viewModel.selectedGeminiModel) {
            viewModel.project.geminiModel = viewModel.selectedGeminiModel.rawValue
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
