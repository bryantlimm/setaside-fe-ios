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
    let category: String?
    let isAvailable: Bool?
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = (try? container.decode(String.self, forKey: .name)) ?? "Unknown Product"
        description = try container.decodeIfPresent(String.self, forKey: .description)
        price = (try? container.decode(Double.self, forKey: .price)) ?? 0.0
        category = try container.decodeIfPresent(String.self, forKey: .category)
        isAvailable = try container.decodeIfPresent(Bool.self, forKey: .isAvailable)
        stockQuantity = try container.decodeIfPresent(Int.self, forKey: .stockQuantity)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        
        #if DEBUG
        print("📦 Decoded Product: id=\(id), name=\(name), price=\(price)")
        #endif
    }
    
    init(id: String, name: String, description: String?, price: Double, category: String?, isAvailable: Bool?, stockQuantity: Int?, imageUrl: String?, createdAt: String?, updatedAt: String?) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.category = category
        self.isAvailable = isAvailable
        self.stockQuantity = stockQuantity
        self.imageUrl = imageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        lhs.id == rhs.id
    }
}

struct ProductsResponse: Codable {
    let data: [Product]?
    let products: [Product]?
    let items: [Product]?
    let meta: ProductsMeta?
    let total: Int?
    let page: Int?
    let limit: Int?
    let totalPages: Int?
    
    enum CodingKeys: String, CodingKey {
        case data
        case products
        case items
        case meta
        case total
        case page
        case limit
        case totalPages = "total_pages"
    }
    
    var allProducts: [Product] {
        return data ?? products ?? items ?? []
    }
}

struct ProductsMeta: Codable {
    let total: Int?
    let page: Int?
    let limit: Int?
    let totalPages: Int?
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
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case price
        case category
        case isAvailable = "is_available"
        case stockQuantity = "stock_quantity"
        case imageUrl = "image_url"
    }
}
