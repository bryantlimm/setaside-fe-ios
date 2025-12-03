//
//  AdminProductListView.swift
//  SetAside
//

import SwiftUI

struct AdminProductListView: View {
    @StateObject private var viewModel = AdminProductViewModel()
    @State private var showAddProduct = false
    @State private var productToEdit: Product?
    @State private var productToDelete: Product?
    @State private var showDeleteConfirmation = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundGreen
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Inventory Management")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                            Text("Products & Stock")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Button {
                            showAddProduct = true
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.darkGreen)
                    
                    // Content
                    ZStack {
                        Color.backgroundGreen
                        
                        if viewModel.isLoading && viewModel.products.isEmpty {
                            ProgressView("Loading products...")
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text("Error loading products")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            Task {
                                await viewModel.loadProducts()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if viewModel.products.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cube.box")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No products yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Tap + to add your first product")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(viewModel.products) { product in
                            AdminProductRow(product: product)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    productToEdit = product
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        productToDelete = product
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        productToEdit = product
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.loadProducts()
                    }
                }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddProduct) {
                AddEditProductView(viewModel: viewModel, product: nil)
            }
            .sheet(item: $productToEdit) { product in
                AddEditProductView(viewModel: viewModel, product: product)
            }
            .alert("Delete Product", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let product = productToDelete {
                        Task {
                            let success = await viewModel.deleteProduct(id: product.id)
                            if success {
                                alertMessage = "Product deleted successfully"
                                isSuccess = true
                            } else {
                                alertMessage = viewModel.errorMessage ?? "Failed to delete product"
                                isSuccess = false
                            }
                            showAlert = true
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete \"\(productToDelete?.name ?? "")\"? This action cannot be undone.")
            }
            .alert(isSuccess ? "Success" : "Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .task {
                await viewModel.loadProducts()
                await viewModel.loadCategories()
            }
        }
    }
}

struct AdminProductRow: View {
    let product: Product
    
    var body: some View {
        HStack(spacing: 12) {
            // Product Image
            AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_):
                    ZStack {
                        Color.gray.opacity(0.1)
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.1)
                        ProgressView()
                    }
                @unknown default:
                    ZStack {
                        Color.gray.opacity(0.1)
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(width: 60, height: 60)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(product.category ?? "Uncategorized")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.primaryGreen)
                        .cornerRadius(4)
                    
                    // Availability Badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill((product.isAvailable ?? true) ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        Text((product.isAvailable ?? true) ? "Available" : "Unavailable")
                            .font(.caption2)
                            .foregroundColor((product.isAvailable ?? true) ? .green : .red)
                    }
                }
                
                HStack {
                    Text(String(format: "$%.2f", product.price))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryGreen)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "cube.box")
                            .font(.caption2)
                        Text("Stock: \(product.stockQuantity ?? 0)")
                            .font(.caption)
                    }
                    .foregroundColor((product.stockQuantity ?? 0) > 10 ? .primary : ((product.stockQuantity ?? 0) > 0 ? .orange : .red))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AdminProductListView()
}
