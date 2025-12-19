# Common Exam Questions & Answers

## 📚 Table of Contents

1. [Architecture Questions](#architecture-questions)
2. [Data Flow Questions](#data-flow-questions)
3. [SwiftUI Specific Questions](#swiftui-specific-questions)
4. [Networking Questions](#networking-questions)
5. [Testing Questions](#testing-questions)
6. [Design Pattern Questions](#design-pattern-questions)
7. [Scenario-Based Questions](#scenario-based-questions)

---

## 🏗 Architecture Questions

### Q1: Why did you choose MVVM architecture?

**Answer:**
> "I chose MVVM for several reasons:
> 
> 1. **Separation of Concerns** - Views only handle UI rendering, ViewModels contain business logic, Models are pure data structures. This makes the code easier to maintain.
> 
> 2. **Testability** - ViewModels can be unit tested without running the UI. I can test business logic in isolation by mocking the service layer.
> 
> 3. **SwiftUI Compatibility** - MVVM works naturally with SwiftUI's declarative paradigm. @Published properties in ViewModels automatically trigger view updates through Combine.
> 
> 4. **Team Scalability** - Different developers can work on Views and ViewModels independently without conflicts.
> 
> 5. **Reusability** - ViewModels can be shared across multiple views if they need the same data."

---

### Q2: Can you explain the layers in your architecture?

**Answer:**
```
┌─────────────────────────────────────────────────────────────┐
│ VIEW LAYER (SwiftUI Views)                                  │
│ • Renders UI based on ViewModel state                       │
│ • Captures user interactions                                │
│ • No business logic                                         │
├─────────────────────────────────────────────────────────────┤
│ VIEWMODEL LAYER (ObservableObject classes)                  │
│ • Holds UI state (@Published properties)                    │
│ • Contains business logic                                   │
│ • Transforms data for View consumption                      │
│ • Calls Service layer for data operations                   │
├─────────────────────────────────────────────────────────────┤
│ SERVICE LAYER (Singleton services)                          │
│ • Abstracts API endpoints                                   │
│ • Builds requests and parses responses                      │
│ • Contains no UI-related logic                              │
├─────────────────────────────────────────────────────────────┤
│ NETWORK LAYER (NetworkManager)                              │
│ • Central HTTP client                                       │
│ • Handles authentication headers                            │
│ • Error handling and response parsing                       │
├─────────────────────────────────────────────────────────────┤
│ MODEL LAYER (Codable structs)                               │
│ • Pure data structures                                      │
│ • JSON encoding/decoding via Codable                        │
│ • No business logic                                         │
└─────────────────────────────────────────────────────────────┘
```

---

### Q3: How does data flow through your application?

**Answer:**
> "Data flows unidirectionally in my application:
>
> **User Action → ViewModel Method → Service → Network → API**
>
> Then the response flows back:
>
> **API Response → Network Decoding → Service → ViewModel State Update → View Re-render**
>
> For example, when a user taps 'Add to Cart':
> 1. **View** captures tap and calls `cartViewModel.addToCart(product)`
> 2. **ViewModel** modifies the `items` array (local operation)
> 3. **@Published** triggers SwiftUI to re-render
> 4. **View** shows updated cart badge
>
> The key principle is that Views don't directly modify data - they always go through ViewModels."

---

## 🔄 Data Flow Questions

### Q4: How does data binding work in your implementation?

**Answer:**
> "I use Combine's property observation through these property wrappers:
>
> - **@Published** - On ViewModel properties. When these change, Combine publishes an event.
>
> - **@StateObject** - Creates and owns a ViewModel instance. The View manages its lifecycle.
>
> - **@EnvironmentObject** - Accesses a ViewModel injected by a parent view. Multiple views share the same instance.
>
> - **@State** - For View-local state like form fields or toggles.
>
> - **@Binding** - Two-way binding between parent and child views.
>
> Example:
> ```swift
> class CartViewModel: ObservableObject {
>     @Published var items: [CartItem] = []  // Observable
> }
>
> struct HomeView: View {
>     @EnvironmentObject var cartViewModel: CartViewModel  // Bound
>     
>     var body: some View {
>         Text("\(cartViewModel.itemCount)")  // Auto-updates
>     }
> }
> ```
>
> When `items` changes, any view observing `cartViewModel` automatically re-renders."

---

### Q5: What happens when [user taps Login button]?

**Answer:**
> "Let me trace through the complete flow:
>
> **1. View Layer (SignInView.swift)**
> - User taps 'Sign In' button
> - Button action creates async Task and calls `authViewModel.login(email, password)`
>
> **2. ViewModel Layer (AuthViewModel.swift)**
> - Sets `isLoading = true` (shows loading spinner)
> - Calls `authService.login(email, password)`
>
> **3. Service Layer (AuthService.swift)**
> - Creates `LoginRequest` with email/password
> - Calls `networkManager.request("/auth/login", method: "POST", body: request)`
>
> **4. Network Layer (NetworkManager.swift)**
> - Encodes request body to JSON
> - Creates URLRequest with headers
> - Executes async HTTP request
> - Decodes response to `AuthResponse`
>
> **5. Return Path**
> - `AuthService` saves JWT token to UserDefaults
> - Returns `AuthResponse` to ViewModel
> - `AuthViewModel` sets `currentUser = response.user`, `isLoggedIn = true`
>
> **6. View Update**
> - `RootView` observes `isLoggedIn` change
> - SwiftUI re-renders, switching from `SignInView` to `MainTabView`
>
> The entire flow takes approximately 300-600ms, mostly network time."

---

### Q6: How do you handle [error scenario]?

**Answer:**
> "Errors are handled at multiple levels:
>
> **Network Layer:**
> - Catches HTTP status codes (401, 404, 500, etc.)
> - Parses error response body for message
> - Throws typed `APIError` enum
>
> **ViewModel Layer:**
> - Catches `APIError` with do-catch blocks
> - Sets `errorMessage = error.errorDescription`
> - Sets `showError = true` to trigger UI
>
> **View Layer:**
> - Observes `showError` property
> - Shows `.alert()` with error message
> - Provides retry action if applicable
>
> For example, if login fails:
> ```swift
> } catch let error as APIError {
>     self.errorMessage = error.errorDescription  // e.g., 'Incorrect password'
>     self.showError = true  // Triggers alert in View
> }
> ```
>
> For critical errors like unauthorized (401), we automatically logout the user."

---

## 📱 SwiftUI Specific Questions

### Q7: Explain the lifecycle of a ViewModel in your app

**Answer:**
> "ViewModel lifecycle depends on how it's created:
>
> **@StateObject (Owned by View):**
> - Created when the View appears for the first time
> - Instance persists across View updates/re-renders
> - Destroyed when the View is removed from hierarchy
>
> **@EnvironmentObject (Shared):**
> - Created at app level in `SetAsideApp.swift`
> - Lives for entire app lifetime
> - Same instance shared across all views
>
> Example:
> ```swift
> // App-level (lives forever)
> @StateObject private var authViewModel = AuthViewModel()
>
> // View-level (lives while tab is visible)
> @StateObject private var productViewModel = ProductViewModel()
> ```
>
> I use `@StateObject` for single-view ViewModels and `@EnvironmentObject` for shared state like authentication and cart."

---

### Q8: Why use @StateObject vs @EnvironmentObject?

**Answer:**
| Wrapper | When to Use | Lifecycle |
|---------|-------------|-----------|
| `@StateObject` | View creates and owns the ViewModel | View's lifetime |
| `@EnvironmentObject` | View accesses shared ViewModel | Injector's lifetime |

> "In my app:
> - `AuthViewModel` and `CartViewModel` are `@StateObject` in `SetAsideApp` and injected as `@EnvironmentObject` to children. They need to persist across navigation.
> - `ProductViewModel` is `@StateObject` in `MainTabView` because it's only needed for the Home tab.
> - `OrderViewModel` is `@StateObject` in `OrdersView` because each instance of that screen needs its own state."

---

### Q9: How do you handle navigation in SwiftUI?

**Answer:**
> "I use SwiftUI's NavigationStack with programmatic navigation:
>
> **1. NavigationStack** - Container for navigation hierarchy
>
> **2. navigationDestination** - Defines destination Views for navigation
>
> **3. @State boolean** - Controls whether to navigate
>
> Example:
> ```swift
> struct HomeView: View {
>     @State private var showCart = false
>     
>     var body: some View {
>         NavigationStack {
>             Button("Go to Cart") { showCart = true }
>                 .navigationDestination(isPresented: $showCart) {
>                     CartView()
>                 }
>         }
>     }
> }
> ```
>
> For tab-based navigation, I use a custom tab bar with `@State private var selectedTab = 0` and `switch` statement to show different views."

---

## 🌐 Networking Questions

### Q10: How does authentication work in your app?

**Answer:**
> "My app uses JWT (JSON Web Token) bearer authentication:
>
> **Login Flow:**
> 1. User enters credentials
> 2. POST /auth/login returns `{ access_token: "jwt...", user: {...} }`
> 3. Token is saved to UserDefaults
> 4. `isLoggedIn` flag is set to true
>
> **Authenticated Requests:**
> ```swift
> if requiresAuth, let token = accessToken {
>     request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
> }
> ```
>
> **Token Expiry:**
> - If API returns 401, `NetworkManager` clears the token
> - `AuthViewModel` receives `unauthorized` error
> - User is logged out and redirected to login
>
> **Persistence:**
> - Token stored in UserDefaults (key: 'accessToken')
> - On app launch, check UserDefaults for existing token
> - If exists, attempt to fetch user profile to validate"

---

### Q11: How do you handle different API response formats?

**Answer:**
> "My API sometimes returns data in different wrappers. I handle this with flexible decoding:
>
> ```swift
> struct ProductsResponse: Codable {
>     let data: [Product]?      // Some endpoints use 'data'
>     let products: [Product]?  // Some use 'products'
>     let items: [Product]?     // Some use 'items'
>     
>     var allProducts: [Product] {
>         return data ?? products ?? items ?? []
>     }
> }
> ```
>
> For order creation, I use `requestWithFlexibleResponse` which tries:
> 1. Direct decoding as `Order`
> 2. Wrapped in `{ "order": {...} }`
> 3. Wrapped in `{ "data": {...} }`
>
> This makes the app resilient to API inconsistencies."

---

## 🧪 Testing Questions

### Q12: How would you test this component?

**Answer:**
> "ViewModels are designed to be testable in isolation. Here's how I would test `AuthViewModel`:
>
> ```swift
> class MockAuthService: AuthServiceProtocol {
>     var shouldSucceed = true
>     var mockUser = User(id: '1', email: 'test@test.com', ...)
>     
>     func login(email: String, password: String) async throws -> AuthResponse {
>         if shouldSucceed {
>             return AuthResponse(accessToken: 'token', user: mockUser)
>         } else {
>             throw APIError.unauthorized
>         }
>     }
> }
>
> class AuthViewModelTests: XCTestCase {
>     func testLoginSuccess() async {
>         // Arrange
>         let mockService = MockAuthService()
>         let viewModel = AuthViewModel(authService: mockService)
>         
>         // Act
>         await viewModel.login(email: 'test@test.com', password: 'password')
>         
>         // Assert
>         XCTAssertTrue(viewModel.isLoggedIn)
>         XCTAssertNotNil(viewModel.currentUser)
>         XCTAssertFalse(viewModel.isLoading)
>     }
>     
>     func testLoginFailure() async {
>         let mockService = MockAuthService()
>         mockService.shouldSucceed = false
>         let viewModel = AuthViewModel(authService: mockService)
>         
>         await viewModel.login(email: 'test@test.com', password: 'wrong')
>         
>         XCTAssertFalse(viewModel.isLoggedIn)
>         XCTAssertTrue(viewModel.showError)
>     }
> }
> ```
>
> The key is injecting dependencies (services) so they can be mocked in tests."

---

### Q13: What would you mock for testing?

**Answer:**
> "For comprehensive testing, I would mock:
>
> **1. Network Layer (NetworkManager)**
> - Return canned responses without HTTP calls
> - Simulate errors (401, 500, timeout)
>
> **2. Services (AuthService, ProductService, OrderService)**
> - Control exactly what data ViewModels receive
> - Test edge cases (empty arrays, missing fields)
>
> **3. UserDefaults**
> - Test token persistence
> - Test clean slate scenarios
>
> **Example Protocol for Mocking:**
> ```swift
> protocol AuthServiceProtocol {
>     func login(email: String, password: String) async throws -> AuthResponse
>     func logout()
> }
>
> class AuthService: AuthServiceProtocol { ... }
> class MockAuthService: AuthServiceProtocol { ... }
> ```
>
> In production, inject `AuthService`. In tests, inject `MockAuthService`."

---

## 🎨 Design Pattern Questions

### Q14: What design patterns are used in your project?

**Answer:**

| Pattern | Where Used | Purpose |
|---------|------------|---------|
| **MVVM** | Entire app | Separation of concerns |
| **Singleton** | Services (AuthService.shared) | Single shared instance |
| **Repository** | Services | Abstract data source from ViewModels |
| **Observer** | @Published + Combine | Reactive UI updates |
| **Dependency Injection** | @EnvironmentObject | Provide dependencies to Views |
| **DTO (Data Transfer Object)** | Request models | Different shape than domain models |
| **Factory** | CodingKeys + custom init | Create objects from JSON |

---

### Q15: Explain the Observer pattern in your app

**Answer:**
> "The Observer pattern is implemented through Combine's property observation:
>
> **Observable (Subject):**
> ```swift
> class CartViewModel: ObservableObject {
>     @Published var items: [CartItem] = []  // This is observed
> }
> ```
>
> **Observer:**
> ```swift
> struct CartBadge: View {
>     @EnvironmentObject var cartViewModel: CartViewModel  // Subscribes
>     
>     var body: some View {
>         Text('\(cartViewModel.itemCount)')  // Automatically updates
>     }
> }
> ```
>
> When `items` changes:
> 1. `@Published` publishes a change notification via Combine
> 2. SwiftUI receives the notification
> 3. Views observing that ViewModel re-render
>
> This happens automatically - no manual subscription management needed."

---

### Q16: Why use Singleton pattern for services?

**Answer:**
> "Singleton pattern is used for services because:
>
> 1. **Shared State** - NetworkManager holds the auth token. Multiple instances would have inconsistent tokens.
>
> 2. **Resource Efficiency** - URLSession configuration is expensive. One instance is reused.
>
> 3. **Consistency** - All requests go through the same client with same headers.
>
> Implementation:
> ```swift
> class NetworkManager {
>     static let shared = NetworkManager()  // Single instance
>     private init() { }                     // Prevent external creation
> }
> ```
>
> Drawback: Singletons are hard to mock for testing. Solutions:
> - Use protocols
> - Inject the singleton instance rather than accessing directly"

---

## 🎯 Scenario-Based Questions

### Q17: Walk me through placing an order from start to finish

**Answer:**
> "Let me trace the complete order flow:
>
> **1. User browses products (HomeView)**
> - Products fetched via GET /products
> - Displayed in LazyVGrid
>
> **2. User taps 'Add' (ProductCard)**
> - `cartViewModel.addToCart(product)` called
> - CartItem added to local `items` array
> - Cart badge updates to show count
>
> **3. User goes to Cart (CartView)**
> - Displays all CartItems with quantities
> - Shows subtotal and total
>
> **4. User proceeds to Checkout (CheckoutView)**
> - Optional notes input
> - Optional pickup time
> - Order summary displayed
>
> **5. User taps 'Place Order'**
> - `cartViewModel.placeOrder(notes, pickupTime)` called
> - CartItems transformed to CreateOrderItemRequest array
> - POST /orders with items, notes, pickupTime
>
> **6. API creates order**
> - Calculates total, assigns status 'pending'
> - Returns Order object
>
> **7. Success state**
> - `orderPlaced = true` triggers success UI
> - `clearCart()` empties the items
> - User can view order in Orders tab
>
> **8. Staff sees order (AdminOrdersView)**
> - New order appears with 'pending' status
> - Staff advances through: pending → preparing → ready → pickedup → completed"

---

### Q18: How would you add a new feature (e.g., favorites)?

**Answer:**
> "I would follow the MVVM pattern:
>
> **1. Model Layer**
> ```swift
> struct Favorite: Codable, Identifiable {
>     let id: String
>     let productId: String
>     let product: Product?
> }
> ```
>
> **2. Service Layer**
> ```swift
> class FavoriteService {
>     static let shared = FavoriteService()
>     
>     func getFavorites() async throws -> [Favorite]
>     func addFavorite(productId: String) async throws
>     func removeFavorite(id: String) async throws
> }
> ```
>
> **3. ViewModel Layer**
> ```swift
> class FavoriteViewModel: ObservableObject {
>     @Published var favorites: [Favorite] = []
>     @Published var isLoading = false
>     
>     func loadFavorites() async { ... }
>     func toggleFavorite(product: Product) async { ... }
>     func isFavorite(_ product: Product) -> Bool { ... }
> }
> ```
>
> **4. View Layer**
> - Add heart icon to ProductCard
> - Create FavoritesView for favorites tab
> - Connect via @EnvironmentObject
>
> The structure mirrors existing features, maintaining consistency."

---

### Q19: What would you improve in this architecture?

**Answer:**
> "Several potential improvements:
>
> 1. **Dependency Injection Container**
>    - Currently using singletons directly
>    - Could use a DI container for better testability
>
> 2. **Cart Persistence**
>    - Cart is lost on app kill
>    - Could persist to UserDefaults or Core Data
>
> 3. **Offline Support**
>    - Cache products locally
>    - Queue orders when offline
>
> 4. **Push Notifications**
>    - Notify customers when order status changes
>    - Instead of manual refresh
>
> 5. **Error Retry**
>    - Add automatic retry for transient failures
>    - Currently single attempt only
>
> 6. **State Management**
>    - Could use Combine more extensively
>    - Or adopt third-party like TCA (The Composable Architecture)
>
> These are trade-offs between complexity and features for an academic project."

---

## 🗣 Quick Reference: What to Say

### For Architecture Questions:
> "MVVM with SwiftUI and Combine. Views observe ViewModels via @Published properties. Services abstract the API. Data flows unidirectionally."

### For Data Binding Questions:
> "@Published in ViewModels, @EnvironmentObject for injection, @StateObject for ownership. Combine handles the observation automatically."

### For Error Handling Questions:
> "Errors are caught at each layer. APIError enum provides typed errors. ViewModels expose errorMessage and showError for Views to display."

### For Testing Questions:
> "ViewModels are testable by mocking services via protocols. No UI required. Assert on state changes after async operations."

### For Design Pattern Questions:
> "Observer pattern via @Published, Singleton for services, Repository pattern for data abstraction, Dependency Injection via Environment."

---

## ✅ Final Preparation Checklist

- [ ] Can explain MVVM layers and their responsibilities
- [ ] Can trace data flow for any user action
- [ ] Can explain @Published, @StateObject, @EnvironmentObject
- [ ] Can describe error handling strategy
- [ ] Can discuss testing approach with mocks
- [ ] Can identify design patterns used
- [ ] Can walk through complete order flow
- [ ] Can suggest improvements to architecture
