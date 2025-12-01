//
//  Order.swift
//  SetAside
//

import Foundation

struct Order: Codable, Identifiable {
    let id: String
    let customerId: String?
    let status: String
    let notes: String?
    let pickupTime: String?
    let totalAmount: Double?
    let items: [OrderItem]?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case customerId = "customer_id"
        case status
        case notes
        case pickupTime = "pickup_time"
        case totalAmount = "total_amount"
        case items
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var statusEnum: AppConstants.OrderStatus {
        AppConstants.OrderStatus(rawValue: status) ?? .pending
    }
    
    var formattedDate: String {
        guard let createdAt = createdAt else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return createdAt
    }
}

struct OrderItem: Codable, Identifiable {
    let id: String
    let orderId: String?
    let productId: String
    let quantity: Int
    let unitPrice: Double?
    let specialInstructions: String?
    let product: Product?
    
    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case productId = "product_id"
        case quantity
        case unitPrice = "unit_price"
        case specialInstructions = "special_instructions"
        case product
    }
    
    var totalPrice: Double {
        (unitPrice ?? 0) * Double(quantity)
    }
}

struct OrdersResponse: Codable {
    let orders: [Order]?
    let items: [Order]?
    let total: Int?
    let page: Int?
    let limit: Int?
    
    var allOrders: [Order] {
        return orders ?? items ?? []
    }
}

struct CreateOrderRequest: Codable {
    let notes: String?
    let pickupTime: String?
    let items: [CreateOrderItemRequest]
    
    enum CodingKeys: String, CodingKey {
        case notes
        case pickupTime = "pickup_time"
        case items
    }
}

struct CreateOrderItemRequest: Codable {
    let productId: String
    let quantity: Int
    let specialInstructions: String?
    
    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case quantity
        case specialInstructions = "special_instructions"
    }
}

struct UpdateOrderRequest: Codable {
    let notes: String?
    let pickupTime: String?
    
    enum CodingKeys: String, CodingKey {
        case notes
        case pickupTime = "pickup_time"
    }
}

struct UpdateOrderStatusRequest: Codable {
    let status: String
}

struct AddOrderItemRequest: Codable {
    let productId: String
    let quantity: Int
    let specialInstructions: String?
    
    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case quantity
        case specialInstructions = "special_instructions"
    }
}

struct UpdateOrderItemRequest: Codable {
    let quantity: Int?
    let specialInstructions: String?
    
    enum CodingKeys: String, CodingKey {
        case quantity
        case specialInstructions = "special_instructions"
    }
}
