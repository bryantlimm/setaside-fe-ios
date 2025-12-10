//
//  AppConstants.swift
//  SetAside
//

import Foundation

enum AppConstants {
    static let baseURL = "https://setaside.matthewswong.tech/api/v1"
    
    enum UserDefaultsKeys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
        static let userId = "userId"
        static let isLoggedIn = "isLoggedIn"
    }
    
    enum OrderStatus: String, CaseIterable {
        case pending = "pending"
        case preparing = "preparing"
        case ready = "ready"
        case pickedUp = "pickedup"
        case completed = "completed"
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .preparing: return "Preparing"
            case .ready: return "Ready for Pickup"
            case .pickedUp: return "Picked Up"
            case .completed: return "Picked Up"
            }
        }
        
        var iconName: String {
            switch self {
            case .pending: return "clock.fill"
            case .preparing: return "flame.fill"
            case .ready: return "checkmark.circle.fill"
            case .pickedUp: return "bag.fill"
            case .completed: return "bag.fill"
            }
        }
    }
}
