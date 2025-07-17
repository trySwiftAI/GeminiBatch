//
//  ProjectView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import SwiftUI
import SwiftData

struct ProjectView: View {
    @Environment(\.modelContext) private var modelContext
    
    let project: Project
    
    @Binding var selectedProject: Project?
    @Binding var currentError: ProjectError?
    
    @State var showingDeleteAlert = false
    @State var isEditing: Bool = false
    
    @FocusState private var isTextFieldFocused: Bool
    
    private var isSelected: Bool {
        selectedProject == project
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isEditing {
                TextField("Project Name", text: Binding(
                    get: { project.name },
                    set: { project.name = $0 }
                ))
                .font(.headline)
                .textFieldStyle(.plain)
                .focused($isTextFieldFocused)
                .onSubmit {
                    finishEditing()
                }
                .onAppear {
                    isTextFieldFocused = true
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
        .clipShape(.rect(cornerRadius: 6.0))
        .onTapGesture {
            selectedProject = project
            isEditing = false
            isTextFieldFocused = false
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            selectedProject = project
            startEditing()
        }
        .contextMenu {
            Button("Edit Name") {
                startEditing()
            }
            
            Divider()
            
            Button("Delete", role: .destructive) {
                showingDeleteAlert = true
            }
        }
        .alert("Delete Project", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                
            }
            Button("Delete", role: .destructive) {
                deleteProject()
            }
        } message: {
            Text("Are you sure you want to delete \"\(project.name)\"? This action cannot be undone.")
        }
    }
}

// MARK: Project Actions
extension ProjectView {
    private func startEditing() {
        isEditing = true
        isTextFieldFocused = true
    }
    
    private func finishEditing() {
        let trimmedName = project.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            currentError = ProjectError(type: .validation("Project name cannot be empty."))
            return
        }
        
        project.name = trimmedName
        project.updatedAt = Date()
        
        do {
            try modelContext.save()
            isEditing = false
            isTextFieldFocused = false
        } catch {
            currentError = ProjectError(type: .updateProject, underlyingError: error)
        }
    }
    
    private func deleteProject() {
        if selectedProject == project {
            selectedProject = nil
        }
        
        modelContext.delete(project)
        
        do {
            try modelContext.save()
        } catch {
            currentError = ProjectError(type: .deleteProject, underlyingError: error)
        }
    }
}
