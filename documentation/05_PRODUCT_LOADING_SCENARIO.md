# Scenario: Product Loading

## 📋 Scenario Overview

**User Action**: User navigates to Home screen (or pulls to refresh)  
**Platform**: iOS (Swift/SwiftUI)  
**Expected Behavior**: Fetch products from API, display in grid, support filtering and pagination

---

## 🔄 Complete Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  USER OPENS HOME TAB (or pulls to refresh)                                   │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  VIEW LAYER: HomeView.swift                                                  │
│                                                                              │
│  ProductViewModel.init() {                                                   │
│      Task {                                                                  │
│          await loadInitialData()  // Auto-load on init                       │
│      }                                                                       │
│  }                                                                           │
│                                                                              │
│  .refreshable {                                                              │
│      await productViewModel.loadInitialData()                               │
│  }                                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  VIEWMODEL LAYER: ProductViewModel.swift                                     │
│                                                                              │
│  func loadInitialData() async {                                              │
│      await fetchCategories()                                                 │
│      await fetchProducts(refresh: true)                                      │
│  }                                                                           │
│                                                                              │
│  func fetchProducts(refresh: Bool) async {                                   │
│      isLoading = true                                                        │
│      let fetched = try await productService.getProducts(...)                 │
│      products = fetched                                                      │
│  }                                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  SERVICE LAYER: ProductService.swift                                         │
│                                                                              │
│  func getProducts(page, limit, category, isAvailable, search) {              │
│      endpoint = "/products?page=1&limit=20&is_available=true"                │
│      response = try await networkManager.request(endpoint)                   │
│      return response.allProducts                                             │
│  }                                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  NETWORK: GET /api/v1/products?page=1&limit=20&is_available=true             │
│                                                                              │
│  Response: { "data": [Product, Product, ...], "total": 50 }                  │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  RETURN PATH - UI Updates                                                    │
│                                                                              │
│  productViewModel.products = [Product]                                       │
│       │                                                                      │
│       ▼                                                                      │
│  HomeView re-renders LazyVGrid with product cards                            │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 📍 Step-by-Step Code Flow

### STEP 1: VIEW LAYER - ViewModel Initialization

**File**: `SetAside/Views/Main/MainTabView.swift` (Line 11)

```swift
struct MainTabView: View {
    @StateObject private var productViewModel = ProductViewModel()
    //                        ↑ Creates and OWNS the ViewModel
    
    var body: some View {
        // ...
        HomeView(hideTabBar: $hideTabBar)
            .environmentObject(productViewModel)  // Pass down to child views
    }
}
```

**File**: `SetAside/ViewModels/ProductViewModel.swift` (Lines 10-27)

```swift
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
            await loadInitialData()  // ← AUTO-LOAD ON CREATION
        }
    }
}
```

**What happens here:**
1. `MainTabView` creates ProductViewModel with `@StateObject`
2. ProductViewModel's `init()` immediately starts loading data
3. ViewModel is injected into environment for `HomeView` and children

---

### STEP 2: VIEWMODEL LAYER - Load Initial Data

**File**: `SetAside/ViewModels/ProductViewModel.swift` (Lines 29-32)

```swift
func loadInitialData() async {
    await fetchCategories()          // Load category list first
    await fetchProducts(refresh: true)  // Then load products
}
```

This method coordinates loading all needed data:
1. **Categories** - For the filter chips
2. **Products** - For the main product grid

---

### STEP 3: VIEWMODEL LAYER - Fetch Products

**File**: `SetAside/ViewModels/ProductViewModel.swift` (Lines 34-84)

```swift
func fetchProducts(refresh: Bool = false) async {
    // STEP 3a: Prevent duplicate calls
    guard !isLoading else { return }
    
    // STEP 3b: Handle refresh vs pagination
    if refresh {
        currentPage = 1
        hasMoreProducts = true
    }
    
    // STEP 3c: Check if more products exist
    guard hasMoreProducts else { return }
    
    // STEP 3d: Set loading state
    isLoading = true
    errorMessage = nil
    
    do {
        // STEP 3e: Call service
        let fetchedProducts = try await productService.getProducts(
            page: currentPage,
            limit: 20,
            category: selectedCategory,        // Filter by category
            isAvailable: true,                 // Only show available products
            search: searchText.isEmpty ? nil : searchText  // Search filter
        )
        
        #if DEBUG
        print("✅ Fetched \(fetchedProducts.count) products for page \(currentPage)")
        #endif
        
        // STEP 3f: Update products array
        if refresh {
            products = fetchedProducts         // Replace all
        } else {
            products.append(contentsOf: fetchedProducts)  // Append for pagination
        }
        
        // STEP 3g: Check if more pages exist
        hasMoreProducts = fetchedProducts.count == 20  // If less than limit, no more
        currentPage += 1
        
    } catch let error as APIError {
        errorMessage = error.errorDescription
        showError = true
    } catch {
        errorMessage = error.localizedDescription
        showError = true
    }
    
    isLoading = false
}
```

