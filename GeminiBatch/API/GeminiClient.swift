//
//  GeminiClient.swift
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
        
//        // Extract just the file ID from the full URL if needed
//        let cleanFileId: String
//        if fileId.hasPrefix("https://") {
//            // Extract the file ID from URL like "https://generativelanguage.googleapis.com/v1beta/files/34iwswvmsy5e"
//            cleanFileId = String(fileId.split(separator: "/").last ?? "")
//        } else if fileId.hasPrefix("files/") {
//            cleanFileId = fileId
//        } else {
//            cleanFileId = "files/\(fileId)"
//        }
        
        let requestBody = BatchGenerateContentRequest(
            batch: BatchConfig(
                displayName: displayName,
                inputConfig: InputConfig(
                    fileName: fileId
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
            // Try to parse the error response to get the actual error message
            if let errorResponse = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
                throw GeminiBatchError.apiError(errorResponse.error.message, errorResponse.error.code)
            } else {
                throw GeminiBatchError.httpError(httpResponse.statusCode)
            }
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
    let fileName: String
    
    enum CodingKeys: String, CodingKey {
        case fileName = "file_name"
    }
}

// MARK: - Error Response Models

private struct GeminiErrorResponse: Codable {
    let error: GeminiError
}

private struct GeminiError: Codable {
    let code: Int
    let message: String
    let status: String
}

// MARK: - Errors

enum GeminiBatchError: Error {
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case apiError(String, Int) // message, code
}

extension GeminiBatchError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .apiError(let message, let code):
            return "API Error (\(code)): \(message)"
        }
    }
}
