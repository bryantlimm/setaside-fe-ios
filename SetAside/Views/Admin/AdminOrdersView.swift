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
    @State private var searchText = ""
    @State private var showStatusConfirmation = false
    @State private var pendingStatusUpdate: (orderId: String, newStatus: String, order: Order)?
    
    var searchedOrders: [Order] {
        if searchText.isEmpty {
            return viewModel.filteredOrders
        }
        return viewModel.filteredOrders.filter { order in
            // Search by order ID
            if order.id.lowercased().contains(searchText.lowercased()) {
                return true
            }
            // Search by customer name
            if let name = order.customer?.fullName,
               name.lowercased().contains(searchText.lowercased()) {
                return true
            }
            // Search by customer phone
            if let phone = order.customer?.phone,
               phone.contains(searchText) {
                return true
            }
            // Search by product name in items
            if let items = order.items {
                for item in items {
                    if let productName = item.product?.name,
                       productName.lowercased().contains(searchText.lowercased()) {
                        return true
                    }
                }
            }
            return false
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundGreen
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Order Management")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                            Text("Track & Update Orders")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.darkGreen)
                    
                    // Content
                    VStack(spacing: 0) {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                    
                    TextField("Search by name, phone, order ID, or item...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 12)
                
                // Status Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        StatusFilterButton(
                            title: "Active",
                            count: viewModel.pendingOrders.count + viewModel.preparingOrders.count + viewModel.readyOrders.count + viewModel.pickedUpOrders.count,
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
                            color: .yellow
                        ) {
                            viewModel.selectedStatus = "preparing"
                        }
                        
                        StatusFilterButton(
                            title: "Ready",
                            count: viewModel.readyOrders.count,
                            isSelected: viewModel.selectedStatus == "ready",
                            color: .blue
                        ) {
                            viewModel.selectedStatus = "ready"
                        }
                        
                        StatusFilterButton(
                            title: "Picked Up",
                            count: viewModel.pickedUpOrders.count,
                            isSelected: viewModel.selectedStatus == "pickedup",
                            color: .purple
                        ) {
                            viewModel.selectedStatus = "pickedup"
                        }
                        
                        StatusFilterButton(
                            title: "Completed",
                            count: viewModel.completedOrders.count,
                            isSelected: viewModel.selectedStatus == "completed",
                            color: .green
                        ) {
                            viewModel.selectedStatus = "completed"
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color.backgroundGreen)
                
                // Orders List
                if viewModel.isLoading && viewModel.orders.isEmpty {
                    Spacer()
                    ProgressView("Loading orders...")
                    Spacer()
                } else if searchedOrders.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: searchText.isEmpty ? "doc.text" : "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text(searchText.isEmpty ? "No orders found" : "No matching orders")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text(searchText.isEmpty 
                             ? (viewModel.selectedStatus == "all" ? "No active orders" : "No \(viewModel.selectedStatus.replacingOccurrences(of: "_", with: " ")) orders")
                             : "Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(searchedOrders) { order in
                            AdminOrderRow(order: order, viewModel: viewModel) { orderId, newStatus in
                                pendingStatusUpdate = (orderId, newStatus, order)
                                showStatusConfirmation = true
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.loadAllOrders()
                    }
                }
                    }
                    .background(Color.backgroundGreen)
                }
            }
            .navigationBarHidden(true)
            .alert(isSuccess ? "Success" : "Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .overlay {
                if showStatusConfirmation, let update = pendingStatusUpdate {
                    StatusUpdateConfirmationModal(
                        order: update.order,
                        newStatus: update.newStatus,
                        onConfirm: {
                            showStatusConfirmation = false
                            Task {
                                let success = await viewModel.updateOrderStatus(orderId: update.orderId, newStatus: update.newStatus)
                                if success {
                                    alertMessage = "Order status updated to \(update.newStatus.replacingOccurrences(of: "_", with: " "))"
                                    isSuccess = true
                                } else {
                                    alertMessage = viewModel.errorMessage ?? "Failed to update order status"
                                    isSuccess = false
                                }
                                showAlert = true
                                pendingStatusUpdate = nil
                            }
                        },
                        onCancel: {
                            showStatusConfirmation = false
                            pendingStatusUpdate = nil
                        }
                    )
                }
            }
            .sheet(isPresented: $viewModel.showCompletionModal) {
                OrderCompletionModal(onDismiss: {
                    viewModel.dismissCompletionModal()
                })
            }
            .task {
                await viewModel.loadAllOrders()
            }
        }
    }
}

