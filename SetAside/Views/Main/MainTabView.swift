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
    @State private var hideTabBar = false
    
    // Check if user is admin or cashier (staff)
    private var isStaff: Bool {
        guard let role = authViewModel.currentUser?.role else { return false }
        return role == "admin" || role == "cashier"
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            Group {
                if isStaff {
                    // Staff view (Admin/Cashier)
                    switch selectedTab {
                    case 0:
                        AdminOrdersView()
                    case 1:
                        AdminProductListView()
                    case 2:
                        ProfileView()
//                        in case mau debugging:
//                        HomeView(hideTabBar: $hideTabBar)
//                            .environmentObject(productViewModel)
//                    case 3:
//                        ProfileView()
                    default:
                        AdminOrdersView()
                    }
                } else {
                    // Customer view
                    switch selectedTab {
                    case 0:
                        HomeView(hideTabBar: $hideTabBar)
                            .environmentObject(productViewModel)
                    case 1:
                        OrdersView()
                    case 2:
                        ProfileView()
                    default:
                        HomeView(hideTabBar: $hideTabBar)
                            .environmentObject(productViewModel)
                    }
                }
            }
            
            // Bottom Navigation Bar - hide when navigating to cart/checkout
            if !hideTabBar {
                if isStaff {
                    staffBottomNavBar
                } else {
                    customerBottomNavBar
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    // Customer Bottom Nav Bar (3 tabs)
    private var customerBottomNavBar: some View {
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
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // Staff Bottom Nav Bar (4 tabs: Orders, Products, Shop, Profile)
    private var staffBottomNavBar: some View {
        HStack(spacing: 0) {
            TabBarItemWithSystemIcon(
                systemIcon: "list.clipboard",
                title: "Orders",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            TabBarItemWithSystemIcon(
                systemIcon: "cube.box",
                title: "Products",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }
            
            TabBarItem(
                icon: "home",
                title: "Shop",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
            
//           for debugging purposes hehe (kalo bisa jangan di hapus)
//            TabBarItem(
//                icon: "account",
//                title: "Profile",
//                isSelected: selectedTab == 3
//            ) {
//                selectedTab = 3
//            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Tab Bar Item (Asset Image)
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

// MARK: - Tab Bar Item (System Icon)
struct TabBarItemWithSystemIcon: View {
    let systemIcon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemIcon)
                    .resizable()
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
