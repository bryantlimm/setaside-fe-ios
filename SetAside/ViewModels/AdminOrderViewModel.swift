//
//  AdminOrderViewModel.swift
//  SetAside
//

import Foundation

@MainActor
class AdminOrderViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var selectedStatus: String = "all"
    @Published var showCompletionModal = false
    @Published var completedOrderId: String?
    
    // Full 5-stage flow: pending -> preparing -> ready -> pickedup -> completed
    let orderStatuses = ["pending", "preparing", "ready", "pickedup", "completed"]
    
    private let orderService = OrderService.shared
    
    var filteredOrders: [Order] {
        if selectedStatus == "all" {
            // Show only active orders (not completed) in "Active" tab
            return orders.filter { $0.status != "completed" }
        }
        if selectedStatus == "completed" {
            return orders.filter { $0.status == "completed" }
        }
        return orders.filter { $0.status == selectedStatus }
    }
    
    var pendingOrders: [Order] {
        orders.filter { $0.status == "pending" }
    }
    
    var preparingOrders: [Order] {
        orders.filter { $0.status == "preparing" }
    }
    
    var readyOrders: [Order] {
        orders.filter { $0.status == "ready" }
    }
    
    var pickedUpOrders: [Order] {
        orders.filter { $0.status == "pickedup" }
    }
    
    var completedOrders: [Order] {
        orders.filter { $0.status == "completed" }
    }
    
    func loadAllOrders() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // The list API now returns items and total_amount directly
            orders = try await orderService.getAllOrders()
            
            #if DEBUG
            print("📋 Loaded \(orders.count) orders")
            for order in orders {
                print("📦 Order \(order.id.prefix(8)): \(order.items?.count ?? 0) items, total: $\(order.totalAmount ?? 0)")
                if let items = order.items {
                    for item in items {
                        print("   - \(item.quantity)x \(item.product?.name ?? "Unknown") = $\(item.totalPrice)")
                    }
                }
            }
            #endif
            
            // Sort by created date, newest first
            orders.sort { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
            
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ Failed to load orders: \(error)")
            #endif
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ Failed to load orders: \(error)")
            #endif
        }
        
        isLoading = false
    }
    
    func updateOrderStatus(orderId: String, newStatus: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let _ = try await orderService.updateOrderStatus(id: orderId, status: newStatus)
            successMessage = "Order status updated to \(newStatus)"
            await loadAllOrders()
            isLoading = false
            return true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func getNextStatus(currentStatus: String) -> String? {
        switch currentStatus {
        case "pending": return "preparing"      // Start Preparing
        case "preparing": return "ready"        // Order is Ready
        case "ready": return "pickedup"        // Customer Picked Up
        case "pickedup": return "completed"    // Complete Order
        default: return nil                      // completed is final
        }
    }
    
    func getButtonLabel(for status: String) -> String {
        switch status {
        case "pending": return "Start Preparing"
        case "preparing": return "Order is Ready"
        case "ready": return "Customer Picked Up"
        case "pickedup": return "Complete Order"
        default: return ""
        }
    }
    
    func getButtonIcon(for status: String) -> String {
        switch status {
        case "pending": return "flame.fill"
        case "preparing": return "checkmark.circle.fill"
        case "ready": return "bag.fill"
        case "pickedup": return "checkmark.seal.fill"
        default: return "checkmark"
        }
    }
    
    func getButtonColor(for status: String) -> String {
        switch status {
        case "pending": return "orange"        // Start preparing - orange
        case "preparing": return "blue"        // Mark ready - blue  
        case "ready": return "purple"          // Picked up - purple
        case "pickedup": return "green"       // Complete - green
        default: return "gray"
        }
    }
    
    func statusColor(for status: String) -> String {
        switch status {
        case "pending": return "orange"
        case "preparing": return "blue"
        case "ready": return "green"
        default: return "gray"
        }
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    /// Mark order as completed and show completion modal
    func markOrderCompleted(orderId: String) async -> Bool {
        isLoading = true
        
        do {
            let _ = try await orderService.updateOrderStatus(id: orderId, status: "completed")
            completedOrderId = orderId
            showCompletionModal = true
            await loadAllOrders()
            isLoading = false
            #if DEBUG
            print("✅ Order \(orderId.prefix(8)) marked as completed")
            #endif
            return true
        } catch {
            #if DEBUG
            print("⚠️ Failed to update order status: \(error)")
            #endif
            errorMessage = "Failed to complete order"
            isLoading = false
            return false
        }
    }
    
    func dismissCompletionModal() {
        showCompletionModal = false
        completedOrderId = nil
    }
}
