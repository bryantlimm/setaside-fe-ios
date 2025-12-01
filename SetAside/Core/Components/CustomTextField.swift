//
//  CustomTextField.swift
//  SetAside
//

import SwiftUI

struct CustomTextField: View {
    var label: String
    var iconName: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    @State private var isPasswordVisible: Bool = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.gray)
                
                if isSecure && !isPasswordVisible {
                    SecureField(label, text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isFocused)
                        .textContentType(.oneTimeCode) // Prevents password autofill issues
                } else {
                    TextField(label, text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                        .autocorrectionDisabled(keyboardType == .emailAddress)
                        .focused($isFocused)
                        .textContentType(keyboardType == .emailAddress ? .emailAddress : .none)
                }
                
                if isSecure {
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.primaryGreen : Color.gray.opacity(0.4), lineWidth: isFocused ? 2 : 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

struct PrimaryButton: View {
    var title: String
    var isLoading: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.primaryGreen)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}

struct SecondaryButton: View {
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(.primaryGreen)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primaryGreen, lineWidth: 2)
                )
                .cornerRadius(12)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomTextField(label: "Email", iconName: "EmailIcon", text: .constant(""))
        CustomTextField(label: "Password", iconName: "PasswordIcon", text: .constant(""), isSecure: true)
        PrimaryButton(title: "Sign In") {}
        SecondaryButton(title: "Sign Up") {}
    }
    .padding()
}
