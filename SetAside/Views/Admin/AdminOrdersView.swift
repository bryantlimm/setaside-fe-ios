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
    @State private var showPaymentReceipt = false
    @State private var orderForReceipt: Order?
    
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
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Orders")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("\(viewModel.orders.count) total orders")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                        
                        // Refresh button
                        Button {
                            Task { await viewModel.loadAllOrders() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.body)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.primaryGreen)
                    
                    // Stats Cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            OrderStatCard(
                                title: "Pending",
                                count: viewModel.pendingOrders.count,
                                icon: "clock.fill",
                                color: .orange,
                                isSelected: viewModel.selectedStatus == "pending"
                            ) {
                                viewModel.selectedStatus = "pending"
                            }
                            
                            OrderStatCard(
                                title: "Preparing",
                                count: viewModel.preparingOrders.count,
                                icon: "flame.fill",
                                color: .blue,
                                isSelected: viewModel.selectedStatus == "preparing"
                            ) {
                                viewModel.selectedStatus = "preparing"
                            }
                            
                            OrderStatCard(
                                title: "Ready",
                                count: viewModel.readyOrders.count,
                                icon: "checkmark.circle.fill",
                                color: .green,
                                isSelected: viewModel.selectedStatus == "ready"
                            ) {
                                viewModel.selectedStatus = "ready"
                            }
                            
                            OrderStatCard(
                                title: "Picked Up",
                                count: viewModel.pickedUpOrders.count,
                                icon: "bag.fill",
                                color: .purple,
                                isSelected: viewModel.selectedStatus == "pickedup"
                            ) {
                                viewModel.selectedStatus = "pickedup"
                            }
                            
                            OrderStatCard(
                                title: "Completed",
                                count: viewModel.completedOrders.count,
                                icon: "checkmark.seal.fill",
                                color: .gray,
                                isSelected: viewModel.selectedStatus == "completed"
                            ) {
                                viewModel.selectedStatus = "completed"
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color(.systemBackground))
                    
                    // Search & Filter Bar
                    HStack(spacing: 12) {
                        // Search
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                            
                            TextField("Search orders...", text: $searchText)
                                .font(.subheadline)
                            
                            if !searchText.isEmpty {
                                Button { searchText = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        
                        // All Orders Button
                        Button {
                            viewModel.selectedStatus = "all"
                        } label: {
                            Text("All")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(viewModel.selectedStatus == "all" ? .white : .primaryGreen)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(viewModel.selectedStatus == "all" ? Color.primaryGreen : Color(.systemBackground))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemGroupedBackground))
                    
                    // Orders List
                    if viewModel.isLoading && viewModel.orders.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading orders...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else if searchedOrders.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "tray")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No orders found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text(searchText.isEmpty ? "Orders will appear here" : "Try different search terms")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(searchedOrders) { order in
                                    OrderCard(order: order, viewModel: viewModel) { orderId, newStatus in
                                        pendingStatusUpdate = (orderId, newStatus, order)
                                        showStatusConfirmation = true
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .refreshable {
                            await viewModel.loadAllOrders()
                        }
                    }
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
                                    // Show payment receipt when order is completed
                                    if update.newStatus == "completed" {
                                        orderForReceipt = update.order
                                        showPaymentReceipt = true
                                    } else {
                                        alertMessage = "Order status updated to \(update.newStatus.replacingOccurrences(of: "_", with: " "))"
                                        isSuccess = true
                                        showAlert = true
                                    }
                                } else {
                                    alertMessage = viewModel.errorMessage ?? "Failed to update order status"
                                    isSuccess = false
                                    showAlert = true
                                }
                                pendingStatusUpdate = nil
                            }
                        },
                        onCancel: {
                            showStatusConfirmation = false
                            pendingStatusUpdate = nil
                        }
                    )
                }
                
                if showPaymentReceipt, let order = orderForReceipt {
                    PaymentReceiptModal(
                        order: order,
                        onPaymentSelected: { paymentMethod in
                            showPaymentReceipt = false
                            orderForReceipt = nil
                            alertMessage = "Payment method: \(paymentMethod). Order picked up successfully!"
                            isSuccess = true
                            showAlert = true
                        },
                        onDismiss: {
                            showPaymentReceipt = false
                            orderForReceipt = nil
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

// MARK: - Payment Receipt Modal
struct PaymentReceiptModal: View {
    let order: Order
    let onPaymentSelected: (String) -> Void
    let onDismiss: () -> Void
    
    @State private var selectedPaymentMethod: String? = nil
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            // Receipt Card
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Decorative top edge (receipt style)
                    ZigZagEdge()
                        .fill(Color(.systemBackground))
                        .frame(height: 12)
                    
                    VStack(spacing: 0) {
                        // Store Header
                        VStack(spacing: 6) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.primaryGreen)
                            
                            Text("SetAside")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Fresh Groceries")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                        
                        // Dashed Divider
                        DashedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundColor(.gray.opacity(0.4))
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                        
                        // Order Info
                        VStack(spacing: 4) {
                            Text("Order #\(String(order.id.prefix(8)).uppercased())")
                                .font(.footnote)
                                .fontWeight(.semibold)
                            
                            Text(formattedDate)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            if let customer = order.customer {
                                Text(customer.fullName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 12)
                        
                        // Dashed Divider
                        DashedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundColor(.gray.opacity(0.4))
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                        
                        // Order Items
                        VStack(spacing: 6) {
                            ForEach(order.items ?? [], id: \.id) { item in
                                HStack(alignment: .top) {
                                    Text("\(item.quantity)x")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 24, alignment: .leading)
                                    
                                    Text(item.displayName)
                                        .font(.caption)
                                        .lineLimit(2)
                                    
                                    Spacer()
                                    
                                    Text(String(format: "$%.2f", item.totalPrice))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        
                        // Dashed Divider
                        DashedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundColor(.gray.opacity(0.4))
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                        
                        // Total
                        HStack {
                            Text("TOTAL")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Spacer()
                            Text(String(format: "$%.2f", order.totalAmount ?? 0))
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        
                        // Dashed Divider
                        DashedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundColor(.gray.opacity(0.4))
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                        
                        // Payment Method Selection
                        VStack(spacing: 10) {
                            Text("SELECT PAYMENT METHOD")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.top, 12)
                            
                            HStack(spacing: 10) {
                                PaymentOption(
                                    icon: "banknote.fill",
                                    label: "Cash",
                                    color: .green,
                                    isSelected: selectedPaymentMethod == "Cash"
                                ) {
                                    selectedPaymentMethod = "Cash"
                                }
                                
                                PaymentOption(
                                    icon: "qrcode",
                                    label: "QRIS",
                                    color: .blue,
                                    isSelected: selectedPaymentMethod == "QRIS"
                                ) {
                                    selectedPaymentMethod = "QRIS"
                                }
                                
                                PaymentOption(
                                    icon: "creditcard.fill",
                                    label: "Card",
                                    color: .purple,
                                    isSelected: selectedPaymentMethod == "Card"
                                ) {
                                    selectedPaymentMethod = "Card"
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            // QRIS QR Code
                            if selectedPaymentMethod == "QRIS" {
                                VStack(spacing: 8) {
                                    Text("Scan to Pay")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                    
                                    // QRIS Image from Assets
                                    Image("qris")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 140, height: 140)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                                        )
                                    
                                    Text("SetAside Payment")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.05))
                                .cornerRadius(12)
                                .padding(.horizontal, 16)
                            }
                            
                            // Card EDC Message
                            if selectedPaymentMethod == "Card" {
                                VStack(spacing: 8) {
                                    Image(systemName: "creditcard.and.123")
                                        .font(.system(size: 32))
                                        .foregroundColor(.purple)
                                    
                                    Text("Continue to EDC Machine")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.purple)
                                    
                                    Text("Please process the card payment\nusing the EDC terminal")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(Color.purple.opacity(0.05))
                                .cornerRadius(12)
                                .padding(.horizontal, 16)
                            }
                            
                            // Cash Message
                            if selectedPaymentMethod == "Cash" {
                                VStack(spacing: 8) {
                                    Image(systemName: "banknote.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.green)
                                    
                                    Text("Cash Payment")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                    
                                    Text("Collect \(String(format: "$%.2f", order.totalAmount ?? 0)) from customer")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(Color.green.opacity(0.05))
                                .cornerRadius(12)
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 16)
                        
                        // Confirm Button
                        Button {
                            if let method = selectedPaymentMethod {
                                onPaymentSelected(method)
                            }
                        } label: {
                            Text(selectedPaymentMethod != nil ? "Confirm \(selectedPaymentMethod!) Payment" : "Select Payment Method")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedPaymentMethod != nil ? Color.primaryGreen : Color.gray)
                                .cornerRadius(8)
                        }
                        .disabled(selectedPaymentMethod == nil)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        
                        // Cancel Button
                        Button {
                            onDismiss()
                        } label: {
                            Text("Cancel")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 16)
                        
                        // Thank you message
                        Text("Thank you for your order!")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 12)
                    }
                    .background(Color(.systemBackground))
                    
                    // Decorative bottom edge (receipt style)
                    ZigZagEdge()
                        .fill(Color(.systemBackground))
                        .frame(height: 12)
                        .rotationEffect(.degrees(180))
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 60)
        }
    }
}

// MARK: - Payment Option Button
struct PaymentOption: View {
    let icon: String
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? color.opacity(0.15) : Color(.systemGray6))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? color : .gray)
                }
                
                Text(label)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? color : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? color.opacity(0.08) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Dashed Line Shape
struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

// MARK: - ZigZag Edge Shape (Receipt Style)
struct ZigZagEdge: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let zigzagHeight: CGFloat = rect.height
        let zigzagWidth: CGFloat = 10
        let numberOfZigzags = Int(rect.width / zigzagWidth)
        
        path.move(to: CGPoint(x: 0, y: zigzagHeight))
        
        for i in 0..<numberOfZigzags {
            let x = CGFloat(i) * zigzagWidth
            let point1 = CGPoint(x: x + zigzagWidth / 2, y: 0)
            let point2 = CGPoint(x: x + zigzagWidth, y: zigzagHeight)
            path.addLine(to: point1)
            path.addLine(to: point2)
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: zigzagHeight))
        path.closeSubpath()
        
        return path
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

