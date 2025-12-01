//
//  AdminOrdersView.swift
//  SetAside
//

import SwiftUI

struct AdminOrdersView: View {
    @StateObject private var viewModel = AdminOrderViewModel()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Status Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        StatusFilterButton(
                            title: "All",
                            count: viewModel.orders.count,
                            isSelected: viewModel.selectedStatus == "all",
                            color: .primary
                        ) {
                            viewModel.selectedStatus = "all"
                        }
                        
                        StatusFilterButton(
                            title: "Pending",
                            count: viewModel.pendingOrders.count,
                            isSelected: viewModel.selectedStatus == "pending",
                            color: .orange
                        ) {
                            viewModel.selectedStatus = "pending"
                        }
                        
                        StatusFilterButton(
                            title: "Preparing",
                            count: viewModel.preparingOrders.count,
                            isSelected: viewModel.selectedStatus == "preparing",
                            color: .blue
                        ) {
                            viewModel.selectedStatus = "preparing"
                        }
                        
                        StatusFilterButton(
                            title: "Ready",
                            count: viewModel.readyOrders.count,
                            isSelected: viewModel.selectedStatus == "ready",
                            color: .green
                        ) {
                            viewModel.selectedStatus = "ready"
                        }
                        
                        StatusFilterButton(
                            title: "Picked Up",
                            count: viewModel.pickedUpOrders.count,
                            isSelected: viewModel.selectedStatus == "picked_up",
                            color: .gray
                        ) {
                            viewModel.selectedStatus = "picked_up"
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))
                
                Divider()
                
                // Orders List
                if viewModel.isLoading && viewModel.orders.isEmpty {
                    Spacer()
                    ProgressView("Loading orders...")
                    Spacer()
                } else if viewModel.filteredOrders.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No orders found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text(viewModel.selectedStatus == "all" ? "No orders have been placed yet" : "No \(viewModel.selectedStatus.replacingOccurrences(of: "_", with: " ")) orders")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.filteredOrders) { order in
                            AdminOrderRow(order: order, viewModel: viewModel) { orderId, newStatus in
                                Task {
                                    let success = await viewModel.updateOrderStatus(orderId: orderId, newStatus: newStatus)
                                    if success {
                                        alertMessage = "Order status updated to \(newStatus.replacingOccurrences(of: "_", with: " "))"
                                        isSuccess = true
                                    } else {
                                        alertMessage = viewModel.errorMessage ?? "Failed to update order status"
                                        isSuccess = false
                                    }
                                    showAlert = true
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.loadAllOrders()
                    }
                }
            }
            .navigationTitle("Orders")
            .alert(isSuccess ? "Success" : "Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .task {
                await viewModel.loadAllOrders()
            }
        }
    }
}

struct StatusFilterButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? color : Color.gray.opacity(0.3))
                    .foregroundColor(isSelected ? .white : .primary)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(0.15) : Color.clear)
            .foregroundColor(isSelected ? color : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct AdminOrderRow: View {
    let order: Order
    @ObservedObject var viewModel: AdminOrderViewModel
    let onStatusUpdate: (String, String) -> Void
    
    @State private var showStatusPicker = false
    @State private var isExpanded = false
    
    var statusColor: Color {
        switch order.status {
        case "pending": return .orange
        case "preparing": return .blue
        case "ready": return .green
        case "picked_up": return .gray
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order #\(String(order.id.prefix(8)).uppercased())")
                        .font(.headline)
                    
                    if let createdAt = order.createdAt {
                        Text(formatDate(createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status Badge
                Menu {
                    ForEach(viewModel.orderStatuses, id: \.self) { status in
                        Button {
                            if status != order.status {
                                onStatusUpdate(order.id, status)
                            }
                        } label: {
                            HStack {
                                Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
                                if status == order.status {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(order.status.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(12)
                }
            }
            
            // Quick Action Button (if not picked up)
            if let nextStatus = viewModel.getNextStatus(currentStatus: order.status) {
                Button {
                    onStatusUpdate(order.id, nextStatus)
                } label: {
                    HStack {
                        Image(systemName: statusIcon(for: nextStatus))
                        Text("Mark as \(nextStatus.replacingOccurrences(of: "_", with: " ").capitalized)")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(statusColor(for: nextStatus).opacity(0.15))
                    .foregroundColor(statusColor(for: nextStatus))
                    .cornerRadius(8)
                }
            }
            
            // Order Items (expandable)
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(order.items ?? [], id: \.id) { item in
                        HStack {
                            Text("\(item.quantity)x")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 30, alignment: .leading)
                            
                            Text(item.product?.name ?? "Unknown Product")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(String(format: "$%.2f", item.totalPrice))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(String(format: "$%.2f", order.totalAmount ?? 0))
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                }
                .padding(.top, 8)
            } label: {
                HStack {
                    Text("\((order.items ?? []).count) item\((order.items ?? []).count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(String(format: "$%.2f", order.totalAmount ?? 0))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    private func statusIcon(for status: String) -> String {
        switch status {
        case "pending": return "clock"
        case "preparing": return "flame"
        case "ready": return "checkmark.circle"
        case "picked_up": return "bag.fill"
        default: return "circle"
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "pending": return .orange
        case "preparing": return .blue
        case "ready": return .green
        case "picked_up": return .gray
        default: return .gray
        }
    }
}

#Preview {
    AdminOrdersView()
}
