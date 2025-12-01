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
    
    let orderStatuses = ["pending", "preparing", "ready", "picked_up"]
    
    private let orderService = OrderService.shared
    
    var filteredOrders: [Order] {
        if selectedStatus == "all" {
            return orders
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
        orders.filter { $0.status == "picked_up" }
    }
    
    func loadAllOrders() async {
        isLoading = true
        errorMessage = nil
        
        do {
            orders = try await orderService.getAllOrders()
            // Sort by created date, newest first
            orders.sort { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
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
        case "pending": return "preparing"
        case "preparing": return "ready"
        case "ready": return "picked_up"
        default: return nil
        }
    }
    
    func statusColor(for status: String) -> String {
        switch status {
        case "pending": return "orange"
        case "preparing": return "blue"
        case "ready": return "green"
        case "picked_up": return "gray"
        default: return "gray"
        }
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
