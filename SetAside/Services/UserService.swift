//
//  UserService.swift
//  SetAside
//

import Foundation

class UserService {
    static let shared = UserService()
    private let networkManager = NetworkManager.shared
    
    private init() {}
    
    /// Get current user's profile
    func getMyProfile() async throws -> User {
        return try await networkManager.request(
            endpoint: "/users/me",
            method: "GET"
        )
    }
    
    /// Update current user's profile
    func updateMyProfile(fullName: String?, phone: String?) async throws -> User {
        let request = UpdateProfileRequest(fullName: fullName, phone: phone)
        
        return try await networkManager.request(
            endpoint: "/users/me",
            method: "PATCH",
            body: request
        )
    }
    
    /// List all users (Admin only)
    func listUsers(page: Int = 1, limit: Int = 10, role: String? = nil, search: String? = nil) async throws -> [User] {
        var endpoint = "/users?page=\(page)&limit=\(limit)"
        if let role = role {
            endpoint += "&role=\(role)"
        }
        if let search = search {
            endpoint += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? search)"
        }
        
        struct UsersResponse: Codable {
            let users: [User]?
            let items: [User]?
            
            var allUsers: [User] {
                return users ?? items ?? []
            }
        }
        
        let response: UsersResponse = try await networkManager.request(
            endpoint: endpoint,
            method: "GET"
        )
        
        return response.allUsers
    }
}
