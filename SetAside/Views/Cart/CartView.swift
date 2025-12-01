//
//  CartView.swift
//  SetAside
//

import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showCheckout = false
    
    var body: some View {
        ZStack {
            Color.backgroundGreen
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("My Cart")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.darkGreen)
                    
                    Spacer()
                    
                    Text("\(cartViewModel.itemCount) items")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                
                if cartViewModel.isEmpty {
                    // Empty Cart
                    EmptyStateView(
                        icon: "cart.badge.minus",
                        title: "Your cart is empty",
                        message: "Add items to get started with your order",
                        buttonTitle: "Browse Products"
                    ) {
                        dismiss()
                    }
                } else {
                    // Cart Items
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(cartViewModel.items.enumerated()), id: \.element.id) { index, item in
                                CartItemRow(
                                    item: item,
                                    onIncrement: { cartViewModel.incrementQuantity(at: index) },
                                    onDecrement: { cartViewModel.decrementQuantity(at: index) },
                                    onDelete: { cartViewModel.removeItem(at: index) }
                                )
                            }
                        }
                        .padding()
                    }
                    
                    // Bottom Summary
                    VStack(spacing: 16) {
                        Divider()
                        
                        // Price Summary
                        VStack(spacing: 8) {
                            HStack {
                                Text("Subtotal")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("$\(cartViewModel.totalPrice, specifier: "%.2f")")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Total")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.darkGreen)
                                Spacer()
                                Text("$\(cartViewModel.totalPrice, specifier: "%.2f")")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primaryGreen)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Checkout Button
                        Button(action: { showCheckout = true }) {
                            Text("Proceed to Checkout")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.primaryGreen)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -4)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primaryGreen)
                        .fontWeight(.semibold)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if !cartViewModel.isEmpty {
                    Button("Clear") {
                        cartViewModel.clearCart()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .navigationDestination(isPresented: $showCheckout) {
            CheckoutView()
        }
    }
}

// MARK: - Cart Item Row
struct CartItemRow: View {
    let item: CartItem
    var onIncrement: () -> Void
    var onDecrement: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Product Image
            AsyncImage(url: URL(string: item.product.imageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                default:
                    Rectangle()
                        .fill(Color.lightGreen)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: 70, height: 70)
            .cornerRadius(12)
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Text("$\(item.product.price, specifier: "%.2f") each")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("$\(item.totalPrice, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryGreen)
                
                if let instructions = item.specialInstructions, !instructions.isEmpty {
                    Text("Note: \(instructions)")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .lineLimit(1)
                }
                
                // Quantity Controls
                HStack(spacing: 12) {
                    Button(action: onDecrement) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.primaryGreen)
                            .font(.title3)
                    }
                    
                    Text("\(item.quantity)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(minWidth: 20)
                    
                    Button(action: onIncrement) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.primaryGreen)
                            .font(.title3)
                    }
                }
            }
            
            Spacer()
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red.opacity(0.7))
                    .font(.title3)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        CartView()
            .environmentObject(CartViewModel())
    }
}
