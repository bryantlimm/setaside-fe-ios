//
//  APIError.swift
//  SetAside
//

import Foundation

struct APIErrorResponse: Codable {
    let detail: String?
    let message: MessageType?
    let error: String?
    
    // Handle message being either a string or array of strings
    enum MessageType: Codable {
        case string(String)
        case array([String])
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                self = .string(string)
            } else if let array = try? container.decode([String].self) {
                self = .array(array)
            } else {
                self = .string("Unknown error")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let str):
                try container.encode(str)
            case .array(let arr):
                try container.encode(arr)
            }
        }
        
        var displayString: String {
            switch self {
            case .string(let str):
                return str
            case .array(let arr):
                return arr.joined(separator: "\n")
            }
        }
    }
    
    var errorMessage: String {
        if let detail = detail {
            return detail
        }
        if let message = message {
            return message.displayString
        }
        if let error = error {
            return error
        }
        return "An unknown error occurred"
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
