//
//  ProjectsView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Project.createdAt, order: .reverse)
    private var projects: [Project]
    
    @Binding var selectedProject: Project?
    
    @State private var currentError: ProjectError?
    
    var body: some View {
        VStack(spacing: 0) {
            projectsHeader
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(projects, id: \.self) { project in
                        ProjectView(
                            project: project,
                            selectedProject: $selectedProject,
                            currentError: $currentError
                        )
                    }
                }
                .padding()
            }
        }
        .alert(item: $currentError) { error in
            Alert(
                title: Text(error.type.title),
                message: Text(error.errorDescription),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            if !projects.isEmpty {
                selectedProject = projects.first
            }
        }
    }
    
    @ViewBuilder
    var projectsHeader: some View {
        HStack {
            Text("Projects")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: {
                addProject()
            }) {
                Label("Add Project", systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 20, weight: .semibold))
                    .padding(3)
            }
            .buttonStyle(.borderless)
            .glassEffect(.regular.interactive())
        }
        .padding()
    }
}

// MARK: Project Actions
extension ProjectsView {
    
    private func addProject() {
        let newProject = Project(name: "My Project")
        modelContext.insert(newProject)
        
        do {
            try modelContext.save()
            selectedProject = newProject 
        } catch {
            currentError = ProjectError(type: .createProject, underlyingError: error)
        }
    }
}

#Preview {
    ProjectsView(selectedProject: .constant(nil))
        .frame(width: 250)
        .modelContainer(for: Project.self, inMemory: true)
}
