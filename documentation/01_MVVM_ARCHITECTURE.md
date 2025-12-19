# MVVM Architecture in SetAside iOS

## 📐 Architecture Overview

MVVM (Model-View-ViewModel) separates the application into three distinct layers, promoting clean code, testability, and maintainability.

```
┌─────────────────────────────────────────────────────────────────┐
│                          USER ACTIONS                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         VIEW LAYER                              │
│   (SwiftUI Views - UI Rendering & User Interaction)            │
│                                                                 │
│   Examples: SignInView, HomeView, CartView, OrdersView          │
│                                                                 │
│   - Displays UI based on ViewModel state                        │
│   - Captures user input                                         │
│   - Calls ViewModel methods on user actions                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ @EnvironmentObject / @StateObject
                              │ Data Binding (@Published)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      VIEWMODEL LAYER                            │
│   (ObservableObject classes - Business Logic & State)          │
│                                                                 │
│   Examples: AuthViewModel, ProductViewModel, CartViewModel      │
│                                                                 │
│   - Manages UI state (@Published properties)                    │
│   - Contains business logic                                     │
│   - Calls Service layer for data operations                     │
│   - Transforms data for View consumption                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ async/await method calls
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       SERVICE LAYER                             │
│   (Singleton Services - API Communication)                      │
│                                                                 │
│   Examples: AuthService, ProductService, OrderService           │
│                                                                 │
│   - Abstracts API endpoints                                     │
│   - Calls NetworkManager for HTTP requests                      │
│   - Returns decoded Model objects                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTP Requests
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      NETWORK MANAGER                            │
│   (Singleton - HTTP Client)                                     │
│                                                                 │
│   - Creates URLRequest with headers                             │
│   - Handles authentication (Bearer token)                       │
│   - Executes requests via URLSession                            │
│   - Decodes JSON responses                                      │
│   - Handles errors                                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        MODEL LAYER                              │
│   (Codable structs - Data Structures)                          │
│                                                                 │
│   Examples: User, Product, Order, OrderItem, CartItem           │
│                                                                 │
│   - Pure data structures                                        │
│   - Conforms to Codable for JSON encoding/decoding             │
│   - Contains CodingKeys for API field mapping                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Direction

### **Unidirectional Data Flow (User Action → API → UI Update)**

```
User Action → View → ViewModel → Service → NetworkManager → API
                                                              │
UI Update ← View ← ViewModel (state update) ← Service ← Response
```

**Key Principle**: Data flows DOWN through method calls, and state flows UP through bindings.

---

## 📦 MODEL LAYER Deep Dive

### Purpose
- Define data structures that mirror API responses
- Provide type-safe data handling
- Handle JSON encoding/decoding

### Key Files

| File | Purpose |
|------|---------|
| `User.swift` | User model, AuthResponse, LoginRequest, RegisterRequest |
| `Product.swift` | Product model, ProductsResponse, CreateProductRequest |
| `Order.swift` | Order model, OrderItem, CreateOrderRequest |
| `CartItem.swift` | Local cart item (not from API) |
| `APIError.swift` | Error types and error response parsing |

### Example: Product Model

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
        case isAvailable = "is_available"      // Maps snake_case to camelCase
        case stockQuantity = "stock_quantity"
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

**Key Points for Exam:**
- `Codable` enables automatic JSON encoding/decoding
- `Identifiable` provides `id` for SwiftUI lists
- `CodingKeys` maps JSON snake_case to Swift camelCase

---

## 👁 VIEW LAYER Deep Dive

### Purpose
- Render UI based on ViewModel state
- Capture and forward user interactions
- NO business logic in Views

### Key Patterns Used

#### 1. @EnvironmentObject (Dependency Injection)
```swift
struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var cartViewModel: CartViewModel
    @EnvironmentObject var productViewModel: ProductViewModel
    
    var body: some View {
        // Views can access any ViewModel injected at app level
    }
}
```

#### 2. @StateObject (View-owned ViewModel)
```swift
struct MainTabView: View {
    @StateObject private var productViewModel = ProductViewModel()
    // This view OWNS the ProductViewModel lifecycle
}
```

#### 3. Reactive UI Updates
```swift
// When productViewModel.products changes, the LazyVGrid automatically re-renders
LazyVGrid(columns: columns) {
    ForEach(productViewModel.products) { product in
        ProductCard(product: product)
    }
}
```

---

## 🧠 VIEWMODEL LAYER Deep Dive

### Purpose
- Hold UI state
- Contain business logic
- Communicate with Services
- Transform data for Views

### Key Patterns Used

#### 1. ObservableObject + @Published
```swift
@MainActor
class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []        // UI binds to this
    @Published var isLoading: Bool = false         // Shows loading spinner
    @Published var errorMessage: String?           // Shows error alert
    @Published var showError: Bool = false
    
    private let productService = ProductService.shared
}
```

#### 2. @MainActor (Thread Safety)
```swift
@MainActor
class AuthViewModel: ObservableObject {
    // All @Published updates MUST happen on main thread
    // @MainActor ensures this automatically
}
```

#### 3. Async Method Pattern
```swift
func fetchProducts(refresh: Bool = false) async {
    guard !isLoading else { return }  // Prevent duplicate calls
    
    isLoading = true                  // Show loading state
    errorMessage = nil                // Clear previous errors
    
    do {
        let fetched = try await productService.getProducts()
        products = fetched            // Update state
    } catch let error as APIError {
        errorMessage = error.errorDescription
        showError = true
    } catch {
        errorMessage = error.localizedDescription
        showError = true
    }
    
    isLoading = false                 // Hide loading state
}
```

---

## 🌐 SERVICE LAYER Deep Dive

### Purpose
- Abstract API endpoints
- Provide clean interface for ViewModels
- Handle request/response transformation

### Singleton Pattern
```swift
class ProductService {
    static let shared = ProductService()  // Single instance
    private let networkManager = NetworkManager.shared
    
