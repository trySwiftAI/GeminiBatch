//
//  GeminiCliet.swift
//  GeminiBatch
//
//  Created by Natasha Murashev on 8/11/25.
//

import AIProxy
import Foundation

struct GeminiClient {
    
    private let apiKey: String
    private let model: String
    private let displayName: String
    
    init(apiKey: String, model: String, displayName: String) {
        self.apiKey = "AIzaSyCD4qWre1Ij9Pb-GdaVqVy5FGorqYqKXQ8"
        self.model = model
        self.displayName = displayName
    }
    
    /// Creates a batch job using the batchGenerateContent endpoint
    /// - Parameter fileId: The file ID of the uploaded batch file
    /// - Returns: A GeminiBatchResponse containing the batch job details
    func createBatchJob(fileId: String) async throws -> GeminiBatchResponseBody {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):batchGenerateContent")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = BatchGenerateContentRequest(
            batch: BatchConfig(
                displayName: displayName,
                inputConfig: InputConfig(
                    requests: RequestsConfig(
                        fileName: fileId
                    )
                )
            )
        )
        
        let jsonData = try JSONEncoder().encode(requestBody)
        request.httpBody = jsonData
        
        // Print the actual JSON being sent for debugging
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Sending JSON:")
            print(jsonString)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw JSON Response:")
            print(responseString)
        }

        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiBatchError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw GeminiBatchError.httpError(httpResponse.statusCode)
        }
        
        let batchResponse = try JSONDecoder().decode(GeminiBatchResponseBody.self, from: data)
        print(batchResponse)
        return batchResponse
    }
}

// MARK: - Request Models

private struct BatchGenerateContentRequest: Codable {
    let batch: BatchConfig
}

private struct BatchConfig: Codable {
    let displayName: String
    let inputConfig: InputConfig
    
    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case inputConfig = "input_config"
    }
}

private struct InputConfig: Codable {
    let requests: RequestsConfig
}

private struct RequestsConfig: Codable {
    let fileName: String
    
    enum CodingKeys: String, CodingKey {
        case fileName = "file_name"
    }
}

// MARK: - Errors

enum GeminiBatchError: Error {
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
}
