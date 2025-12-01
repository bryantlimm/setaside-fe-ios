//
//  AuthService.swift
//  SetAside
//

import Foundation

class AuthService {
    static let shared = AuthService()
    private let networkManager = NetworkManager.shared
    
    private init() {}
    
    /// Register a new user
    func register(email: String, password: String, fullName: String, phone: String?) async throws -> AuthResponse {
        let request = RegisterRequest(
            email: email,
            password: password,
            fullName: fullName,
            phone: phone
        )
        
        #if DEBUG
        print("📝 Registering user: \(email), fullName: \(fullName), phone: \(phone ?? "nil")")
        #endif
        
        let response: AuthResponse = try await networkManager.request(
            endpoint: "/auth/register",
            method: "POST",
            body: request,
            requiresAuth: false
        )
        
        // Save token
        networkManager.setAccessToken(response.accessToken)
        UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.isLoggedIn)
        
        return response
    }
    
    /// Login with email and password
    func login(email: String, password: String) async throws -> AuthResponse {
        let request = LoginRequest(email: email, password: password)
        
        let response: AuthResponse = try await networkManager.request(
            endpoint: "/auth/login",
            method: "POST",
            body: request,
            requiresAuth: false
        )
        
        // Save token
        networkManager.setAccessToken(response.accessToken)
        UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.isLoggedIn)
        
        return response
    }
    
    /// Get current authenticated user
    func getCurrentUser() async throws -> User {
        return try await networkManager.request(
            endpoint: "/auth/me",
            method: "GET"
        )
    }
    
    /// Logout user
    func logout() {
        networkManager.clearToken()
        UserDefaults.standard.set(false, forKey: AppConstants.UserDefaultsKeys.isLoggedIn)
    }
    
    /// Check if user is logged in
    var isLoggedIn: Bool {
        return UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.isLoggedIn)
    }
}
