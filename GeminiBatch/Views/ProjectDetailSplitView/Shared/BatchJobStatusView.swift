//
//  BatchJobStatusView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/17/25.
//

import SwiftUI

struct BatchJobStatusView: View {
    
    let status: BatchJobStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(statusColor)
            
            Text(status.statusTitle)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .glassEffect(.regular.interactive())
        .background(statusColor.opacity(0.1))
        .cornerRadius(12)
    }
}

extension BatchJobStatusView {
    private var iconName: String {
        switch status {
        case .notStarted:
            return "circle.dotted"
        case .fileUploaded:
            return "arrow.up.circle.fill"
        case .pending:
            return "clock.fill"
        case .running:
            return "gearshape.2.fill"
        case .succeeded:
            return "checkmark.circle.fill"
        case .jobFileDownloaded:
            return "arrow.down.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .cancelled:
            return "stop.circle.fill"
        case .expired:
            return "timer.circle.fill"
        case .unspecified:
            return "questionmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .notStarted:
            return .blue
        case .fileUploaded, .pending, .running:
            return .orange
        case .succeeded:
            return .green
        case .jobFileDownloaded:
            return .indigo
        case .failed, .cancelled, .expired, .unspecified:
            return .red
        }
    }
}

// MARK: - Previews
#Preview("Not Started") {
    BatchJobStatusView(status: .notStarted)
        .padding()
}

#Preview("File Uploaded") {
    BatchJobStatusView(status: .fileUploaded)
        .padding()
}

#Preview("Pending") {
    BatchJobStatusView(status: .pending)
        .padding()
}

#Preview("Running") {
    BatchJobStatusView(status: .running)
        .padding()
}

#Preview("Unspecified") {
    BatchJobStatusView(status: .unspecified)
        .padding()
}

#Preview("Succeeded") {
    BatchJobStatusView(status: .succeeded)
        .padding()
}

#Preview("Job File Downloaded") {
    BatchJobStatusView(status: .jobFileDownloaded)
        .padding()
}

#Preview("Failed") {
    BatchJobStatusView(status: .failed)
        .padding()
}

#Preview("Cancelled") {
    BatchJobStatusView(status: .cancelled)
        .padding()
}

#Preview("Expired") {
    BatchJobStatusView(status: .expired)
        .padding()
}

#Preview("All Status Colors") {
    VStack(alignment: .leading, spacing: 8) {
        Text("Blue Statuses")
            .font(.headline)
        HStack {
            BatchJobStatusView(status: .notStarted)
            BatchJobStatusView(status: .fileUploaded)
        }
        
        Text("Orange Statuses")
            .font(.headline)
        HStack {
            BatchJobStatusView(status: .pending)
            BatchJobStatusView(status: .running)
            BatchJobStatusView(status: .unspecified)
        }
        
        Text("Green Statuses")
            .font(.headline)
        HStack {
            BatchJobStatusView(status: .succeeded)
            BatchJobStatusView(status: .jobFileDownloaded)
        }
        
        Text("Red Statuses")
            .font(.headline)
        HStack {
            BatchJobStatusView(status: .failed)
            BatchJobStatusView(status: .cancelled)
            BatchJobStatusView(status: .expired)
        }
    }
    .padding()
    .frame(width: 500)
}
