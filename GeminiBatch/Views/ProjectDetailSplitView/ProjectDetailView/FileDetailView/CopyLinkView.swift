//
//  CopyLinkView.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/18/25.
//

import SwiftUI

struct CopyLinkView: View {
    @Environment(ToastPresenter.self) private var toastPresenter
    
    let copyContent: String
    let helpText: String
    let successMessage: String
    
    var body: some View {
        HStack {
            Text(copyContent)
                .font(.caption)
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.separatorColor), lineWidth: 0.5)
                )
            
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(copyContent, forType: .string)
                toastPresenter.showSuccessToast(withMessage: successMessage)
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help(helpText)
        }
    }
}
