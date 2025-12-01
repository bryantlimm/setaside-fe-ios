//
//  SignUpView.swift
//  SetAside
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var fullName: String = ""
    @State private var phone: String = ""
    @State private var showPasswordMismatch: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        ZStack {
            // Background
            Image("AuthBG")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Logo
                    Image("SetAsideLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .padding(.top, 20)
                    
                    // Header Text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Join SetAside!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Shopping made easy with SetAside")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    
                    // Form Container
                    VStack(spacing: 0) {
                        signUpForm
                            .padding(24)
                    }
                    .background(Color.white)
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Password Mismatch", isPresented: $showPasswordMismatch) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Passwords do not match. Please try again.")
        }
        .onReceive(authViewModel.$showError) { newValue in
            if newValue {
                errorMessage = authViewModel.errorMessage ?? "An error occurred"
                showErrorAlert = true
                DispatchQueue.main.async {
                    authViewModel.clearError()
                }
            }
        }
    }
    
    private var signUpForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            VStack(alignment: .leading, spacing: 4) {
                Text("Create Account")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Fill in your details to get started")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
            
            // Input Fields
            VStack(spacing: 14) {
                CustomTextField(
                    label: "Full Name",
                    iconName: "account",
                    text: $fullName
                )
                
                CustomTextField(
                    label: "Email",
                    iconName: "EmailIcon",
                    text: $email,
                    keyboardType: .emailAddress
                )
                
                CustomTextField(
                    label: "Phone (Optional)",
                    iconName: "location",
                    text: $phone,
                    keyboardType: .phonePad
                )
                
                CustomTextField(
                    label: "Password",
                    iconName: "PasswordIcon",
                    text: $password,
                    isSecure: true
                )
                
                CustomTextField(
                    label: "Confirm Password",
                    iconName: "PasswordIcon",
                    text: $confirmPassword,
                    isSecure: true
                )
            }
            
            // Password requirements hint
            Text("Password must be at least 8 characters with uppercase, lowercase, and number")
                .font(.caption)
                .foregroundColor(.gray)
            
            // Sign Up Button
            PrimaryButton(
                title: "Create Account",
                isLoading: authViewModel.isLoading
            ) {
                hideKeyboard()
                if password != confirmPassword {
                    showPasswordMismatch = true
                    return
                }
                
                Task {
                    await authViewModel.register(
                        email: email,
                        password: password,
                        fullName: fullName,
                        phone: phone.isEmpty ? nil : phone
                    )
                }
            }
            .disabled(!isFormValid)
            
            // Sign In Link
            HStack(spacing: 4) {
                Text("Already have an account?")
                    .foregroundColor(.gray)
                
                Button("Sign in here") {
                    dismiss()
                }
                .foregroundColor(.primaryGreen)
                .fontWeight(.semibold)
            }
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !fullName.isEmpty && !confirmPassword.isEmpty
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}
