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
    @Query private var projects: [Project]
    @Query private var batchFiles: [BatchFile]
    @Query private var batchJobs: [BatchJob]
    
    @StateObject private var hide = SideHolder(.secondary)
    
    @State var selectedBatchFile: BatchFile? = nil
    
    private var project: Project? {
        projects.first
    }
    
    init(project: Project) {
        let projectId = project.id
        self._projects = Query(filter: #Predicate { $0.id == projectId })
        self._batchFiles = Query(
            filter: #Predicate<BatchFile> { $0.project.id == projectId },
            sort: \BatchFile.uploadedAt
        )
        self._batchJobs = Query(
            filter: #Predicate<BatchJob> { $0.batchFile.project.id == projectId }
        )
    }
    
    var body: some View {
        Split(
            primary: {
                if let project = project {
                    ProjectDetailView(
                        project: project,
                        batchFiles: batchFiles,
                        batchJobs: batchJobs,
                        selectedBatchFile: $selectedBatchFile
                    )
                } else {
                    NoProjectSelectedView()
                }
            },
            secondary: {
                if let batchFile = selectedBatchFile {
                    RunView(batchFileID: batchFile.id)
                } else {
                    EmptyView()
                }
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
        .onChange(of: selectedBatchFile) {
            if selectedBatchFile == nil {
                withAnimation {
                    hide.side = .secondary
                }
            } else {
                withAnimation {
                    hide.side = nil
                }
            }
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
