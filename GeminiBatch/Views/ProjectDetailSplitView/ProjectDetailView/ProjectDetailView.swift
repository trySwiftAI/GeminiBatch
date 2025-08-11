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
    @Binding var selectedBatchFile: BatchFile?
    @Binding var selectedGeminiModel: GeminiModel
    
    @State private var keychainManager: ProjectKeychainManager
    @State private var isAPIKeyVisible: Bool = false
    @FocusState private var isAPIKeyFocused
    
    init(project: Project, selectedBatchFile: Binding<BatchFile?>, selectedGeminiModel: Binding<GeminiModel>) {
        self.project = project
        self._selectedBatchFile = selectedBatchFile
        self._selectedGeminiModel = selectedGeminiModel
        self._keychainManager = State(initialValue: ProjectKeychainManager(project: project))
    }
        
    var body: some View {
        VStack(spacing: 20) {
            projectHeader(project)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    apiKeySection
                    modelSelectionSection
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
            .scrollIndicators(.hidden)
            Spacer()
        }
        .overlay(alignment: .top) {
            if toastPresenter.isPresented && !toastPresenter.message.isEmpty {
                ToastView()
            }
        }
        .onChange(of: project.id) {
            keychainManager = ProjectKeychainManager(project: project)
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
                            TextField("Enter your Gemini API Key", text: $keychainManager.geminiAPIKey)
                        } else {
                            SecureField("Enter your Gemini API Key", text: $keychainManager.geminiAPIKey)
                        }
                    }
                    .textFieldStyle(.plain)
                    .padding(6)
                    .padding(.trailing, !keychainManager.geminiAPIKey.isEmpty ? 30 : 6)
                    
                    if !keychainManager.geminiAPIKey.isEmpty {
                        Button(action: {
                            keychainManager.geminiAPIKey = ""
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
                        .stroke(keychainManager.geminiAPIKey.isEmpty ? .red.opacity(0.5) : .mint.opacity(0.3), lineWidth: 2)
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
    private var modelSelectionSection: some View {
        HStack {
            Picker("Gemini Model", selection: $selectedGeminiModel) {
                ForEach(GeminiModel.allPredefinedCases, id: \.self) { model in
                    Text(model.displayName)
                        .tag(model)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 300)
            
            Spacer()
        }
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
                        FileRowView(file: file, selectedBatchFile: $selectedBatchFile)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Divider()
        }
    }
}
