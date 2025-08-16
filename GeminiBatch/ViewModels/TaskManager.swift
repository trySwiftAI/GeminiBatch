//
//  TaskManager.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/15/25.
//

import SwiftData
import SwiftUI

@Observable
final class TaskManager {
    typealias BatchJobID = PersistentIdentifier

    static let shared = TaskManager()
    
    var runningTasks: [BatchJobID: Task<Void, Error>] = [:]
    
    private init() {}
    
    func addTask(
        for batchJobID: BatchJobID,
        task: Task<Void, Error>
    ) {
        runningTasks[batchJobID] = task
        
        // Clean up completed tasks automatically on main actor
        Task { @MainActor in
            _ = await task.result
            runningTasks.removeValue(forKey: batchJobID)
        }
    }
    
    func cancelTask(for batchJobID: BatchJobID) {
        runningTasks[batchJobID]?.cancel()
        runningTasks.removeValue(forKey: batchJobID)
    }
    
    func cancelAllTasks() {
        for task in runningTasks.values {
            task.cancel()
        }
        runningTasks.removeAll()
    }
    
    func isTaskRunning(for batchJobID: BatchJobID) -> Bool {
        if let task = runningTasks[batchJobID] {
            // Check if task is actually still running
            if task.isCancelled {
                runningTasks.removeValue(forKey: batchJobID)
                return false
            }
            return true
        }
        return false
    }
    
    var hasRunningTasks: Bool {
        // Clean up any cancelled tasks
        runningTasks = runningTasks.filter { !$0.value.isCancelled }
        return !runningTasks.isEmpty
    }
    
    var runningTaskCount: Int {
        // Clean up any cancelled tasks first
        runningTasks = runningTasks.filter { !$0.value.isCancelled }
        return runningTasks.count
    }
    
    var runningTaskIDs: [BatchJobID] {
        // Clean up any cancelled tasks first
        runningTasks = runningTasks.filter { !$0.value.isCancelled }
        return Array(runningTasks.keys)
    }
}
