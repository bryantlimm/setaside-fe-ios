//
//  ProductDetailView.swift
//  SetAside
//

import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @EnvironmentObject var cartViewModel: CartViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var quantity: Int = 1
    @State private var specialInstructions: String = ""
    @State private var navigateToCheckout: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Product Image
                    AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.lightGreen)
                                .overlay(
                                    ProgressView()
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .failure:
                            Rectangle()
                                .fill(Color.lightGreen)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.lightGreen)
                        }
                    }
                    .frame(height: 250)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Product Info
                    VStack(alignment: .leading, spacing: 16) {
                        // Name and Price
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(product.category ?? "Uncategorized")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Text("$\(product.price, specifier: "%.2f")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryGreen)
                        }
                        
                        // Availability
                        HStack {
                            Image(systemName: (product.isAvailable ?? true) ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor((product.isAvailable ?? true) ? .green : .red)
                            
                            Text((product.isAvailable ?? true) ? "In Stock" : "Out of Stock")
                                .font(.subheadline)
                                .foregroundColor((product.isAvailable ?? true) ? .green : .red)
                            
                            if let stock = product.stockQuantity {
                                Text("(\(stock) available)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Description
                        if let description = product.description, !description.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.headline)
                                
                                Text(description)
                                    .font(.body)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Divider()
                        
                        // Quantity Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quantity")
                                .font(.headline)
                            
                            HStack(spacing: 20) {
                                Button(action: {
                                    if quantity > 1 { quantity -= 1 }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(quantity > 1 ? .primaryGreen : .gray)
                                }
                                .disabled(quantity <= 1)
                                
                                Text("\(quantity)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .frame(minWidth: 40)
                                
                                Button(action: {
                                    quantity += 1
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.primaryGreen)
                                }
                            }
                        }
                        
                        // Special Instructions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Special Instructions (Optional)")
                                .font(.headline)
                            
                            TextField("Add any special requests...", text: $specialInstructions, axis: .vertical)
                                .lineLimit(3...5)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 100)
            }
            .background(Color.backgroundGreen)
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Add to Cart and Buy Now Buttons
                VStack(spacing: 12) {
                    HStack {
                        Text("Total:")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("$\(product.price * Double(quantity), specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryGreen)
                    }
                    
                    HStack(spacing: 12) {
                        // Add to Cart Button
                        Button(action: {
                            cartViewModel.addToCart(
                                product: product,
                                quantity: quantity,
                                specialInstructions: specialInstructions.isEmpty ? nil : specialInstructions
                            )
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "cart.badge.plus")
                                Text("Add to Cart")
                            }
                            .font(.headline)
                            .foregroundColor(.primaryGreen)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primaryGreen, lineWidth: 2)
                            )
                            .cornerRadius(12)
                        }
                        .disabled(!(product.isAvailable ?? true))
                        
                        // Buy Now Button
                        Button(action: {
                            cartViewModel.addToCart(
                                product: product,
                                quantity: quantity,
                                specialInstructions: specialInstructions.isEmpty ? nil : specialInstructions
                            )
                            navigateToCheckout = true
                        }) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                Text("Buy Now")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background((product.isAvailable ?? true) ? Color.primaryGreen : Color.gray)
                            .cornerRadius(12)
                        }
                        .disabled(!(product.isAvailable ?? true))
                    }
                }
                .padding()
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -4)
            }
            .navigationDestination(isPresented: $navigateToCheckout) {
                CheckoutView()
                    .onDisappear {
                        dismiss()
                    }
            }
        }
    }
}

#Preview {
    ProductDetailView(product: Product(
        id: "1",
        name: "Fresh Organic Apples",
        description: "Crisp and delicious organic apples from local farms. Perfect for snacking or baking.",
        price: 4.99,
        category: "Fruits",
        isAvailable: true,
        stockQuantity: 50,
        imageUrl: nil,
        createdAt: nil,
        updatedAt: nil
    ))
    .environmentObject(CartViewModel())
}
