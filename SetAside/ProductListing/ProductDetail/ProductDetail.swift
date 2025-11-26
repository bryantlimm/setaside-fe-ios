//
//  ProductDetail.swift
//  SetAside
//
//  Created by Rukiye Verep on 24.11.25.
//

import SwiftUI

struct ProductDetail: View {
    let productName: String
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Transparent green overlay background
            Color(red: 0.38, green: 0.51, blue: 0.39)
                .opacity(0.9)
                .ignoresSafeArea()
            
            // White content block
            VStack(spacing: 0) {
                // Tab selection
                HStack {
                    TabButton(title: "Details", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    TabButton(title: "Location", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                    Spacer()
                    
                    // Close button
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 14, height: 14)
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                // Product Image
                Image("cabbage")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                
                // Content based on selected tab
                if selectedTab == 0 {
                    DetailsView()
                } else {
                    LocationView()
                }
                
                Spacer()
                
                // ADD TO CART button
                Button(action: {
                    // Add to cart action
                    print("Added to cart")
                }) {
                    Text("ADD TO CART")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.38, green: 0.51, blue: 0.39))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 20)
            .padding(.vertical, 60)
        }
    }
}

// Tab Button Component
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .black : .gray)
                
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(isSelected ? Color(red: 0.38, green: 0.51, blue: 0.39) : .clear)
            }
        }
    }
}

#Preview {
    ProductDetail(productName: "Fresh Cabbage")
}
