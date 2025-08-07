//
//  ProjectView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import SwiftUI
import SwiftData

struct ProjectOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ToastPresenter.self) private var toastPresenter
    
    let project: Project
    
    @Binding var selectedProject: Project?
    
    @State var showingDeleteAlert = false
    @State var isEditing: Bool = false
    
    @FocusState private var isTextFieldFocused: Bool
    @FocusState private var isProjectFocused: Bool
    
    private var isSelected: Bool {
        selectedProject == project
    }
    
    var body: some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .glassEffect(.regular.interactive().tint(.accentColor), in: .rect(cornerRadius: 8))
            }
            projectOverviewView
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedProject = project
            isEditing = false
            isTextFieldFocused = false
            isProjectFocused = true
        }
        .contextMenu {
            Button("Edit Name", systemImage: "pencil") {
                startEditing()
            }
            
            Divider()
            
            Button("Delete", systemImage: "trash", role: .destructive) {
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
        .focusEffectDisabled()
        .onDeleteCommand {
            if selectedProject == project && !isEditing {
                showingDeleteAlert = true
            }
        }
    }
}

extension ProjectOverviewView {
    @ViewBuilder
    private var projectOverviewView: some View {
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
            
            Text(project.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: Project Actions
extension ProjectOverviewView {
    
    private func startEditing() {
        isEditing = true
        isTextFieldFocused = true
    }
    
    private func finishEditing() {
        let trimmedName = project.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            let error = ProjectError(type: .validation("Project name cannot be empty."))
            toastPresenter.showToast(.error, withMessage: error.errorDescription)
            return
        }
        
        project.name = trimmedName
        project.updatedAt = Date()
        
        do {
            try modelContext.save()
            isEditing = false
            isTextFieldFocused = false
        } catch {
            let error = ProjectError(type: .updateProject, underlyingError: error)
            toastPresenter.showToast(.error, withMessage: error.errorDescription)
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
            let error = ProjectError(type: .deleteProject, underlyingError: error)
            toastPresenter.showToast(.error, withMessage: error.errorDescription)
        }
    }
}
