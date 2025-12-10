//
//  HomeView.swift
//  SetAside
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var productViewModel: ProductViewModel
    @EnvironmentObject var cartViewModel: CartViewModel
    
    @Binding var hideTabBar: Bool
    @State private var showCart = false
    @State private var showCheckout = false
    @State private var selectedProduct: Product?
    
    init(hideTabBar: Binding<Bool> = .constant(false)) {
        self._hideTabBar = hideTabBar
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.backgroundGreen
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        headerView
                        
                        // Content
                        VStack(spacing: 24) {
                            // Search Bar
                            searchBar
                            
                            // Categories
                            if !productViewModel.categories.isEmpty {
                                categoriesSection
                            }
                            
                            // Products Grid
                            productsSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
            .navigationDestination(isPresented: $showCart) {
                NavigationStack {
                    CartView(hideTabBar: $hideTabBar)
                        .onAppear { hideTabBar = true }
                        .onDisappear { hideTabBar = false }
                }
            }
            .navigationDestination(isPresented: $showCheckout) {
                CheckoutView(hideTabBar: $hideTabBar)
                    //.onAppear { hideTabBar = true }
                    //.onDisappear { hideTabBar = false }
            }
            .sheet(item: $selectedProduct) { product in
                ProductDetailView(product: product)
            }
            .refreshable {
                await productViewModel.loadInitialData()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        Group {
            let topSafeArea = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello,")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    Text(authViewModel.currentUser?.fullName ?? "Guest")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Cart Button
                Button(action: { showCart = true }) {
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image("cart")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                        
                        // Badge
                        if cartViewModel.itemCount > 0 {
                            Text("\(cartViewModel.itemCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 6, y: -6)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.top, 40)
            .background(Color.darkGreen)
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search products...", text: $productViewModel.searchText)
                    .onSubmit {
                        productViewModel.search()
                    }
                
                if !productViewModel.searchText.isEmpty {
                    Button(action: {
                        productViewModel.searchText = ""
                        productViewModel.search()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            
            Button(action: { productViewModel.search() }) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.primaryGreen)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Categories Section
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.title3)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // All category
                    CategoryChip(
                        title: "All",
                        isSelected: productViewModel.selectedCategory == nil,
                        action: { productViewModel.selectCategory(nil) }
                    )
                    
                    ForEach(productViewModel.categories, id: \.self) { category in
                        CategoryChip(
                            title: category,
                            isSelected: productViewModel.selectedCategory == category,
                            action: { productViewModel.selectCategory(category) }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Products Section
    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Products")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                if productViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if productViewModel.products.isEmpty && !productViewModel.isLoading {
                EmptyStateView(
                    icon: "bag.badge.questionmark",
                    title: "No Products Found",
                    message: "Try adjusting your search or category filter"
                )
                .frame(height: 200)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(productViewModel.products) { product in
                        ProductCard(
                            product: product,
                            onTap: {
                                selectedProduct = product
                            },
                            onBuyNow: {
                                cartViewModel.addToCart(product: product)
                                showCheckout = true
                            }
                        )
                        .onAppear {
                            productViewModel.loadMoreIfNeeded(currentProduct: product)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .darkGreen)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.primaryGreen : Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Product Card
struct ProductCard: View {
    let product: Product
    var onTap: () -> Void
    var onBuyNow: () -> Void
    @EnvironmentObject var cartViewModel: CartViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product Image
            AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.lightGreen)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
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
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    Rectangle()
                        .fill(Color.lightGreen)
                }
            }
            .frame(height: 100)
            .cornerRadius(8)
            .onTapGesture(perform: onTap)
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text(String(format: "$%.2f", product.price))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryGreen)
                
                if let category = product.category as String? {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Action Buttons
            VStack(spacing: 6) {
                // Add to Cart Button
                Button(action: {
                    cartViewModel.addToCart(product: product)
                }) {
                    HStack {
                        if cartViewModel.isInCart(product) {
                            Text("In Cart (\(cartViewModel.getQuantity(for: product)))")
                        } else {
                            Image(systemName: "plus")
                            Text("Add")
                        }
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(cartViewModel.isInCart(product) ? Color.primaryGreen : Color.lightGreen)
                    .foregroundColor(cartViewModel.isInCart(product) ? .white : .primaryGreen)
                    .cornerRadius(8)
                }
                
                // Buy Now Button
                Button(action: onBuyNow) {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text("Buy Now")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.primaryGreen)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    HomeView(hideTabBar: .constant(false))
        .environmentObject(AuthViewModel())
        .environmentObject(ProductViewModel())
        .environmentObject(CartViewModel())
}
