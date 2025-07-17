//
//  ProjectView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import SwiftUI

struct ProjectView: View {
    let project: Project?
    
    var body: some View {
        Group {
            if let project = project {
                VStack(spacing: 20) {
                    HStack {
                        Text(project.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("Created: \(project.createdAt, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    Divider()
                    
                    // Main project content area
                    VStack {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("Project content will go here")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            } else {
                // Empty state when no project is selected
                VStack(spacing: 20) {
                    Image(systemName: "folder")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Select a project")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Choose a project from the sidebar to get started")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    ProjectView(project: Project(name: "Sample Project"))
        .frame(width: 600, height: 400)
}