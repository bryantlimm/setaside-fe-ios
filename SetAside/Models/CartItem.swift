//
//  CartItem.swift
//  SetAside
//

import Foundation

struct CartItem: Identifiable, Equatable {
    let id: UUID = UUID()
    let product: Product
    var quantity: Int
    var specialInstructions: String?
    
    var totalPrice: Double {
        product.price * Double(quantity)
    }
    
    static func == (lhs: CartItem, rhs: CartItem) -> Bool {
        lhs.product.id == rhs.product.id
    }
}
