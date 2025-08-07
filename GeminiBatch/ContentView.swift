//
//  ContentView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var selectedProject: Project?
    
    var body: some View {
        NavigationSplitView {
            ProjectsView(selectedProject: $selectedProject)
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
        } detail: {
            if let project = selectedProject {
                ProjectDetailView(project: project)
                    .environment(ToastPresenter())
            } else {
                NoProjectSelectedView()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Project.self, inMemory: true)
}
