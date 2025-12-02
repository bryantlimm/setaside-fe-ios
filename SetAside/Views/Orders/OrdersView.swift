//
//  OrdersView.swift
//  SetAside
//

import SwiftUI

struct OrdersView: View {
    @StateObject private var orderViewModel = OrderViewModel()
    @State private var selectedOrder: Order?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundGreen
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("My Orders")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.darkGreen)
                        
                        Text("Track your order status")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    
                    // Status Filter
                    statusFilter
                    
                    // Orders List
                    if orderViewModel.isLoading && orderViewModel.orders.isEmpty {
                        LoadingView(message: "Loading orders...")
                    } else if orderViewModel.orders.isEmpty {
                        EmptyStateView(
                            icon: "bag",
                            title: "No Orders Yet",
                            message: "Your order history will appear here"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(orderViewModel.orders) { order in
                                    OrderRow(order: order) {
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
                            .padding()
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
    
    private var statusFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                StatusFilterChip(
                    title: "All",
                    isSelected: orderViewModel.selectedStatus == nil
                ) {
                    orderViewModel.filterByStatus(nil)
                }
                
                ForEach(AppConstants.OrderStatus.allCases, id: \.rawValue) { status in
                    StatusFilterChip(
                        title: status.displayName,
                        isSelected: orderViewModel.selectedStatus == status.rawValue
                    ) {
                        orderViewModel.filterByStatus(status.rawValue)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color.white)
    }
}

// MARK: - Status Filter Chip
struct StatusFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .darkGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.primaryGreen : Color.lightGreen)
                .cornerRadius(16)
        }
    }
}

// MARK: - Order Row
struct OrderRow: View {
    let order: Order
    let onTap: () -> Void
    
    var statusColor: Color {
        switch order.statusEnum {
        case .pending: return .orange
        case .preparing: return .blue
        case .ready: return .green
        case .pickedUp: return .gray
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Order #\(order.id.prefix(8).uppercased())")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(order.formattedDate)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Status Badge
                    HStack(spacing: 4) {
                        Image(systemName: order.statusEnum.iconName)
                            .font(.caption)
                        Text(order.statusEnum.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusColor)
                    .cornerRadius(12)
                }
                
                // Scheduled Pickup Time
                if let pickupTime = order.pickupTime, !pickupTime.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.caption)
                        Text("Pickup: \(formatPickupTime(pickupTime))")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.purple)
                }
                
                // Items Preview
                if let items = order.items, !items.isEmpty {
                    HStack {
                        // Show items summary
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(items.count) item(s)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            // Show first item name as preview using displayName
                            if let firstItem = items.first {
                                let itemName = firstItem.displayName
                                Text(items.count > 1 ? "\(itemName) + \(items.count - 1) more" : itemName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        // Payment Status
                        HStack(spacing: 4) {
                            Image(systemName: order.status == "pickedup" ? "checkmark.circle.fill" : "banknote.fill")
                                .font(.caption)
                            Text(order.status == "pickedup" ? "Paid" : "Pay at Pickup")
                                .font(.caption)
                        }
                        .foregroundColor(order.status == "pickedup" ? .green : .blue)
                    }
                } else {
                    // Fallback when items not available in list view
                    HStack {
                        Text("Tap to view details")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        // Payment Status
                        HStack(spacing: 4) {
                            Image(systemName: order.status == "pickedup" ? "checkmark.circle.fill" : "banknote.fill")
                                .font(.caption)
                            Text(order.status == "pickedup" ? "Paid" : "Pay at Pickup")
                                .font(.caption)
                        }
                        .foregroundColor(order.status == "pickedup" ? .green : .blue)
                    }
                }
                
                // Total
                HStack {
                    Text("Total")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if let total = order.totalAmount, total > 0 {
                        Text("$\(total, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(.primaryGreen)
                    } else {
                        Text("View details")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Notes
                if let notes = order.notes, !notes.isEmpty {
                    Text("Note: \(notes)")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .lineLimit(1)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
        
        // Try without fractional seconds
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