// MARK: - Order Completion Modal
struct OrderCompletionModal: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Success Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
            }
            
            // Title
            Text("Great Job! 🎉")
                .font(.title)
                .fontWeight(.bold)
            
            // Message
            VStack(spacing: 8) {
                Text("Thanks for completing your work!")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("The order is ready for customer pickup.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            // Encouragement
            VStack(spacing: 4) {
                Text("Ready for the next order?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            // Button
            Button(action: onDismiss) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .interactiveDismissDisabled()
    }
}

// MARK: - Status Update Confirmation Modal
struct StatusUpdateConfirmationModal: View {
    let order: Order
    let newStatus: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var statusDisplayName: String {
        switch newStatus {
        case "pending": return "Pending"
        case "preparing": return "Preparing"
        case "ready": return "Ready"
        case "pickedup": return "Picked Up"
        case "completed": return "Completed"
        default: return newStatus.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    var statusColor: Color {
        switch newStatus {
        case "pending": return .orange
        case "preparing": return .yellow
        case "ready": return .blue
        case "pickedup": return .purple
        case "completed": return .green
        default: return .gray
        }
    }
    
    var statusIcon: String {
        switch newStatus {
        case "pending": return "clock.fill"
        case "preparing": return "flame.fill"
        case "ready": return "checkmark.circle.fill"
        case "pickedup": return "bag.fill"
        case "completed": return "checkmark.seal.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    var statusDescription: String {
        switch newStatus {
        case "preparing": return "Start preparing this order?"
        case "ready": return "Mark order as ready for pickup?"
        case "pickedup": return "Confirm customer picked up order?"
        case "completed": return "Mark order as completed?"
        default: return "Update the order status?"
        }
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Modal content
            VStack(spacing: 16) {
                // Status Icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: statusIcon)
                        .font(.system(size: 28))
                        .foregroundColor(statusColor)
                }
                
                // Title
                Text("Update Status")
                    .font(.headline)
                    .fontWeight(.bold)
                
                // Order Info
                Text("Order #\(String(order.id.prefix(8)).uppercased())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // New Status Badge
                Text(statusDisplayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(16)
                
                // Description
                Text(statusDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .cornerRadius(10)
                    }
                    
                    Button(action: onConfirm) {
                        Text("Confirm")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(statusColor)
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
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
    
    @State private var isExpanded = false
    
    var statusColor: Color {
        switch order.status {
        case "pending": return .orange
        case "preparing": return .yellow
        case "ready": return .blue
        case "pickedup": return .purple
        case "completed": return .green
        default: return .gray
        }
    }
    
    var displayStatus: String {
        switch order.status {
        case "pending": return "Pending"
        case "preparing": return "Preparing"
        case "ready": return "Ready"
        case "pickedup": return "Picked Up"
        case "completed": return "Completed"
        default: return order.status.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    var buttonColor: Color {
        switch order.status {
        case "pending": return .orange       // Start Preparing
        case "preparing": return .blue       // Order is Ready
        case "ready": return .purple         // Customer Picked Up
        case "pickedup": return .green      // Complete Order
        default: return .gray
        }
    }
    
    var buttonIcon: String {
        switch order.status {
        case "pending": return "flame.fill"
        case "preparing": return "checkmark.circle.fill"
        case "ready": return "bag.fill"
        case "pickedup": return "checkmark.seal.fill"
        default: return "checkmark"
        }
    }
    
    var buttonLabel: String {
        switch order.status {
        case "pending": return "Start Preparing"
        case "preparing": return "Order is Ready"
        case "ready": return "Customer Picked Up"
        case "pickedup": return "Complete Order"
        default: return ""
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
                
                // Status Badge (no dropdown menu, just display)
                Text(displayStatus)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(12)
            }
            
            // Customer Info (without email)
            if let customer = order.customer {
                HStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.primaryGreen)
                    
                    Text(customer.fullName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let phone = customer.phone, !phone.isEmpty {
                        Spacer()
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Scheduled Pickup Time
            if let pickupTime = order.pickupTime, !pickupTime.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption)
                        .foregroundColor(.purple)
                    Text("Pickup: \(formatPickupTime(pickupTime))")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .fontWeight(.medium)
                }
            }
            
            // Order Notes
            if let notes = order.notes, !notes.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Payment Status
            HStack(spacing: 6) {
                Image(systemName: "banknote.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                Text("Pay at Pickup")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }
            
            // Order Items - Always visible, tap to expand
            VStack(alignment: .leading, spacing: 8) {
                // Items header with tap to expand
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text("\((order.items ?? []).count) item\((order.items ?? []).count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(String(format: "$%.2f", order.totalAmount ?? 0))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Expanded items list
                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(order.items ?? [], id: \.id) { item in
                            HStack {
                                Text("\(item.quantity)x")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(width: 30, alignment: .leading)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.displayName)
                                        .font(.subheadline)
                                    
                                    if item.displayUnitPrice > 0 {
                                        Text("$\(item.displayUnitPrice, specifier: "%.2f") each")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(String(format: "$%.2f", item.totalPrice))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            if let instructions = item.specialInstructions, !instructions.isEmpty {
                                Text("Note: \(instructions)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.leading, 30)
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
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                }
            }
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            // Quick Action Button - Based on current status
            if let nextStatus = viewModel.getNextStatus(currentStatus: order.status) {
                Button {
                    onStatusUpdate(order.id, nextStatus)
                } label: {
                    HStack {
                        Image(systemName: buttonIcon)
                        Text(buttonLabel)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(buttonColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
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
    AdminOrdersView()
}
