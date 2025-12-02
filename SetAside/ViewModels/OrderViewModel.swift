//
//  OrderViewModel.swift
//  SetAside
//

import Foundation
import SwiftUI

@MainActor
class OrderViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var selectedOrder: Order?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var selectedStatus: String?
    
    private let orderService = OrderService.shared
    private var currentPage = 1
    private var hasMoreOrders = true
    
    init() {
        Task {
            await fetchOrders(refresh: true)
        }
    }
    
    func fetchOrders(refresh: Bool = false) async {
        guard !isLoading else { return }
        
        if refresh {
            currentPage = 1
            hasMoreOrders = true
        }
        
        guard hasMoreOrders else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // The list API now returns items and total_amount directly
            let fetchedOrders = try await orderService.getOrders(
                page: currentPage,
                limit: 20,
                status: selectedStatus
            )
            
            #if DEBUG
            print("📋 Fetched \(fetchedOrders.count) orders")
            for order in fetchedOrders {
                print("📦 Order \(order.id.prefix(8)): \(order.items?.count ?? 0) items, total: $\(order.totalAmount ?? 0)")
            }
            #endif
            
            if refresh {
                orders = fetchedOrders
            } else {
                orders.append(contentsOf: fetchedOrders)
            }
            
            hasMoreOrders = fetchedOrders.count == 20
            currentPage += 1
            
        } catch let error as APIError {
            errorMessage = error.errorDescription
            showError = true
            #if DEBUG
            print("❌ Failed to fetch orders: \(error)")
            #endif
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            #if DEBUG
            print("❌ Failed to fetch orders: \(error)")
            #endif
        }
        
        isLoading = false
    }
    
    func fetchOrderDetails(orderId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            selectedOrder = try await orderService.getOrder(id: orderId)
        } catch let error as APIError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func filterByStatus(_ status: String?) {
        selectedStatus = status
        Task {
            await fetchOrders(refresh: true)
        }
    }
    
    func cancelOrder(orderId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await orderService.deleteOrder(id: orderId)
            orders.removeAll { $0.id == orderId }
            if selectedOrder?.id == orderId {
                selectedOrder = nil
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func updateOrder(orderId: String, notes: String?, pickupTime: Date?) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedOrder = try await orderService.updateOrder(
                id: orderId,
                notes: notes,
                pickupTime: pickupTime
            )
            
            if let index = orders.firstIndex(where: { $0.id == orderId }) {
                orders[index] = updatedOrder
            }
            
            if selectedOrder?.id == orderId {
                selectedOrder = updatedOrder
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func loadMoreIfNeeded(currentOrder: Order) {
        guard let lastOrder = orders.last else { return }
        
        if currentOrder.id == lastOrder.id {
            Task {
                await fetchOrders()
            }
        }
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    // Computed properties for order statistics
    var pendingOrders: [Order] {
        orders.filter { $0.status == "pending" }
    }
    
    var preparingOrders: [Order] {
        orders.filter { $0.status == "preparing" }
    }
    
    var readyOrders: [Order] {
        orders.filter { $0.status == "ready" }
    }
    
    var completedOrders: [Order] {
        orders.filter { $0.status == "pickedup" }
    }
    
    var activeOrders: [Order] {
        orders.filter { $0.status != "pickedup" }
    }
}
