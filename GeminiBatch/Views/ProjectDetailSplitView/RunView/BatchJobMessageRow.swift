//
//  BatchJobMessageRow.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/18/25.
//

import SwiftUI

struct BatchJobMessageRow: View {
    let message: BatchJobMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: message.type.systemImageName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(messageTypeColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.message)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 0)
        }
        .padding()
        .cornerRadius(8)
    }
    
    private var messageTypeColor: Color {
        switch message.type {
        case .success:
            return .green
        case .error:
            return .red
        case .pending:
            return .orange
        }
    }
}
