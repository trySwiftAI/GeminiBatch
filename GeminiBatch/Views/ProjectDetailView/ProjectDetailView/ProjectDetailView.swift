//
//  ProjectView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import SwiftUI

struct ProjectDetailView: View {
    @Environment(ToastPresenter.self) private var toastPresenter
    
    let project: Project
    
    @State private var geminiAPIKey: String = ""
    @State private var isAPIKeyVisible: Bool = false
    @FocusState private var isAPIKeyFocused
        
    var body: some View {
        VStack(spacing: 20) {
            projectHeader(project)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    apiKeySection
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
        .overlay(alignment: .top) {
            if toastPresenter.isPresented && !toastPresenter.message.isEmpty {
                ToastView()
            }
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
    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("The Gemini API key for this project (required)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack {
                ZStack(alignment: .trailing) {
                    Group {
                        if isAPIKeyVisible {
                            TextField("Enter your Gemini API Key", text: $geminiAPIKey)
                        } else {
                            SecureField("Enter your Gemini API Key", text: $geminiAPIKey)
                        }
                    }
                    .textFieldStyle(.plain)
                    .padding(6)
                    .padding(.trailing, !geminiAPIKey.isEmpty ? 30 : 6)
                    
                    if !geminiAPIKey.isEmpty {
                        Button(action: {
                            geminiAPIKey = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .background(.background)
                        }
                        .buttonStyle(.borderless)
                        .padding(.trailing, 6)
                    }
                }
                .overlay(
                    ConcentricRectangle(corners: .fixed(8), isUniform: true)
                        .stroke(geminiAPIKey.isEmpty ? .red.opacity(0.5) : .mint.opacity(0.3), lineWidth: 2)
                )
                
                Button(action: {
                    isAPIKeyVisible.toggle()
                }) {
                    Image(systemName: isAPIKeyVisible ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal)
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
