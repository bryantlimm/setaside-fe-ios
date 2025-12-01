//
//  CheckoutView.swift
//  SetAside
//

import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var orderNotes: String = ""
    @State private var pickupTime: Date = Date().addingTimeInterval(3600) // 1 hour from now
    @State private var useScheduledPickup: Bool = false
    @State private var showOrderComplete: Bool = false
    @State private var shouldNavigateToHome: Bool = false
    
    var body: some View {
        ZStack {
            Color.backgroundGreen
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Checkout")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.darkGreen)
                        
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
                            .foregroundColor(.darkGreen)
                        
                        ForEach(cartViewModel.items) { item in
                            HStack {
                                Text(item.product.name)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("x\(item.quantity)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text("$\(item.totalPrice, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total (\(cartViewModel.itemCount) items)")
                                .font(.headline)
                            Spacer()
                            Text("$\(cartViewModel.totalPrice, specifier: "%.2f")")
                                .font(.headline)
                                .foregroundColor(.primaryGreen)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Pickup Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Pickup Details")
                            .font(.headline)
                            .foregroundColor(.darkGreen)
                        
                        // ASAP vs Scheduled
                        VStack(spacing: 12) {
                            PickupOptionRow(
                                icon: "clock.fill",
                                title: "Pick up ASAP",
                                subtitle: "Ready when your order is prepared",
                                isSelected: !useScheduledPickup
                            ) {
                                useScheduledPickup = false
                            }
                            
                            PickupOptionRow(
                                icon: "calendar",
                                title: "Schedule Pickup",
                                subtitle: "Choose a specific time",
                                isSelected: useScheduledPickup
                            ) {
                                useScheduledPickup = true
                            }
                        }
                        
                        if useScheduledPickup {
                            DatePicker(
                                "Pickup Time",
                                selection: $pickupTime,
                                in: Date()...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Order Notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Order Notes (Optional)")
                            .font(.headline)
                            .foregroundColor(.darkGreen)
                        
                        TextField("Add any special requests for your order...", text: $orderNotes, axis: .vertical)
                            .lineLimit(3...5)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Payment Method
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Payment Method")
                            .font(.headline)
                            .foregroundColor(.darkGreen)
                        
                        HStack {
                            Image(systemName: "banknote.fill")
                                .foregroundColor(.primaryGreen)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pay When Picked Up")
                                    .fontWeight(.medium)
                                Text("Payment will be collected at pickup")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.primaryGreen)
                        }
                        .padding()
                        .background(Color.lightGreen)
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
            
            // Bottom Place Order Button
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    Divider()
                    
                    Button(action: placeOrder) {
                        HStack {
                            if cartViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "bag.fill")
                                Text("Place Order - $\(cartViewModel.totalPrice, specifier: "%.2f")")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryGreen)
                        .cornerRadius(12)
                    }
                    .disabled(cartViewModel.isLoading)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                }
                .background(Color.white)
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
        }
        .alert("Error", isPresented: $cartViewModel.showError) {
            Button("OK") {
                cartViewModel.clearError()
            }
        } message: {
            Text(cartViewModel.errorMessage ?? "An error occurred")
        }
        .sheet(isPresented: $showOrderComplete, onDismiss: {
            // When sheet is dismissed, go back to home
            if shouldNavigateToHome {
                dismiss()
            }
        }) {
            OrderCompleteView(order: cartViewModel.lastOrder, onContinueShopping: {
                shouldNavigateToHome = true
                showOrderComplete = false
            })
        }
        .onChange(of: cartViewModel.orderPlaced) { _, placed in
            if placed {
                showOrderComplete = true
            }
        }
    }
    
    private func placeOrder() {
        Task {
            await cartViewModel.placeOrder(
                notes: orderNotes.isEmpty ? nil : orderNotes,
                pickupTime: useScheduledPickup ? pickupTime : nil
            )
        }
    }
}

// MARK: - Pickup Option Row
struct PickupOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.primaryGreen)
                    .font(.title3)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .primaryGreen : .gray)
            }
            .padding()
            .background(isSelected ? Color.lightGreen : Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Order Complete View
struct OrderCompleteView: View {
    let order: Order?
    var onContinueShopping: () -> Void
    @EnvironmentObject var cartViewModel: CartViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundGreen
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Success Icon
                    ZStack {
                        Circle()
                            .fill(Color.lightGreen)
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.primaryGreen)
                    }
                    
                    // Title
                    Text("Order Placed!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.darkGreen)
                    
                    // Message
                    VStack(spacing: 8) {
                        Text("Your order has been confirmed.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                        
                        Text("The store is preparing your order now.")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primaryGreen)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "banknote.fill")
                                .foregroundColor(.orange)
                            Text("Pay when you pick up your order")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)
                    
                    // Order Info Card
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "receipt")
                                .foregroundColor(.primaryGreen)
                            Text("Order Confirmed")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Divider()
                        
                        if let order = order {
                            HStack {
                                Text("Order ID")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("#\(order.id.prefix(8).uppercased())")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primaryGreen)
                            }
                            
                            if let total = order.totalAmount {
                                HStack {
                                    Text("Total")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("$\(total, specifier: "%.2f")")
                                        .font(.headline)
                                        .foregroundColor(.darkGreen)
                                }
                            }
                        }
                        
                        HStack {
                            Text("Status")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 8, height: 8)
                                Text("Pending")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        HStack {
                            Text("Payment")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("Pay at Pickup")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Tip to check orders
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("View the Orders tab to track your order status")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Button
                    VStack(spacing: 12) {
                        PrimaryButton(title: "Continue Shopping") {
                            cartViewModel.resetOrderPlaced()
                            onContinueShopping()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled() // Prevent swipe to dismiss
        }
    }
}

#Preview {
    NavigationStack {
        CheckoutView()
            .environmentObject(CartViewModel())
    }
}
