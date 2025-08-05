//
//  ProjectView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import SwiftUI

struct ProjectDetailView: View {
    
    let project: Project
    
    var body: some View {
        VStack(spacing: 20) {
            projectHeader(project)
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !project.batchFiles.isEmpty {
                        fileListView(project.batchFiles)
                    }
                    FileUploadView(project: project)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .padding(.leading, 10)
            }
            .padding(.horizontal)
            Spacer()
        }
    }
}

extension ProjectDetailView {
    
    @ViewBuilder
    private func projectHeader(_ project: Project) -> some View {
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
    }
    
    @ViewBuilder
    private func fileListView(_ files: [BatchFile]) -> some View {
        VStack(alignment: .leading) {
            
            Text("JSONL Files (\(files.count))")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(files) { file in
                        FileRowView(file: file)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Divider()
        }
    }
}