**State Changes:**

| Property | Before | During | After (Success) |
|----------|--------|--------|-----------------|
| `isLoading` | false | **true** | false |
| `products` | [] | [] | **[Product, ...]** |
| `currentPage` | 1 | 1 | **2** |
| `hasMoreProducts` | true | true | true/false |

---

### STEP 4: SERVICE LAYER - Build Query and Request

**File**: `SetAside/Services/ProductService.swift` (Lines 14-41)

```swift
func getProducts(
    page: Int = 1,
    limit: Int = 20,
    category: String? = nil,
    isAvailable: Bool? = nil,
    search: String? = nil
) async throws -> [Product] {
    
    // STEP 4a: Build query string
    var endpoint = "/products?page=\(page)&limit=\(limit)"
    
    if let category = category {
        // URL encode the category name
        endpoint += "&category=\(category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? category)"
    }
    if let isAvailable = isAvailable {
        endpoint += "&is_available=\(isAvailable)"
    }
    if let search = search, !search.isEmpty {
        endpoint += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? search)"
    }
    
    // STEP 4b: Make request
    let response: ProductsResponse = try await networkManager.request(
        endpoint: endpoint,
        method: "GET",
        requiresAuth: false  // Products are public
    )
    
    return response.allProducts
}
```

**Example Endpoints:**
```
/products?page=1&limit=20&is_available=true                     // Basic
/products?page=1&limit=20&is_available=true&category=Coffee     // Filtered
/products?page=1&limit=20&is_available=true&search=Latte        // Search
/products?page=2&limit=20&is_available=true                     // Pagination
```

---

### STEP 5: MODEL LAYER - Response Structure

**File**: `SetAside/Models/Product.swift` (Lines 74-98)

```swift
struct ProductsResponse: Codable {
    let data: [Product]?        // Some APIs use "data"
    let products: [Product]?    // Some use "products"
    let items: [Product]?       // Some use "items"
    let meta: ProductsMeta?
    let total: Int?
    let page: Int?
    let limit: Int?
    let totalPages: Int?
    
    enum CodingKeys: String, CodingKey {
        case data, products, items, meta
        case total, page, limit
        case totalPages = "total_pages"
    }
    
    // FLEXIBLE ACCESSOR - works with different API formats
    var allProducts: [Product] {
        return data ?? products ?? items ?? []
    }
}
```

**Why flexible accessor?**
> APIs might return products under different keys. This computed property tries all common keys and returns the first non-nil array.

**API Response Example:**
```json
{
    "data": [
        {
            "id": "uuid-1",
            "name": "Cappuccino",
            "description": "Rich espresso with steamed milk",
            "price": 4.50,
            "category": "Coffee",
            "is_available": true,
            "stock_quantity": 100,
            "image_url": "https://example.com/cappuccino.jpg",
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        },
        // ... more products
    ],
    "total": 50,
    "page": 1,
    "limit": 20,
    "total_pages": 3
}
```

---

### STEP 6: MODEL LAYER - Product Decoding

**File**: `SetAside/Models/Product.swift` (Lines 8-72)

```swift
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
        case id, name, description, price, category
        case isAvailable = "is_available"
        case stockQuantity = "stock_quantity"
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // CUSTOM DECODER with safe defaults
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
    
    // Hashable conformance for SwiftUI lists
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        lhs.id == rhs.id
    }
}
```

**Why custom init(from decoder:)?**
> Provides default values for missing fields and logs decoded products in debug mode. Prevents crashes if API returns incomplete data.

---

### STEP 7: VIEW LAYER - Display Products

**File**: `SetAside/Views/Home/HomeView.swift` (Lines 192-240)

```swift
private var productsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
        HStack {
            Text("Products")
                .font(.title3)
                .fontWeight(.bold)
            
            Spacer()
            
            // Show loading spinner
            if productViewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        
        // Empty state
        if productViewModel.products.isEmpty && !productViewModel.isLoading {
            EmptyStateView(
                icon: "bag.badge.questionmark",
                title: "No Products Found",
                message: "Try adjusting your search or category filter"
            )
        } else {
            // Product Grid
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
                        onTap: { selectedProduct = product },
                        onBuyNow: {
                            cartViewModel.addToCart(product: product)
                            showCheckout = true
                        }
                    )
                    .onAppear {
                        // PAGINATION TRIGGER
                        productViewModel.loadMoreIfNeeded(currentProduct: product)
                    }
                }
            }
        }
    }
}
```

**SwiftUI Reactivity:**
- `ForEach(productViewModel.products)` automatically re-renders when products array changes
- `@EnvironmentObject` establishes binding to ProductViewModel
- `isLoading` controls ProgressView visibility
- `onAppear` on each card enables infinite scroll

