//
//  SignInContent.swift
//  SetAside
//
//  Created by Bryant Aryadi on 11/11/25.
//

import SwiftUI

struct SignInContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title + subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Sign in to your account")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
            
            // Inputs + button + link
            VStack(spacing: 16) {
                Columns(label: "Email", iconName: "EmailIcon")
                Columns(label: "Password", iconName: "PasswordIcon")
                
                CustomButton(title: "Sign In")
                
                // "Don't have an account yet? Create one here"
                HStack(spacing: 4) {
                    Text("Don't have an account yet? Create one")
                        .foregroundColor(.gray)
                    
                    NavigationLink(destination: SignUpPage()) {
                        Text("here")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        SignInContent()
    }
}
