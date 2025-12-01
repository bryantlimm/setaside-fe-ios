//
//  Product.swift
//  SetAside
//

import Foundation

struct Product: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let price: Double
    let category: String
    let isAvailable: Bool
    let stockQuantity: Int?
    let imageUrl: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case price
        case category
        case isAvailable = "is_available"
        case stockQuantity = "stock_quantity"
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        lhs.id == rhs.id
    }
}

struct ProductsResponse: Codable {
    let products: [Product]?
    let items: [Product]?
    let total: Int?
    let page: Int?
    let limit: Int?
    let totalPages: Int?
    
    enum CodingKeys: String, CodingKey {
        case products
        case items
        case total
        case page
        case limit
        case totalPages = "total_pages"
    }
    
    var allProducts: [Product] {
        return products ?? items ?? []
    }
}

struct CategoriesResponse: Codable {
    let categories: [String]?
    
    var allCategories: [String] {
        return categories ?? []
    }
}

struct CreateProductRequest: Codable {
    let name: String
    let description: String?
    let price: Double
    let category: String
    let isAvailable: Bool
    let stockQuantity: Int?
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case price
        case category
        case isAvailable = "is_available"
        case stockQuantity = "stock_quantity"
    }
}
