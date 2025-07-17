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
    @State private var projectToDelete: Project?
    @State private var showingDeleteAlert = false
    
    @State private var currentError: ProjectError?
    
    var body: some View {
        List {
            Section {
                ForEach(projects, id: \.self) { project in
                    projectView(for: project)
                }
            } header: {
                projectsHeader
            }
        }
        .listStyle(.sidebar)
        .focusable()
        .alert("Delete Project", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                projectToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let project = projectToDelete {
                    deleteProject(project)
                }
                projectToDelete = nil
            }
        } message: {
            if let project = projectToDelete {
                Text("Are you sure you want to delete \"\(project.name)\"? This action cannot be undone.")
            }
        }
        .alert(item: $currentError) { error in
            Alert(
                title: Text(error.type.title),
                message: Text(error.errorDescription),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    @ViewBuilder
    func projectView(for project: Project) -> some View {
        let isSelected = selectedProject == project
        
        VStack(alignment: .leading, spacing: 4) {
            if editingProject == project {
                TextField("Project Name", text: Binding(
                    get: { project.name },
                    set: { project.name = $0 }
                ))
                .font(.headline)
                .textFieldStyle(.plain)
                .onSubmit {
                    finishEditing()
                }
            } else {
                Text(project.name)
                    .font(.headline)
            }
            
            Text(project.createdAt, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .onTapGesture {
            editingProject = nil
            selectedProject = project
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            selectedProject = project
            editingProject = project
        }
        .contextMenu {
            Button("Edit Name") {
                editingProject = project
            }
            
            Divider()
            
            Button("Delete", role: .destructive) {
                projectToDelete = project
                showingDeleteAlert = true
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
                addProjectInEditMode()
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
    private func addProjectInEditMode() {
        let projectName = "My Project"
        
        if projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            currentError = ProjectError(type: .validation("Project name cannot be empty."))
            return
        }
        
        let newProject = Project(name: projectName)
        modelContext.insert(newProject)
        
        do {
            try modelContext.save()
            editingProject = newProject
            selectedProject = newProject
        } catch {
            currentError = ProjectError(type: .createProject, underlyingError: error)
        }
    }
    
    private func finishEditing() {
        guard let project = editingProject else { return }
        
        // Validate project name
        let trimmedName = project.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            currentError = ProjectError(type: .validation("Project name cannot be empty."))
            return
        }
        
        project.name = trimmedName
        project.updatedAt = Date()
        
        do {
            try modelContext.save()
            editingProject = nil
        } catch {
            currentError = ProjectError(type: .updateProject, underlyingError: error)
        }
    }
    
    private func deleteProject(_ project: Project) {
        if selectedProject == project {
            selectedProject = nil
        }

        if editingProject == project {
            editingProject = nil
        }
        
        modelContext.delete(project)
        
        do {
            try modelContext.save()
        } catch {
            currentError = ProjectError(type: .deleteProject, underlyingError: error)
        }
    }
    
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
