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
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
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
}
