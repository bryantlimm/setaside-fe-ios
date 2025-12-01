//
//  RootView.swift
//  SetAside
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isLoggedIn {
                MainTabView()
            } else {
                SignInView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isLoggedIn)
    }
}

#Preview {
    RootView()
        .environmentObject(AuthViewModel())
        .environmentObject(CartViewModel())
}