    private init() {}  // Prevent external instantiation
}
```

### Example Method
```swift
func getProducts(page: Int, limit: Int, category: String?) async throws -> [Product] {
    var endpoint = "/products?page=\(page)&limit=\(limit)"
    if let category = category {
        endpoint += "&category=\(category)"
    }
    
    let response: ProductsResponse = try await networkManager.request(
        endpoint: endpoint,
        method: "GET",
        requiresAuth: false
    )
    
    return response.allProducts
}
```

---

## 🔗 NETWORK MANAGER Deep Dive

### Purpose
- Central HTTP client
- Handle authentication headers
- Parse responses and errors

### Key Features

#### 1. Token Management
```swift
private var accessToken: String? {
    get { UserDefaults.standard.string(forKey: "accessToken") }
    set { UserDefaults.standard.set(newValue, forKey: "accessToken") }
}
```

#### 2. Request Creation
```swift
private func createRequest(endpoint: String, method: String, 
                           body: Data?, requiresAuth: Bool) throws -> URLRequest {
    guard let url = URL(string: "\(baseURL)\(endpoint)") else {
        throw APIError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    if requiresAuth, let token = accessToken {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    if let body = body {
        request.httpBody = body
    }
    
    return request
}
```

#### 3. Generic Response Handling
```swift
func request<T: Decodable>(endpoint: String, method: String, 
                            body: Encodable?, requiresAuth: Bool) async throws -> T {
    // ... create request
    
    let (data, response) = try await session.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIError.invalidResponse
    }
    
    switch httpResponse.statusCode {
    case 200...299:
        return try JSONDecoder().decode(T.self, from: data)
    case 401:
        clearToken()
        throw APIError.unauthorized
    case 404:
        throw APIError.notFound
    default:
        // Parse error response
        throw APIError.httpError(statusCode: code, message: message)
    }
}
```

---

## 🔄 Dependency Injection in SwiftUI

### App Level Injection (SetAsideApp.swift)
```swift
@main
struct SetAsideApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var cartViewModel = CartViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)  // Inject globally
                .environmentObject(cartViewModel)  // Inject globally
        }
    }
}
```

### Flow:
1. `SetAsideApp` creates ViewModels with `@StateObject`
2. Injects them via `.environmentObject()`
3. Child views access via `@EnvironmentObject`
4. All views share the SAME instance

---

## 📊 State Management Summary

| Property Wrapper | Purpose | Scope |
|-----------------|---------|-------|
| `@StateObject` | Create & own ViewModel | View lifetime |
| `@EnvironmentObject` | Access shared ViewModel | Injection from parent |
| `@Published` | Observable property | ViewModel internal |
| `@State` | View-local state | View only |
| `@Binding` | Two-way binding | Parent-child |

---

## 🎯 MVVM Benefits

1. **Separation of Concerns** - Views don't know about networking
2. **Testability** - ViewModels can be unit tested without UI
3. **Reusability** - ViewModels can be shared across views
4. **Maintainability** - Clear structure makes changes easier
5. **Reactivity** - Combine's `@Published` enables automatic UI updates

---

## 🗣 What to Say During Exam

> "In this project, I implemented MVVM architecture using SwiftUI and Combine. 
> The **Model layer** consists of Codable structs that map to our REST API responses.
> The **View layer** uses SwiftUI Views that declaratively render UI based on ViewModel state.
> The **ViewModel layer** uses ObservableObject classes with @Published properties for reactive state management.
> Data flows unidirectionally - user actions trigger ViewModel methods, which call Services, 
> and state updates automatically propagate back to Views through Combine's property observation."
