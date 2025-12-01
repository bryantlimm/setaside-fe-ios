//
//  MainTabView.swift
//  SetAside
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var cartViewModel: CartViewModel
    @StateObject private var productViewModel = ProductViewModel()
    
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            Group {
                switch selectedTab {
                case 0:
                    HomeView()
                        .environmentObject(productViewModel)
                case 1:
                    OrdersView()
                case 2:
                    ProfileView()
                default:
                    HomeView()
                        .environmentObject(productViewModel)
                }
            }
            
            // Bottom Navigation Bar
            bottomNavBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    private var bottomNavBar: some View {
        HStack(spacing: 0) {
            TabBarItem(
                icon: "home",
                title: "Home",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            TabBarItem(
                icon: "receipt",
                title: "Orders",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }
            
            TabBarItem(
                icon: "account",
                title: "Profile",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -4)
        )
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(icon)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .primaryGreen : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isSelected
                ? Color.primaryGreen.opacity(0.1)
                : Color.clear
            )
            .cornerRadius(12)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(CartViewModel())
}
