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
        if let existingTask = runningTasks[batchJobID] {
            existingTask.cancel()
        }
        
        runningTasks[batchJobID] = task
        
        // Clean up completed tasks automatically on main actor
        Task { @MainActor in
            _ = await task.result
            runningTasks.removeValue(forKey: batchJobID)
        }
    }
    
    func cancelTask(forBatchJobID batchJobID: BatchJobID) {
        runningTasks[batchJobID]?.cancel()
        runningTasks.removeValue(forKey: batchJobID)
    }
    
    func cancelAllTasks() {
        for task in runningTasks.values {
            task.cancel()
        }
        runningTasks.removeAll()
    }
    
    func isTaskRunning(forBatchJobID batchJobID: BatchJobID) -> Bool {
        if let task = runningTasks[batchJobID] {
            if task.isCancelled {
                runningTasks.removeValue(forKey: batchJobID)
                return false
            }
            return true
        }
        return false
    }
}
