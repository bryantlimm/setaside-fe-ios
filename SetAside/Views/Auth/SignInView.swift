//
//  SignInView.swift
//  SetAside
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showSignUp: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationStack {
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
                            .frame(width: 180, height: 180)
                            .padding(.top, 40)
                        
                        // Header Text
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome Back!")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("We're glad to see you again.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        // Form Container
                        VStack(spacing: 0) {
                            signInForm
                                .padding(24)
                        }
                        .background(Color.white)
                        .cornerRadius(24, corners: [.topLeft, .topRight])
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
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
    }
    
    private var signInForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            VStack(alignment: .leading, spacing: 4) {
                Text("Sign In")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Enter your credentials to continue")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
            
            // Input Fields
            VStack(spacing: 16) {
                CustomTextField(
                    label: "Email",
                    iconName: "EmailIcon",
                    text: $email,
                    keyboardType: .emailAddress
                )
                
                CustomTextField(
                    label: "Password",
                    iconName: "PasswordIcon",
                    text: $password,
                    isSecure: true
                )
            }
            
            // Sign In Button
            PrimaryButton(
                title: "Sign In",
                isLoading: authViewModel.isLoading
            ) {
                hideKeyboard()
                Task {
                    await authViewModel.login(email: email, password: password)
                }
            }
            .disabled(email.isEmpty || password.isEmpty)
            
            // Sign Up Link
            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .foregroundColor(.gray)
                
                Button("Sign up here") {
                    showSignUp = true
                }
                .foregroundColor(.primaryGreen)
                .fontWeight(.semibold)
            }
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthViewModel())
}
