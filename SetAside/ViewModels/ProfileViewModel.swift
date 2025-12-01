//
//  ProfileViewModel.swift
//  SetAside
//

import Foundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var updateSuccess: Bool = false
    
    private let userService = UserService.shared
    
    init() {
        Task {
            await fetchProfile()
        }
    }
    
    func fetchProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            user = try await userService.getMyProfile()
        } catch let error as APIError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func updateProfile(fullName: String?, phone: String?) async {
        isLoading = true
        errorMessage = nil
        updateSuccess = false
        
        do {
            user = try await userService.updateMyProfile(fullName: fullName, phone: phone)
            updateSuccess = true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    func clearSuccess() {
        updateSuccess = false
    }
}
