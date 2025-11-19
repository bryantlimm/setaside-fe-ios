//
//  HeaderView.swift
//  SetAside
//
//  Created by Bryant Aryadi on 11/11/25.
//

import SwiftUI

struct HeaderView: View {
    var username: String
    @State private var navigateToCart = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello,")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                Text(username)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            NavigationLink(destination: CartView(), isActive: $navigateToCart) {
                EmptyView()
            }
            .hidden()
            
            Button(action: {
                navigateToCart = true
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image("cart")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(red: 0.38, green: 0.51, blue: 0.39))
    }
}

// Cart Item Model
struct CartItem: Identifiable {
    let id = UUID()
    let name: String
    let price: Double
    var quantity: Int
    let imageName: String
}

// Cart View
struct CartView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var cartItems = [
        CartItem(name: "Fresh Tomatoes", price: 3.99, quantity: 2, imageName: "veggies"),
        CartItem(name: "Premium Beef", price: 12.99, quantity: 1, imageName: "meat"),
        CartItem(name: "Potato Chips", price: 2.49, quantity: 3, imageName: "snacks")
    ]
    
    var totalPrice: Double {
        cartItems.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.97, blue: 0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Cart Header
                HStack {
                    Text("My Cart")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                    
                    Spacer()
                    
                    Text("\(cartItems.count) items")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                
                if cartItems.isEmpty {
                    // Empty Cart State
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "cart.badge.minus")
                            .font(.system(size: 80))
                            .foregroundColor(Color(red: 0.82, green: 0.91, blue: 0.82))
                        
                        Text("Your cart is empty")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                        
                        Text("Add items to get started")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                } else {
                    // Cart Items List
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(cartItems.indices, id: \.self) { index in
                                CartItemRow(
                                    item: $cartItems[index],
                                    onDelete: { cartItems.remove(at: index) }
                                )
                            }
                        }
                        .padding()
                    }
                    
                    // Bottom Summary Section
                    VStack(spacing: 16) {
                        Divider()
                        
                        // Price Summary
                        VStack(spacing: 8) {
                            HStack {
                                Text("Total")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                                Spacer()
                                Text("$\(totalPrice, specifier: "%.2f")")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                            }
                        }
                        .padding(.horizontal)
                        
                        // Checkout Button
                        NavigationLink(destination: CheckoutView(totalAmount: totalPrice, itemCount: cartItems.count)) {
                            Text("Proceed to Checkout")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.38, green: 0.51, blue: 0.39))
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
        .navigationBarHidden(true)
    }
}

// Cart Item Row
struct CartItemRow: View {
    @Binding var item: CartItem
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Product Image
            Image(item.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .background(Color(red: 0.85, green: 0.93, blue: 0.85))
                .cornerRadius(12)
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                Text("$\(item.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                    .fontWeight(.bold)
                
                // Quantity Controls
                HStack(spacing: 12) {
                    Button(action: {
                        if item.quantity > 1 {
                            item.quantity -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                            .font(.title3)
                    }
                    
                    Text("\(item.quantity)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(minWidth: 20)
                    
                    Button(action: {
                        item.quantity += 1
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
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

// Checkout View
struct CheckoutView: View {
    @Environment(\.presentationMode) var presentationMode
    let totalAmount: Double
    let itemCount: Int
    
    @State private var showOrderComplete = false
    
    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.97, blue: 0.95)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Checkout")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                        
                        Text("Review your order details")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    
                    // Order Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Order Summary")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                        
                        HStack {
                            Image(systemName: "cart.fill")
                                .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                            Text("\(itemCount) items")
                                .foregroundColor(.gray)
                            Spacer()
                            Text("$\(totalAmount, specifier: "%.2f")")
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                        }
                        
                        Divider()
                        
                        HStack {
                            Image(systemName: "bag.fill")
                                .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                            Text("Pickup Order")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Pickup Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Pickup Details")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                        
                        VStack(spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Pickup Time")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("You'll be notified when your order is ready")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            
                            Divider()
                            
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Order Status")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Check Activity page for updates")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Payment Method
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Payment Method")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                        
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                                .font(.title2)
                            Text("Cash on Pickup")
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                        }
                        .padding()
                        .background(Color(red: 0.85, green: 0.93, blue: 0.85))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
            
            // Bottom Checkout Button
            VStack {
                Spacer()
                
                Button(action: {
                    showOrderComplete = true
                }) {
                    Text("Place Order - $\(totalAmount, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.38, green: 0.51, blue: 0.39))
                        .cornerRadius(12)
                }
                .padding()
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -4)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showOrderComplete) {
            OrderCompleteModal()
        }
    }
}

// Order Complete Modal
struct OrderCompleteModal: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Success Icon
                ZStack {
                    Circle()
                        .fill(Color(red: 0.85, green: 0.93, blue: 0.85))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                }
                .padding(.top, 20)
                
                // Title
                Text("Order Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                
                // Message
                VStack(spacing: 12) {
                    Text("Your order has been placed successfully.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                    
                    Text("Please check your Activity page to track your order status and see when it's ready for pickup.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                
                // Order Number
                VStack(spacing: 4) {
                    Text("Order Number")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("#\(Int.random(in: 10000...99999))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                }
                .padding()
                .background(Color(red: 0.95, green: 0.97, blue: 0.95))
                .cornerRadius(12)
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        // Navigate to Activity page
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("View in Activity")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.38, green: 0.51, blue: 0.39))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Continue Shopping")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.38, green: 0.51, blue: 0.39))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.38, green: 0.51, blue: 0.39), lineWidth: 2)
                            )
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .padding(40)
        }
    }
}

#Preview {
    NavigationView {
        HeaderView(username: "Bryant")
    }
}
