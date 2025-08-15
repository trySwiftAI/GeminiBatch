//
//  AppDelegate.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/15/25.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep the app running in the background even when all windows are closed
        // This ensures background tasks continue running
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When user clicks on the dock icon, show the main window if it's hidden
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(nil)
            }
        }
        return true
    }
}