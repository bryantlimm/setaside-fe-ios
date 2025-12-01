//
//  User.swift
//  SetAside
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String
    let phone: String?
    let role: String
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case phone
        case role
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct AuthResponse: Codable {
    let accessToken: String
    let tokenType: String?
    let user: User?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case user
    }
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let fullName: String
    let phone: String?
    
    enum CodingKeys: String, CodingKey {
        case email
        case password
        case fullName = "full_name"
        case phone
    }
}

struct UpdateProfileRequest: Codable {
    let fullName: String?
    let phone: String?
    
    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case phone
    }
}
