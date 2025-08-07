//
//  GeminiBatchApp.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import SwiftUI
import SwiftData

@main
struct GeminiBatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Color.orange.opacity(0.8))
        }
        .modelContainer(for: Project.self)
        .environment(ToastPresenter())
    }
}
