//
//  Project.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import Foundation
import SwiftData

@Model
final class Project {
    var name: String
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \BatchFile.project)
    var batchFiles: [BatchFile] = []
    
    init(name: String) {
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
