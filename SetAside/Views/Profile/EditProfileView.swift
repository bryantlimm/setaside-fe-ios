//
//  EditProfileView.swift
//  SetAside
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var fullName: String = ""
    @State private var phone: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundGreen
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color.lightGreen)
                                .frame(width: 100, height: 100)
                            
                            Text(initials)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primaryGreen)
                        }
                        .padding(.top, 20)
                        
                        // Form
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.headline)
                                
                                TextField("Enter your full name", text: $fullName)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Phone Number")
                                    .font(.headline)
                                
                                TextField("Enter your phone number", text: $phone)
                                    .keyboardType(.phonePad)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.headline)
                                
                                Text(authViewModel.currentUser?.email ?? "")
                                    .foregroundColor(.gray)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                
                                Text("Email cannot be changed")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Save Button
                        PrimaryButton(
                            title: "Save Changes",
                            isLoading: profileViewModel.isLoading
                        ) {
                            Task {
                                await profileViewModel.updateProfile(
                                    fullName: fullName.isEmpty ? nil : fullName,
                                    phone: phone.isEmpty ? nil : phone
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryGreen)
                }
            }
            .onAppear {
                fullName = authViewModel.currentUser?.fullName ?? ""
                phone = authViewModel.currentUser?.phone ?? ""
            }
            .alert("Error", isPresented: $profileViewModel.showError) {
                Button("OK") {
                    profileViewModel.clearError()
                }
            } message: {
                Text(profileViewModel.errorMessage ?? "An error occurred")
            }
            .onChange(of: profileViewModel.updateSuccess) { _, success in
                if success {
                    // Refresh auth user
                    Task {
                        await authViewModel.fetchCurrentUser()
                    }
                    dismiss()
                }
            }
        }
    }
    
    private var initials: String {
        let components = fullName.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }.map { String($0) }.joined()
        return initials.isEmpty ? "U" : initials.uppercased()
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AuthViewModel())
}
