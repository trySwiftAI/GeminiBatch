//
//  URL+Extensions.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 7/17/25.
//

import Foundation

extension URL {
    
    var isJSONL: Bool {
        return pathExtension.lowercased() == "jsonl"
    }
    
    var fileSize: Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
}
