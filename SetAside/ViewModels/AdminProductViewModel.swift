//
//  AdminProductViewModel.swift
//  SetAside
//

import Foundation

@MainActor
class AdminProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var categories: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let productService = ProductService.shared
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            products = try await productService.getAllProductsAdmin()
            #if DEBUG
            print("✅ Loaded \(products.count) products")
            #endif
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ API Error loading products: \(error.localizedDescription)")
            #endif
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ Error loading products: \(error.localizedDescription)")
            #endif
        }
        
        isLoading = false
    }
    
    func loadCategories() async {
        do {
            categories = try await productService.getCategories()
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func createProduct(
        name: String,
        description: String,
        price: Double,
        stockQuantity: Int,
        category: String,
        isAvailable: Bool,
        imageUrl: String?
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let request = CreateProductRequest(
                name: name,
                description: description,
                price: price,
                category: category,
                isAvailable: isAvailable,
                stockQuantity: stockQuantity,
                imageUrl: imageUrl
            )
            
            let _ = try await productService.createProduct(request: request)
            
            successMessage = "Product created successfully"
            await loadProducts()
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
    
    func updateProduct(
        id: String,
        name: String,
        description: String,
        price: Double,
        stockQuantity: Int,
        category: String,
        isAvailable: Bool,
        imageUrl: String?
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let request = CreateProductRequest(
                name: name,
                description: description,
                price: price,
                category: category,
                isAvailable: isAvailable,
                stockQuantity: stockQuantity,
                imageUrl: imageUrl
            )
            
            let _ = try await productService.updateProduct(id: id, request: request)
            
            successMessage = "Product updated successfully"
            await loadProducts()
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
    
    func deleteProduct(id: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await productService.deleteProduct(id: id)
            successMessage = "Product deleted successfully"
            await loadProducts()
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
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
