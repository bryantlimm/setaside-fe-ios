//
//  NetworkManager.swift
//  SetAside
//

import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    private let baseURL = AppConstants.baseURL
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }
    
    private var accessToken: String? {
        get { UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.accessToken) }
        set { UserDefaults.standard.set(newValue, forKey: AppConstants.UserDefaultsKeys.accessToken) }
    }
    
    func setAccessToken(_ token: String?) {
        accessToken = token
    }
    
    func clearToken() {
        accessToken = nil
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.accessToken)
        UserDefaults.standard.set(false, forKey: AppConstants.UserDefaultsKeys.isLoggedIn)
    }
    
    private func createRequest(
        endpoint: String,
        method: String,
        body: Data? = nil,
        requiresAuth: Bool = true
    ) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth, let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        var bodyData: Data? = nil
        
        if let body = body {
            let encoder = JSONEncoder()
            bodyData = try encoder.encode(body)
        }
        
        let request = try createRequest(
            endpoint: endpoint,
            method: method,
            body: bodyData,
            requiresAuth: requiresAuth
        )
        
        #if DEBUG
        print("🌐 API Request: \(method) \(baseURL)\(endpoint)")
        if let bodyData = bodyData, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📤 Request Body: \(bodyString)")
        }
        #endif
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        #if DEBUG
        print("📥 Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response Body: \(responseString.prefix(500))")
        }
        #endif
        
        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                #if DEBUG
                print("❌ Decoding Error: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Full response: \(responseString)")
                }
                #endif
                throw APIError.decodingError(error)
            }
        case 401:
            clearToken()
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 500...599:
            #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Server Error (\(httpResponse.statusCode)) Response: \(responseString)")
            }
            #endif
            let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            if let message = errorResponse?.errorMessage, message != "An unknown error occurred" {
                throw APIError.httpError(statusCode: httpResponse.statusCode, message: "Server error: \(message)")
            }
            throw APIError.serverError
        default:
            #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ HTTP Error (\(httpResponse.statusCode)) Response: \(responseString)")
            }
            #endif
            let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            let message = errorResponse?.errorMessage ?? "Request failed"
            #if DEBUG
            print("❌ Parsed error message: \(message)")
            #endif
            throw APIError.httpError(
                statusCode: httpResponse.statusCode,
                message: message
            )
        }
    }
    
    func requestWithoutResponse(
        endpoint: String,
        method: String = "DELETE",
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws {
        var bodyData: Data? = nil
        
        if let body = body {
            let encoder = JSONEncoder()
            bodyData = try encoder.encode(body)
        }
        
        let request = try createRequest(
            endpoint: endpoint,
            method: method,
            body: bodyData,
            requiresAuth: requiresAuth
        )
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299, 204:
            return
        case 401:
            clearToken()
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError
        default:
            let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw APIError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorResponse?.errorMessage ?? "Request failed"
            )
        }
    }
    
    /// Request method that tries multiple decoding strategies for flexible API responses
    func requestWithFlexibleResponse<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        var bodyData: Data? = nil
        
        if let body = body {
            let encoder = JSONEncoder()
            bodyData = try encoder.encode(body)
        }
        
        let request = try createRequest(
            endpoint: endpoint,
            method: method,
            body: bodyData,
            requiresAuth: requiresAuth
        )
        
        #if DEBUG
        print("🌐 API Request: \(method) \(baseURL)\(endpoint)")
        if let bodyData = bodyData, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📤 Request Body: \(bodyString)")
        }
        #endif
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        #if DEBUG
        print("📥 Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response Body: \(responseString)")
        }
        #endif
        
        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            
            // Try direct decoding first
            do {
                return try decoder.decode(T.self, from: data)
            } catch let directError {
                #if DEBUG
                print("⚠️ Direct decoding failed: \(directError)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Full response for debugging: \(responseString)")
                }
                #endif
                
                // Try to decode as wrapped response { "order": {...} } or { "data": {...} }
                if T.self == Order.self {
                    do {
                        let wrapped = try decoder.decode(SingleOrderResponse.self, from: data)
                        if let order = wrapped.unwrappedOrder as? T {
                            #if DEBUG
                            print("✅ Decoded as wrapped order response")
                            #endif
                            return order
                        }
                    } catch let wrappedError {
                        #if DEBUG
                        print("⚠️ Wrapped decoding also failed: \(wrappedError)")
                        #endif
                    }
                    
                    // Last resort: try to extract just the essential fields manually
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        #if DEBUG
                        print("📋 JSON keys found: \(json.keys)")
                        #endif
                        
                        // Check if response has order nested under some key
                        for key in ["order", "data", "result"] {
                            if let orderDict = json[key] as? [String: Any],
                               let orderData = try? JSONSerialization.data(withJSONObject: orderDict),
                               let order = try? decoder.decode(Order.self, from: orderData) as? T {
                                #if DEBUG
                                print("✅ Found order under key '\(key)'")
                                #endif
                                return order
                            }
                        }
                    }
                }
                
                throw APIError.decodingError(directError)
            }
        case 401:
            clearToken()
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 500...599:
            #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Server Error (\(httpResponse.statusCode)) in flexible request: \(responseString)")
            }
            #endif
            let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            if let message = errorResponse?.errorMessage, message != "An unknown error occurred" {
                throw APIError.httpError(statusCode: httpResponse.statusCode, message: "Server error: \(message)")
            }
            throw APIError.serverError
        default:
            let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw APIError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorResponse?.errorMessage ?? "Request failed"
            )
        }
    }
}
