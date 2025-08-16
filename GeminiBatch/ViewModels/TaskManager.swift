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
        
        // Clean up completed tasks automatically
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
        runningTasks[batchJobID] != nil
    }
    
    var hasRunningTasks: Bool {
        !runningTasks.isEmpty
    }
    
    var runningTaskCount: Int {
        runningTasks.count
    }
    
    var runningTaskIDs: [BatchJobID] {
        Array(runningTasks.keys)
    }
}
