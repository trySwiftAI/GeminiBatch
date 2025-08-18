//
//  BatchJobMessageListView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/18/25.
//

import SwiftUI

struct BatchJobMessagesView: View {
    
    let batchJob: BatchJob
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(batchJob.jobStatusMessages, id: \.id) { message in
                        BatchJobMessageRow(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .onAppear {
                if let lastMessage = batchJob.jobStatusMessages.last {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: batchJob.jobStatusMessages.count) { _, newCount in
                if let lastMessage = batchJob.jobStatusMessages.last {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

