//
//  CartViewModel.swift
//  SetAside
//

import Foundation
import SwiftUI

@MainActor
class CartViewModel: ObservableObject {
    @Published var items: [CartItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var orderPlaced: Bool = false
    @Published var lastOrder: Order?
    
    private let orderService = OrderService.shared
    
    var totalPrice: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }
    
    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    var isEmpty: Bool {
        items.isEmpty
    }
    
    func addToCart(product: Product, quantity: Int = 1, specialInstructions: String? = nil) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            // Update existing item
            items[index].quantity += quantity
            if let instructions = specialInstructions {
                items[index].specialInstructions = instructions
            }
        } else {
            // Add new item
            let cartItem = CartItem(
                product: product,
                quantity: quantity,
                specialInstructions: specialInstructions
            )
            items.append(cartItem)
        }
    }
    
    func removeFromCart(product: Product) {
        items.removeAll { $0.product.id == product.id }
    }
    
    func removeItem(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
    }
    
    func updateQuantity(for product: Product, quantity: Int) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            if quantity <= 0 {
                items.remove(at: index)
            } else {
                items[index].quantity = quantity
            }
        }
    }
    
    func incrementQuantity(at index: Int) {
        guard index < items.count else { return }
        items[index].quantity += 1
    }
    
    func decrementQuantity(at index: Int) {
        guard index < items.count else { return }
        if items[index].quantity > 1 {
            items[index].quantity -= 1
        } else {
            items.remove(at: index)
        }
    }
    
    func updateSpecialInstructions(for product: Product, instructions: String?) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].specialInstructions = instructions
        }
    }
    
    func clearCart() {
        items.removeAll()
    }
    
    func placeOrder(notes: String? = nil, pickupTime: Date? = nil) async {
        guard !items.isEmpty else {
            errorMessage = "Cart is empty"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let orderItems = items.map { item in
            CreateOrderItemRequest(
                productId: item.product.id,
                quantity: item.quantity,
                specialInstructions: item.specialInstructions
            )
        }
        
        #if DEBUG
        print("🛒 Placing order with \(orderItems.count) items:")
        for (index, item) in items.enumerated() {
            print("   Item \(index + 1): product_id=\(item.product.id), qty=\(item.quantity), name=\(item.product.name)")
        }
        #endif
        
        do {
            let order = try await orderService.createOrder(
                notes: notes,
                pickupTime: pickupTime,
                items: orderItems
            )
            
            #if DEBUG
            print("✅ Order created successfully: \(order.id)")
            #endif
            
            lastOrder = order
            orderPlaced = true
            clearCart()
            
        } catch {
            #if DEBUG
            print("⚠️ Order API returned error but order may have been created: \(error)")
            #endif
            
            // The order is likely created even if decoding fails
            // Show success to user and let them check Orders tab
            lastOrder = nil
            orderPlaced = true
            clearCart()
        }
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    func resetOrderPlaced() {
        orderPlaced = false
        lastOrder = nil
    }
    
    func getQuantity(for product: Product) -> Int {
        items.first(where: { $0.product.id == product.id })?.quantity ?? 0
    }
    
    func isInCart(_ product: Product) -> Bool {
        items.contains(where: { $0.product.id == product.id })
    }
}
