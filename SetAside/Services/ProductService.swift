//
//  ProductService.swift
//  SetAside
//

import Foundation

class ProductService {
    static let shared = ProductService()
    private let networkManager = NetworkManager.shared
    
    private init() {}
    
    /// Get all products with optional filters
    func getProducts(
        page: Int = 1,
        limit: Int = 20,
        category: String? = nil,
        isAvailable: Bool? = nil,
        search: String? = nil
    ) async throws -> [Product] {
        var endpoint = "/products?page=\(page)&limit=\(limit)"
        
        if let category = category {
            endpoint += "&category=\(category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? category)"
        }
        if let isAvailable = isAvailable {
            endpoint += "&is_available=\(isAvailable)"
        }
        if let search = search, !search.isEmpty {
            endpoint += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? search)"
        }
        
        let response: ProductsResponse = try await networkManager.request(
            endpoint: endpoint,
            method: "GET",
            requiresAuth: false
        )
        
        return response.allProducts
    }
    
    /// Get all products for admin (include all regardless of availability)
    func getAllProductsAdmin(page: Int = 1, limit: Int = 100) async throws -> [Product] {
        let endpoint = "/products?page=\(page)&limit=\(limit)"
        
        let response: ProductsResponse = try await networkManager.request(
            endpoint: endpoint,
            method: "GET",
            requiresAuth: true
        )
        
        return response.allProducts
    }
    
    /// Get all product categories
    func getCategories() async throws -> [String] {
        // API returns plain array of strings
        let categories: [String] = try await networkManager.request(
            endpoint: "/products/categories",
            method: "GET",
            requiresAuth: false
        )
        
        return categories
    }
    
    /// Get a specific product by ID
    func getProduct(id: String) async throws -> Product {
        return try await networkManager.request(
            endpoint: "/products/\(id)",
            method: "GET",
            requiresAuth: false
        )
    }
    
    /// Create a new product (Staff only)
    func createProduct(request: CreateProductRequest) async throws -> Product {
        return try await networkManager.request(
            endpoint: "/products",
            method: "POST",
            body: request
        )
    }
    
    /// Update a product (Staff only)
    func updateProduct(id: String, request: CreateProductRequest) async throws -> Product {
        return try await networkManager.request(
            endpoint: "/products/\(id)",
            method: "PATCH",
            body: request
        )
    }
    
    /// Delete a product (Staff only)
    func deleteProduct(id: String) async throws {
        try await networkManager.requestWithoutResponse(
            endpoint: "/products/\(id)",
            method: "DELETE"
        )
    }
}
