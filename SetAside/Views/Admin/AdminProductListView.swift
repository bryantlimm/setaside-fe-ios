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
            .navigationTitle("Products")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddProduct = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
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
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                case .empty:
                    ProgressView()
                @unknown default:
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 60, height: 60)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(product.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                
                HStack {
                    Text(String(format: "$%.2f", product.price))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Text("Stock: \(product.stockQuantity ?? 0)")
                        .font(.caption)
                        .foregroundColor((product.stockQuantity ?? 0) > 0 ? .primary : .red)
                }
            }
            
            Spacer()
            
            // Availability indicator
            Circle()
                .fill(product.isAvailable ? Color.green : Color.red)
                .frame(width: 12, height: 12)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AdminProductListView()
}