// MARK: - Order Stat Card
struct OrderStatCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color)
                    
                    Text("\(count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80)
            .padding(.vertical, 12)
            .background(isSelected ? color.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Order Card (Professional ERP Style)
struct OrderCard: View {
    let order: Order
    @ObservedObject var viewModel: AdminOrderViewModel
    let onStatusUpdate: (String, String) -> Void
    
    @State private var isExpanded = false
    
    var statusColor: Color {
        switch order.status {
        case "pending": return .orange
        case "preparing": return .blue
        case "ready": return .green
        case "pickedup": return .purple
        case "completed": return .gray
        default: return .gray
        }
    }
    
    var statusIcon: String {
        switch order.status {
        case "pending": return "clock.fill"
        case "preparing": return "flame.fill"
        case "ready": return "checkmark.circle.fill"
        case "pickedup": return "bag.fill"
        case "completed": return "checkmark.seal.fill"
        default: return "circle"
        }
    }
    
    var displayStatus: String {
        switch order.status {
        case "pending": return "Pending"
        case "preparing": return "Preparing"
        case "ready": return "Ready"
        case "pickedup": return "Picked Up"
        case "completed": return "Completed"
        default: return order.status.capitalized
        }
    }
    
    var actionButtonConfig: (label: String, icon: String, color: Color)? {
        switch order.status {
        case "pending": return ("Start Preparing", "flame.fill", .orange)
        case "preparing": return ("Mark Ready", "checkmark.circle.fill", .blue)
        case "ready": return ("Picked Up", "bag.fill", .green)
        case "pickedup": return ("Complete", "checkmark.seal.fill", .purple)
        default: return nil
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Card Content
            VStack(spacing: 12) {
                // Header Row
                HStack(alignment: .top) {
                    // Order Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("#\(String(order.id.prefix(8)).uppercased())")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            // Status Badge
                            HStack(spacing: 4) {
                                Image(systemName: statusIcon)
                                    .font(.caption2)
                                Text(displayStatus)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.12))
                            .cornerRadius(6)
                        }
                        
                        if let createdAt = order.createdAt {
                            Text(formatDate(createdAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Total Amount
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "$%.2f", order.totalAmount ?? 0))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryGreen)
                        
                        Text("\((order.items ?? []).count) items")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Customer Row
                if let customer = order.customer {
                    HStack(spacing: 10) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color.primaryGreen.opacity(0.15))
                                .frame(width: 36, height: 36)
                            
                            Text(String(customer.fullName.prefix(1)).uppercased())
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primaryGreen)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(customer.fullName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if let phone = customer.phone, !phone.isEmpty {
                                Text(phone)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Pickup Time
                        if let pickupTime = order.pickupTime, !pickupTime.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text(formatPickupTime(pickupTime))
                                    .font(.caption)
                            }
                            .foregroundColor(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
                
                // Expandable Items Section
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text("Order Details")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
                
                if isExpanded {
                    VStack(spacing: 8) {
                        // Items List
                        ForEach(order.items ?? [], id: \.id) { item in
                            HStack(spacing: 8) {
                                Text("\(item.quantity)×")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 24, alignment: .leading)
                                
                                Text(item.displayName)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(String(format: "$%.2f", item.totalPrice))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Divider()
                        
                        // Notes
                        if let notes = order.notes, !notes.isEmpty {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "note.text")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text(notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(8)
                            .background(Color.orange.opacity(0.08))
                            .cornerRadius(6)
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
            .padding(14)
            
            // Action Button
            if let config = actionButtonConfig,
               let nextStatus = viewModel.getNextStatus(currentStatus: order.status) {
                Button {
                    onStatusUpdate(order.id, nextStatus)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: config.icon)
                            .font(.caption)
                        Text(config.label)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(config.color)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    private func formatDate(_ dateString: String) -> String {
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
    
    private func formatPickupTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "h:mm a"
            return displayFormatter.string(from: date)
        }
        
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "h:mm a"
            return displayFormatter.string(from: date)
        }
        
        return dateString
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
