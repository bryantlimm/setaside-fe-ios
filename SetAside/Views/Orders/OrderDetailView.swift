//
//  OrderDetailView.swift
//  SetAside
//

import SwiftUI

struct OrderDetailView: View {
    let order: Order
    @Environment(\.dismiss) var dismiss
    @StateObject private var orderViewModel = OrderViewModel()
    @State private var showCancelConfirmation = false
    @State private var isEditing = false
    @State private var editedNotes: String = ""
    @State private var editedPickupTime: Date = Date()
    
    var statusColor: Color {
        switch order.statusEnum {
        case .pending: return .orange
        case .preparing: return .blue
        case .ready: return .green
        case .pickedUp: return .gray
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundGreen
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Status Card
                        statusCard
                        
                        // Order Info
                        orderInfoCard
                        
                        // Order Items
                        if let items = order.items, !items.isEmpty {
                            orderItemsCard(items: items)
                        }
                        
                        // Actions (only for pending orders)
                        if order.status == "pending" {
                            actionsCard
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .alert("Cancel Order", isPresented: $showCancelConfirmation) {
                Button("Keep Order", role: .cancel) {}
                Button("Cancel Order", role: .destructive) {
                    Task {
                        await orderViewModel.cancelOrder(orderId: order.id)
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to cancel this order? This action cannot be undone.")
            }
            .sheet(isPresented: $isEditing) {
                editOrderSheet
            }
            .onAppear {
                editedNotes = order.notes ?? ""
            }
        }
    }
    
    // MARK: - Status Card
    private var statusCard: some View {
        VStack(spacing: 16) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: order.statusEnum.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(statusColor)
            }
            
            // Status Text
            VStack(spacing: 4) {
                Text(order.statusEnum.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(statusColor)
                
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            // Progress Bar
            statusProgressBar
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private var statusMessage: String {
        switch order.statusEnum {
        case .pending:
            return "Your order is waiting to be prepared"
        case .preparing:
            return "Your order is being prepared"
        case .ready:
            return "Your order is ready for pickup!"
        case .pickedUp:
            return "Order completed"
        }
    }
    
    private var statusProgressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<4) { index in
                Rectangle()
                    .fill(index <= statusIndex ? statusColor : Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
            }
        }
    }
    
    private var statusIndex: Int {
        switch order.statusEnum {
        case .pending: return 0
        case .preparing: return 1
        case .ready: return 2
        case .pickedUp: return 3
        }
    }
    
    // MARK: - Order Info Card
    private var orderInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Order Information")
                .font(.headline)
                .foregroundColor(.darkGreen)
            
            // Order ID
            infoRow(icon: "number", title: "Order ID", value: "#\(order.id.prefix(8).uppercased())")
            
            // Date
            infoRow(icon: "calendar", title: "Placed on", value: order.formattedDate)
            
            // Payment Method
            HStack {
                Image(systemName: order.status == "picked_up" ? "checkmark.circle.fill" : "banknote.fill")
                    .foregroundColor(order.status == "picked_up" ? .green : .blue)
                    .frame(width: 24)
                
                Text("Payment")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(order.status == "picked_up" ? "Paid" : "Pay at Pickup")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(order.status == "picked_up" ? .green : .blue)
            }
            
            // Pickup Time
            if let pickupTime = order.pickupTime, !pickupTime.isEmpty {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    Text("Scheduled Pickup")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(formatPickupTime(pickupTime))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                }
            }
            
            // Notes
            if let notes = order.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundColor(.primaryGreen)
                            .frame(width: 24)
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Text(notes)
                        .font(.body)
                        .padding(.leading, 32)
                }
            }
            
            Divider()
            
            // Total
            HStack {
                Text("Total Amount")
                    .font(.headline)
                Spacer()
                if let total = order.totalAmount {
                    Text("$\(total, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryGreen)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private func formatPickupTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, h:mm a"
            return displayFormatter.string(from: date)
        }
        
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, h:mm a"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.primaryGreen)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Order Items Card
    private func orderItemsCard(items: [OrderItem]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Order Items")
                .font(.headline)
                .foregroundColor(.darkGreen)
            
            ForEach(items) { item in
                HStack(spacing: 12) {
                    // Quantity
                    Text("x\(item.quantity)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.primaryGreen)
                        .cornerRadius(8)
                    
                    // Item Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.product?.name ?? "Product")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if let instructions = item.specialInstructions, !instructions.isEmpty {
                            Text(instructions)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer()
                    
                    // Price
                    Text("$\(item.totalPrice, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryGreen)
                }
                
                if item.id != items.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - Actions Card
    private var actionsCard: some View {
        VStack(spacing: 12) {
            SecondaryButton(title: "Edit Order") {
                isEditing = true
            }
            
            Button(action: { showCancelConfirmation = true }) {
                Text("Cancel Order")
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - Edit Order Sheet
    private var editOrderSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Order Notes")
                        .font(.headline)
                    
                    TextField("Add any special requests...", text: $editedNotes, axis: .vertical)
                        .lineLimit(3...5)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Spacer()
                
                PrimaryButton(title: "Save Changes", isLoading: orderViewModel.isLoading) {
                    Task {
                        await orderViewModel.updateOrder(
                            orderId: order.id,
                            notes: editedNotes.isEmpty ? nil : editedNotes,
                            pickupTime: nil
                        )
                        isEditing = false
                    }
                }
            }
            .padding()
            .navigationTitle("Edit Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isEditing = false
                    }
                }
            }
        }
    }
}

#Preview {
    OrderDetailView(order: Order(
        id: "abc123def456",
        customerId: "user123",
        status: "preparing",
        notes: "Please prepare fresh",
        pickupTime: nil,
        totalAmount: 25.99,
        items: [],
        customer: nil,
        createdAt: "2024-01-15T10:30:00Z",
        updatedAt: nil
    ))
}
