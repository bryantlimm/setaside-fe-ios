//
//  OrdersView.swift
//  SetAside
//

import SwiftUI

struct OrdersView: View {
    @StateObject private var orderViewModel = OrderViewModel()
    @State private var selectedOrder: Order?
    @State private var showCompleted = false
    
    // Separate active and completed orders
    var activeOrders: [Order] {
        orderViewModel.orders.filter { order in
            order.status != "pickedup" && order.status != "completed"
        }
    }
    
    var completedOrders: [Order] {
        orderViewModel.orders.filter { order in
            order.status == "pickedup" || order.status == "completed"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundGreen
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Green Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Orders")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Track your order status")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.primaryGreen)
                    
                    // Tab Selector
                    HStack(spacing: 0) {
                        OrderTabButton(
                            title: "Active",
                            count: activeOrders.count,
                            isSelected: !showCompleted
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showCompleted = false
                            }
                        }
                        
                        OrderTabButton(
                            title: "Completed",
                            count: completedOrders.count,
                            isSelected: showCompleted
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showCompleted = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    
                    // Orders List
                    if orderViewModel.isLoading && orderViewModel.orders.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading orders...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else if (showCompleted ? completedOrders : activeOrders).isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: showCompleted ? "checkmark.circle" : "bag")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                            Text(showCompleted ? "No Completed Orders" : "No Active Orders")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text(showCompleted ? "Your completed orders will appear here" : "Your active orders will appear here")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(showCompleted ? completedOrders : activeOrders) { order in
                                    CustomerOrderCard(order: order) {
                                        selectedOrder = order
                                    }
                                    .onAppear {
                                        orderViewModel.loadMoreIfNeeded(currentOrder: order)
                                    }
                                }
                                
                                if orderViewModel.isLoading {
                                    ProgressView()
                                        .padding()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .sheet(item: $selectedOrder) { order in
                OrderDetailView(order: order)
            }
            .refreshable {
                await orderViewModel.fetchOrders(refresh: true)
            }
            .alert("Error", isPresented: $orderViewModel.showError) {
                Button("OK") {
                    orderViewModel.clearError()
                }
            } message: {
                Text(orderViewModel.errorMessage ?? "An error occurred")
            }
        }
    }
}

// MARK: - Order Tab Button
struct OrderTabButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                    
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(isSelected ? .white : .gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isSelected ? Color.primaryGreen : Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .foregroundColor(isSelected ? .primaryGreen : .gray)
                
                // Underline indicator
                Rectangle()
                    .fill(isSelected ? Color.primaryGreen : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Customer Order Card
struct CustomerOrderCard: View {
    let order: Order
    let onTap: () -> Void
    
    // Simplified status for customer
    var customerStatus: (text: String, color: Color, icon: String) {
        switch order.status {
        case "pending", "preparing":
            return ("Waiting for your order", .orange, "clock.fill")
        case "ready":
            return ("Ready for Pickup!", .green, "checkmark.circle.fill")
        case "pickedup", "completed":
            return ("Completed", .gray, "bag.fill")
        default:
            return ("Processing", .blue, "arrow.triangle.2.circlepath")
        }
    }
    
    var isReady: Bool {
        order.status == "ready"
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Main Content
                VStack(alignment: .leading, spacing: 12) {
                    // Header Row
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Order #\(order.id.prefix(8).uppercased())")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(order.formattedDate)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Total
                        if let total = order.totalAmount, total > 0 {
                            Text("$\(total, specifier: "%.2f")")
                                .font(.headline)
                                .foregroundColor(.primaryGreen)
                        }
                    }
                    
                    // Items Summary
                    if let items = order.items, !items.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(items.count) item\(items.count > 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let firstItem = items.first {
                                Text(items.count > 1 ? "\(firstItem.displayName) + \(items.count - 1) more" : firstItem.displayName)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    // Pickup Time
                    if let pickupTime = order.pickupTime, !pickupTime.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.caption)
                            Text("Pickup: \(formatPickupTime(pickupTime))")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.purple)
                    }
                }
                .padding(16)
                
                // Status Banner
                HStack(spacing: 8) {
                    Image(systemName: customerStatus.icon)
                        .font(.subheadline)
                    
                    Text(customerStatus.text)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if isReady {
                        Text("TAP TO VIEW")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(customerStatus.color)
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isReady ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatPickupTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, h:mm a"
            return displayFormatter.string(from: date)
        }
        
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, h:mm a"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

#Preview {
    OrdersView()
}
