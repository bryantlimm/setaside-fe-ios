//
//  APIError.swift
//  SetAside
//

import Foundation

struct APIErrorResponse: Codable {
    let detail: String?
    let message: String?
    let error: String?
    
    var errorMessage: String {
        detail ?? message ?? error ?? "An unknown error occurred"
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case decodingError(Error)
    case networkError(Error)
    case unauthorized
    case notFound
    case serverError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(_, let message):
            return message
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized. Please login again."
        case .notFound:
            return "Resource not found"
        case .serverError:
            return "Server error. Please try again later."
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
