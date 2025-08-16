//
//  ProjectView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import SwiftData
import SwiftUI

struct ProjectDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ToastPresenter.self) private var toastPresenter
    @Environment(ProjectViewModel.self) private var projectViewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var isAPIKeyVisible: Bool = false
    @FocusState private var isAPIKeyFocused
    
    var body: some View {
        @Bindable var viewModel = projectViewModel
        
        VStack(spacing: 20) {
            projectHeader(viewModel.project)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    apiKeySection
                    modelSelectionPicker
                    if !viewModel.project.batchFiles.isEmpty {
                        fileListView(viewModel.project.batchFiles)
                    }
                    FileUploadView(project: viewModel.project)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .padding(.leading, 10)
            }
            .padding(.horizontal)
            .scrollIndicators(.hidden)
            Spacer()
        }
        .task {
            do {
                try await projectViewModel.continueRunningJobs(inModelContext: modelContext)
            } catch {
                toastPresenter.showErrorToast(withMessage: error.localizedDescription)
            }
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
            
            Button {
                Task {
                    do {
                        try await projectViewModel.runAllJobs(inModelContext: modelContext)
                    } catch {
                        toastPresenter.showErrorToast(withMessage: error.localizedDescription)
                    }
                }
            } label: {
                Label("Run all", systemImage: "play")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.glassProminent)
            .tint(.orange.opacity(colorScheme == .dark ? 0.5 : 0.8))
            .help("Run all files")
            .scaleEffect(1.2)
            .disabled(projectViewModel.keychainManager.geminiAPIKey.isEmpty)
            .padding(.trailing, 20)
        }
        .padding()
    }
    
    @ViewBuilder
    private var apiKeySection: some View {
        @Bindable var viewModel = projectViewModel
        
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
                            TextField("Enter your Gemini API Key", text: $viewModel.keychainManager.geminiAPIKey)
                        } else {
                            SecureField("Enter your Gemini API Key", text: $viewModel.keychainManager.geminiAPIKey)
                        }
                    }
                    .textFieldStyle(.plain)
                    .padding(6)
                    .padding(.trailing, !viewModel.keychainManager.geminiAPIKey.isEmpty ? 30 : 6)
                    
                    if !viewModel.keychainManager.geminiAPIKey.isEmpty {
                        Button(action: {
                            viewModel.keychainManager.geminiAPIKey = ""
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
                        .stroke(viewModel.keychainManager.geminiAPIKey.isEmpty ? .red.opacity(0.5) : .mint.opacity(0.3), lineWidth: 2)
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
    private var modelSelectionPicker: some View {
        @Bindable var viewModel = projectViewModel
        
        Picker("Gemini Model (required):", selection: $viewModel.selectedGeminiModel) {
            ForEach(GeminiModel.allCases, id: \.self) { model in
                Text(model.displayName)
                    .tag(model)
            }
        }
        .pickerStyle(.menu)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func fileListView(_ files: [BatchFile]) -> some View {
        @Bindable var viewModel = projectViewModel
        
        VStack(alignment: .leading) {
            
            Text("JSONL Files (\(files.count))")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(files) { file in
                        FileRowView(file: file)
                            .id(file.id)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Divider()
        }
    }
}
