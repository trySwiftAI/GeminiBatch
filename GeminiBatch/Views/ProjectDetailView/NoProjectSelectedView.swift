//
//  NoProjectSelectedView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/31/25.
//

import SwiftUI

struct NoProjectSelectedView: View {
    
    var body: some View {
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

#Preview {
    NoProjectSelectedView()
}
