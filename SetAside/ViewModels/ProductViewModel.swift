//
//  ProductViewModel.swift
//  SetAside
//

import Foundation
import SwiftUI

@MainActor
class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var categories: [String] = []
    @Published var selectedCategory: String?
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    private let productService = ProductService.shared
    private var currentPage = 1
    private var hasMoreProducts = true
    
    init() {
        Task {
            await loadInitialData()
        }
    }
    
    func loadInitialData() async {
        await fetchCategories()
        await fetchProducts(refresh: true)
    }
    
    func fetchProducts(refresh: Bool = false) async {
        guard !isLoading else { return }
        
        if refresh {
            currentPage = 1
            hasMoreProducts = true
        }
        
        guard hasMoreProducts else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedProducts = try await productService.getProducts(
                page: currentPage,
                limit: 20,
                category: selectedCategory,
                isAvailable: true,
                search: searchText.isEmpty ? nil : searchText
            )
            
            #if DEBUG
            print("✅ Fetched \(fetchedProducts.count) products for page \(currentPage)")
            #endif
            
            if refresh {
                products = fetchedProducts
            } else {
                products.append(contentsOf: fetchedProducts)
            }
            
            hasMoreProducts = fetchedProducts.count == 20
            currentPage += 1
            
        } catch let error as APIError {
            errorMessage = error.errorDescription
            showError = true
            #if DEBUG
            print("❌ API Error fetching products: \(error.errorDescription ?? "unknown")")
            #endif
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            #if DEBUG
            print("❌ Error fetching products: \(error.localizedDescription)")
            #endif
        }
        
        isLoading = false
    }
    
    func fetchCategories() async {
        do {
            categories = try await productService.getCategories()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func selectCategory(_ category: String?) {
        selectedCategory = category
        Task {
            await fetchProducts(refresh: true)
        }
    }
    
    func search() {
        Task {
            await fetchProducts(refresh: true)
        }
    }
    
    func loadMoreIfNeeded(currentProduct: Product) {
        guard let lastProduct = products.last else { return }
        
        if currentProduct.id == lastProduct.id {
            Task {
                await fetchProducts()
            }
        }
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
}
