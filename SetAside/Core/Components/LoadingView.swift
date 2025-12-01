//
//  LoadingView.swift
//  SetAside
//

import SwiftUI

struct LoadingView: View {
    var message: String = "Loading..."
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .primaryGreen))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundGreen)
    }
}

struct EmptyStateView: View {
    var icon: String
    var title: String
    var message: String
    var buttonTitle: String?
    var action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.lightGreen)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.darkGreen)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let buttonTitle = buttonTitle, let action = action {
                PrimaryButton(title: buttonTitle, action: action)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorBanner: View {
    var message: String
    var onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    VStack {
        LoadingView()
        EmptyStateView(
            icon: "cart.badge.minus",
            title: "Your cart is empty",
            message: "Add items to get started",
            buttonTitle: "Browse Products"
        ) {}
        ErrorBanner(message: "Something went wrong") {}
    }
}