---

## 🔄 Pagination Flow

### Load More Products

**File**: `SetAside/ViewModels/ProductViewModel.swift` (Lines 109-117)

```swift
func loadMoreIfNeeded(currentProduct: Product) {
    // Check if we've scrolled to the last product
    guard let lastProduct = products.last else { return }
    
    if currentProduct.id == lastProduct.id {
        // Reached the end, load more
        Task {
            await fetchProducts()  // Uses currentPage (already incremented)
        }
    }
}
```

**Pagination Sequence:**
```
User scrolls down
       │
       ▼
ProductCard.onAppear triggers for last item
       │
       ▼
loadMoreIfNeeded() checks if current == last
       │
       ▼
fetchProducts() with currentPage = 2
       │
       ▼
products.append(contentsOf: newProducts)
       │
       ▼
LazyVGrid re-renders with new items
```

---

## 🔍 Category Filtering

### Select Category

**File**: `SetAside/ViewModels/ProductViewModel.swift` (Lines 96-101)

```swift
func selectCategory(_ category: String?) {
    selectedCategory = category    // Update filter
    Task {
        await fetchProducts(refresh: true)  // Re-fetch with filter
    }
}
```

**View Trigger:**

```swift
// HomeView.swift - Categories Section
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
```

---

## 🔍 Search Flow

### Search Products

**File**: `SetAside/ViewModels/ProductViewModel.swift` (Lines 103-107)

```swift
func search() {
    Task {
        await fetchProducts(refresh: true)
    }
}
```

**View Implementation:**

```swift
// HomeView.swift - Search Bar
HStack {
    TextField("Search products...", text: $productViewModel.searchText)
        .onSubmit {
            productViewModel.search()  // Search on Enter
        }
    
    if !productViewModel.searchText.isEmpty {
        Button(action: {
            productViewModel.searchText = ""
            productViewModel.search()  // Clear and refresh
        }) {
            Image(systemName: "xmark.circle.fill")
        }
    }
}

Button(action: { productViewModel.search() }) {
    Image(systemName: "magnifyingglass")
}
```

---

## ↻ Pull-to-Refresh

**File**: `SetAside/Views/Home/HomeView.swift` (Lines 68-70)

```swift
.refreshable {
    await productViewModel.loadInitialData()
}
```

**What happens:**
1. User pulls down on ScrollView
2. SwiftUI shows refresh spinner
3. `loadInitialData()` re-fetches categories and products
4. Spinner dismisses when async completes

---

## 🗂 State Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRODUCT LOADING STATES                       │
└─────────────────────────────────────────────────────────────────┘

     ┌─────────────┐
     │   INITIAL   │
     │ products=[] │
     │ isLoading=F │
     └──────┬──────┘
            │ init() or refresh
            ▼
     ┌─────────────┐
     │   LOADING   │
     │ products=[] │
     │ isLoading=T │
     └──────┬──────┘
            │
     ┌──────┴──────┐
     │             │
     ▼             ▼
┌─────────┐   ┌─────────┐
│ SUCCESS │   │  ERROR  │
│products │   │products │
│=[...]   │   │=[]      │
│loading=F│   │error=X  │
└─────────┘   └─────────┘
     │
     │ scroll to end
     ▼
┌─────────────┐
│ PAGINATING  │
│ products=[..│
│ loading=T   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ MORE LOADED │
│ products=[..│
│ ..more]     │
└─────────────┘
```

---

## ❓ Key Points for Exam

### Q: Why use LazyVGrid?
> LazyVGrid only renders visible items, improving performance for large lists. Regular VStack would render all items immediately, consuming memory.

### Q: How does pagination work?
> Each ProductCard has an `.onAppear` modifier. When the last card appears (user scrolls to it), `loadMoreIfNeeded()` triggers `fetchProducts()` for the next page.

### Q: Why is requiresAuth false for products?
> Product catalog is public - users should be able to browse without logging in. This improves user experience and conversion.

### Q: How does category filtering work?
> `selectCategory()` updates `selectedCategory` property and triggers `fetchProducts(refresh: true)`. The service includes the category in the API query.

### Q: What design patterns are used?
> - **Repository**: ProductService abstracts API from ViewModel
> - **Observer**: @Published enables reactive UI updates
> - **Pagination**: Cursor-based (page numbers) with infinite scroll

---

## ⏱ Timing Estimates

| Operation | Duration |
|-----------|----------|
| ViewModel init | ~1ms |
| API call (products) | ~200-400ms |
| UI rendering (20 items) | ~50ms |
| Pagination (load more) | ~200-400ms |
| Category filter + reload | ~200-400ms |
| Pull-to-refresh | ~200-400ms |
