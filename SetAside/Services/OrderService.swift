//
//  OrderService.swift
//  SetAside
//

import Foundation

class OrderService {
    static let shared = OrderService()
    private let networkManager = NetworkManager.shared
    
    private init() {}
    
    /// Create a new order
    func createOrder(notes: String?, pickupTime: Date?, items: [CreateOrderItemRequest]) async throws -> Order {
        var pickupTimeString: String? = nil
        if let pickupTime = pickupTime {
            let formatter = ISO8601DateFormatter()
            pickupTimeString = formatter.string(from: pickupTime)
        }
        
        let request = CreateOrderRequest(
            notes: notes,
            pickupTime: pickupTimeString,
            items: items
        )
        
        return try await networkManager.request(
            endpoint: "/orders",
            method: "POST",
            body: request
        )
    }
    
    /// Get all orders for current user
    func getOrders(page: Int = 1, limit: Int = 20, status: String? = nil) async throws -> [Order] {
        var endpoint = "/orders?page=\(page)&limit=\(limit)"
        
        if let status = status {
            endpoint += "&status=\(status)"
        }
        
        let response: OrdersResponse = try await networkManager.request(
            endpoint: endpoint,
            method: "GET"
        )
        
        return response.allOrders
    }
    
    /// Get a specific order by ID
    func getOrder(id: String) async throws -> Order {
        return try await networkManager.request(
            endpoint: "/orders/\(id)",
            method: "GET"
        )
    }
    
    /// Update an order (notes or pickup time)
    func updateOrder(id: String, notes: String?, pickupTime: Date?) async throws -> Order {
        var pickupTimeString: String? = nil
        if let pickupTime = pickupTime {
            let formatter = ISO8601DateFormatter()
            pickupTimeString = formatter.string(from: pickupTime)
        }
        
        let request = UpdateOrderRequest(
            notes: notes,
            pickupTime: pickupTimeString
        )
        
        return try await networkManager.request(
            endpoint: "/orders/\(id)",
            method: "PATCH",
            body: request
        )
    }
    
    /// Update order status (Staff only)
    func updateOrderStatus(id: String, status: String) async throws -> Order {
        let request = UpdateOrderStatusRequest(status: status)
        
        return try await networkManager.request(
            endpoint: "/orders/\(id)/status",
            method: "PATCH",
            body: request
        )
    }
    
    /// Delete an order (only pending orders)
    func deleteOrder(id: String) async throws {
        try await networkManager.requestWithoutResponse(
            endpoint: "/orders/\(id)",
            method: "DELETE"
        )
    }
    
    /// Get items in an order
    func getOrderItems(orderId: String) async throws -> [OrderItem] {
        struct OrderItemsResponse: Codable {
            let items: [OrderItem]?
        }
        
        let response: OrderItemsResponse = try await networkManager.request(
            endpoint: "/orders/\(orderId)/items",
            method: "GET"
        )
        
        return response.items ?? []
    }
    
    /// Add item to an order
    func addItemToOrder(orderId: String, productId: String, quantity: Int, specialInstructions: String?) async throws -> OrderItem {
        let request = AddOrderItemRequest(
            productId: productId,
            quantity: quantity,
            specialInstructions: specialInstructions
        )
        
        return try await networkManager.request(
            endpoint: "/orders/\(orderId)/items",
            method: "POST",
            body: request
        )
    }
    
    /// Update an order item
    func updateOrderItem(orderId: String, itemId: String, quantity: Int?, specialInstructions: String?) async throws -> OrderItem {
        let request = UpdateOrderItemRequest(
            quantity: quantity,
            specialInstructions: specialInstructions
        )
        
        return try await networkManager.request(
            endpoint: "/orders/\(orderId)/items/\(itemId)",
            method: "PATCH",
            body: request
        )
    }
    
    /// Remove item from an order
    func removeItemFromOrder(orderId: String, itemId: String) async throws {
        try await networkManager.requestWithoutResponse(
            endpoint: "/orders/\(orderId)/items/\(itemId)",
            method: "DELETE"
        )
    }
}
