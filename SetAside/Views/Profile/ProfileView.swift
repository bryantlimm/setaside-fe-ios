//
//  ProfileView.swift
//  SetAside
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundGreen
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Header
                        profileHeader
                        
                        // Account Section
                        accountSection
                        
                        // App Info Section
                        appInfoSection
                        
                        // Logout Button
                        logoutButton
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .alert("Logout", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) {
                    authViewModel.logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .refreshable {
                await profileViewModel.fetchProfile()
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.lightGreen)
                    .frame(width: 100, height: 100)
                
                Text(initials)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primaryGreen)
            }
            
            // Name and Email
            VStack(spacing: 4) {
                Text(profileViewModel.user?.fullName ?? authViewModel.currentUser?.fullName ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.darkGreen)
                
                Text(profileViewModel.user?.email ?? authViewModel.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Role Badge
                if let role = profileViewModel.user?.role ?? authViewModel.currentUser?.role {
                    Text(role.capitalized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.primaryGreen)
                        .cornerRadius(12)
                        .padding(.top, 4)
                }
            }
            
            // Edit Profile Button
            Button(action: { showEditProfile = true }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Profile")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primaryGreen)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primaryGreen, lineWidth: 1)
                )
                .cornerRadius(20)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private var initials: String {
        let name = profileViewModel.user?.fullName ?? authViewModel.currentUser?.fullName ?? ""
        let components = name.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }.map { String($0) }.joined()
        return initials.uppercased()
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account Information")
                .font(.headline)
                .foregroundColor(.darkGreen)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                profileInfoRow(
                    icon: "person.fill",
                    title: "Full Name",
                    value: profileViewModel.user?.fullName ?? authViewModel.currentUser?.fullName ?? "-"
                )
                
                Divider().padding(.leading, 48)
                
                profileInfoRow(
                    icon: "envelope.fill",
                    title: "Email",
                    value: profileViewModel.user?.email ?? authViewModel.currentUser?.email ?? "-"
                )
                
                Divider().padding(.leading, 48)
                
                profileInfoRow(
                    icon: "phone.fill",
                    title: "Phone",
                    value: profileViewModel.user?.phone ?? authViewModel.currentUser?.phone ?? "Not set"
                )
            }
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    private func profileInfoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.primaryGreen)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.subheadline)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)
                .foregroundColor(.darkGreen)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                menuRow(icon: "info.circle.fill", title: "About SetAside")
                Divider().padding(.leading, 48)
                menuRow(icon: "questionmark.circle.fill", title: "Help & Support")
                Divider().padding(.leading, 48)
                menuRow(icon: "doc.text.fill", title: "Terms of Service")
                Divider().padding(.leading, 48)
                menuRow(icon: "lock.shield.fill", title: "Privacy Policy")
            }
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    private func menuRow(icon: String, title: String) -> some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(.primaryGreen)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }
    
    // MARK: - Logout Button
    private var logoutButton: some View {
        Button(action: { showLogoutConfirmation = true }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Logout")
            }
            .font(.headline)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
