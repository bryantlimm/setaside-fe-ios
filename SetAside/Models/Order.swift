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
    let customer: User?
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
        case customer
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        customerId = try container.decodeIfPresent(String.self, forKey: .customerId)
        status = try container.decode(String.self, forKey: .status)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        pickupTime = try container.decodeIfPresent(String.self, forKey: .pickupTime)
        totalAmount = try container.decodeIfPresent(Double.self, forKey: .totalAmount)
        customer = try container.decodeIfPresent(User.self, forKey: .customer)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        
        // Handle items - can be full OrderItem array or just count objects like [{"count": 0}]
        if let fullItems = try? container.decodeIfPresent([OrderItem].self, forKey: .items) {
            items = fullItems
        } else {
            // If decoding fails (e.g., items is [{"count": 0}]), set to empty array
            items = []
        }
    }
    
    init(id: String, customerId: String?, status: String, notes: String?, pickupTime: String?, totalAmount: Double?, items: [OrderItem]?, customer: User?, createdAt: String?, updatedAt: String?) {
        self.id = id
        self.customerId = customerId
        self.status = status
        self.notes = notes
        self.pickupTime = pickupTime
        self.totalAmount = totalAmount
        self.items = items
        self.customer = customer
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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
        
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
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
    let productId: String?
    let quantity: Int
    let unitPrice: Double?
    let subtotal: Double?
    let specialInstructions: String?
    let product: Product?
    
    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case productId = "product_id"
        case quantity
        case unitPrice = "unit_price"
        case subtotal
        case specialInstructions = "special_instructions"
        case product
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // ID might be missing in some responses, generate a UUID if needed
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        orderId = try? container.decodeIfPresent(String.self, forKey: .orderId)
        productId = try? container.decodeIfPresent(String.self, forKey: .productId)
        quantity = (try? container.decode(Int.self, forKey: .quantity)) ?? 1
        unitPrice = try? container.decodeIfPresent(Double.self, forKey: .unitPrice)
        subtotal = try? container.decodeIfPresent(Double.self, forKey: .subtotal)
        specialInstructions = try? container.decodeIfPresent(String.self, forKey: .specialInstructions)
        
        // Try to decode product with error logging
        do {
            product = try container.decodeIfPresent(Product.self, forKey: .product)
        } catch {
            #if DEBUG
            print("⚠️ Failed to decode product in OrderItem: \(error)")
            #endif
            product = nil
        }
        
        #if DEBUG
        print("📦 Decoded OrderItem: id=\(id), qty=\(quantity), unitPrice=\(unitPrice ?? 0), subtotal=\(subtotal ?? 0), product=\(product?.name ?? "nil")")
        #endif
    }
    
    init(id: String, orderId: String?, productId: String?, quantity: Int, unitPrice: Double?, subtotal: Double?, specialInstructions: String?, product: Product?) {
        self.id = id
        self.orderId = orderId
        self.productId = productId
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.subtotal = subtotal
        self.specialInstructions = specialInstructions
        self.product = product
    }
    
    var totalPrice: Double {
        // Use subtotal from API first (most reliable)
        if let subtotal = subtotal, subtotal > 0 {
            return subtotal
        }
        // Then try unit price * quantity
        if let unitPrice = unitPrice, unitPrice > 0 {
            return unitPrice * Double(quantity)
        }
        // Fall back to product price
        let price = product?.price ?? 0
        return price * Double(quantity)
    }
    
    /// Get the display name for this item
    var displayName: String {
        product?.name ?? "Product"
    }
    
    /// Get the unit price for display
    var displayUnitPrice: Double {
        unitPrice ?? product?.price ?? 0
    }
}

struct OrdersResponse: Codable {
    let data: [Order]?
    let orders: [Order]?
    let items: [Order]?
    let meta: OrdersMeta?
    let total: Int?
    let page: Int?
    let limit: Int?
    
    var allOrders: [Order] {
        return data ?? orders ?? items ?? []
    }
}

// Response wrapper for single order (create/update operations)
// API might return: {"order": {...}}, {"data": {...}}, or just {...}
struct SingleOrderResponse: Codable {
    let data: Order?
    let order: Order?
    let message: String?
    let id: String?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case data, order, message, id, status
    }
    
    // Try to get the order from wrapper
    var unwrappedOrder: Order? {
        if let order = data ?? order {
            return order
        }
        // If it has id and status at root level, it might be the order itself
        // This case is already handled by direct Order decoding
        return nil
    }
}

struct OrdersMeta: Codable {
    let total: Int?
    let page: Int?
    let limit: Int?
    let totalPages: Int?
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
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Only encode if not nil
        if let notes = notes {
            try container.encode(notes, forKey: .notes)
        }
        if let pickupTime = pickupTime {
            try container.encode(pickupTime, forKey: .pickupTime)
        }
        try container.encode(items, forKey: .items)
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
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(productId, forKey: .productId)
        try container.encode(quantity, forKey: .quantity)
        // Only encode if not nil
        if let specialInstructions = specialInstructions {
            try container.encode(specialInstructions, forKey: .specialInstructions)
        }
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
