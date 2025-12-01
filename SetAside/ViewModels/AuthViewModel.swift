//
//  AuthViewModel.swift
//  SetAside
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    private let authService = AuthService.shared
    
    init() {
        isLoggedIn = authService.isLoggedIn
        if isLoggedIn {
            Task { @MainActor in
                await fetchCurrentUser()
            }
        }
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            let response = try await authService.login(email: email, password: password)
            self.currentUser = response.user
            self.isLoading = false
            self.isLoggedIn = true
            
            // Fetch full user profile if not included in response
            if self.currentUser == nil {
                await fetchCurrentUser()
            }
        } catch let error as APIError {
            self.isLoading = false
            self.errorMessage = error.errorDescription
            self.showError = true
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }
    
    func register(email: String, password: String, fullName: String, phone: String?) async {
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            let response = try await authService.register(
                email: email,
                password: password,
                fullName: fullName,
                phone: phone
            )
            self.currentUser = response.user
            self.isLoading = false
            self.isLoggedIn = true
            
            // Fetch full user profile if not included in response
            if self.currentUser == nil {
                await fetchCurrentUser()
            }
        } catch let error as APIError {
            self.isLoading = false
            self.errorMessage = error.errorDescription
            self.showError = true
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }
    
    func fetchCurrentUser() async {
        do {
            currentUser = try await authService.getCurrentUser()
        } catch let error as APIError {
            if case .unauthorized = error {
                logout()
            }
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func logout() {
        authService.logout()
        isLoggedIn = false
        currentUser = nil
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
}
