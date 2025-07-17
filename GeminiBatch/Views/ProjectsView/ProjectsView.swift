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
    
    @State private var editingProject: Project?
    
    
    @State private var currentError: ProjectError?
    
    var body: some View {
        List {
            Section {
                ForEach(projects, id: \.self) { project in
                    ProjectView(
                        project: project,
                        selectedProject: $selectedProject,
                        editingProject: $editingProject,
                        currentError: $currentError
                    )
                }
            } header: {
                projectsHeader
            }
        }
        .listStyle(.sidebar)
        .focusable()
        .alert(item: $currentError) { error in
            Alert(
                title: Text(error.type.title),
                message: Text(error.errorDescription),
                dismissButton: .default(Text("OK"))
            )
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
                addProject(name: "My Project")
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: Project Actions
extension ProjectsView {
    
    private func addProject(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            currentError = ProjectError(type: .validation("Project name cannot be empty."))
            return
        }
        
        let newProject = Project(name: trimmedName)
        modelContext.insert(newProject)
        
        do {
            try modelContext.save()
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
