# SetAside iOS - MVVM Architecture Documentation

## 📖 Overview

This documentation provides comprehensive, scenario-based explanations of the MVVM architecture implementation in the SetAside iOS app. It's designed to help you confidently explain code flows during your oral exam.

---

## 📁 Documentation Files

| File | Description | Key Topics |
|------|-------------|------------|
| [00_PROJECT_OVERVIEW.md](./00_PROJECT_OVERVIEW.md) | Application overview, features, tech stack | Project structure, features, API |
| [01_MVVM_ARCHITECTURE.md](./01_MVVM_ARCHITECTURE.md) | MVVM pattern explanation | Layers, data flow, binding |
| [02_APP_LAUNCH_FLOW.md](./02_APP_LAUNCH_FLOW.md) | App startup and auth check | Entry point, token check, navigation |
| [03_USER_LOGIN_SCENARIO.md](./03_USER_LOGIN_SCENARIO.md) | User login flow | Auth, JWT token, state updates |
| [04_USER_REGISTRATION_SCENARIO.md](./04_USER_REGISTRATION_SCENARIO.md) | User registration flow | Form validation, custom encoding |
| [05_PRODUCT_LOADING_SCENARIO.md](./05_PRODUCT_LOADING_SCENARIO.md) | Product list loading | API calls, pagination, filtering |
| [06_ADD_TO_CART_SCENARIO.md](./06_ADD_TO_CART_SCENARIO.md) | Cart management | Local state, no API calls |
| [07_PLACE_ORDER_SCENARIO.md](./07_PLACE_ORDER_SCENARIO.md) | Checkout and order creation | Data transformation, API request |
| [08_ORDER_TRACKING_SCENARIO.md](./08_ORDER_TRACKING_SCENARIO.md) | Customer order tracking | Status display, pull-to-refresh |
| [09_ADMIN_ORDER_MANAGEMENT.md](./09_ADMIN_ORDER_MANAGEMENT.md) | Staff order processing | Status workflow, PATCH updates |
| [10_EXAM_QUESTIONS.md](./10_EXAM_QUESTIONS.md) | Common Q&A for exam prep | Architecture, patterns, testing |

---

## 🔑 Quick Reference

### MVVM Layers

```
VIEW          →  ViewModel Methods  →  SERVICE       →  NETWORK       →  API
(SwiftUI)     ←  @Published State   ←  (Singleton)   ←  (HTTP Client) ←  Response
```

### Key Property Wrappers

| Wrapper | Purpose | Example |
|---------|---------|---------|
| `@Published` | Observable property in ViewModel | `@Published var products: [Product] = []` |
| `@StateObject` | Create and own ViewModel | `@StateObject private var vm = ProductViewModel()` |
| `@EnvironmentObject` | Access shared ViewModel | `@EnvironmentObject var cartViewModel: CartViewModel` |
| `@State` | View-local state | `@State private var email = ""` |
| `@Binding` | Two-way parent-child binding | `@Binding var hideTabBar: Bool` |

### Design Patterns Used

| Pattern | Implementation |
|---------|----------------|
| **MVVM** | View ↔ ViewModel ↔ Service ↔ Network |
| **Singleton** | `AuthService.shared`, `NetworkManager.shared` |
| **Observer** | `@Published` + Combine |
| **Repository** | Services abstract API from ViewModels |
| **Dependency Injection** | `@EnvironmentObject` |
| **DTO** | Request models differ from domain models |

---

## 🗺️ Data Flow Maps

### Authentication Flow
```
SignInView → AuthViewModel.login() → AuthService.login() 
           → NetworkManager.request() → POST /auth/login
           → Save token → isLoggedIn = true → MainTabView
```

### Product Loading Flow
```
HomeView → ProductViewModel.init() → ProductService.getProducts() 
         → GET /products → Decode → products = [...] → LazyVGrid renders
```

### Order Creation Flow
```
CheckoutView → CartViewModel.placeOrder() → Transform CartItems 
             → OrderService.createOrder() → POST /orders 
             → clearCart() → orderPlaced = true → Success UI
```

### Admin Status Update Flow
```
AdminOrderCard → updateOrderStatus(orderId, "preparing") 
              → OrderService.updateOrderStatus() → PATCH /orders/{id}/status 
              → loadAllOrders() → UI updates
```

---

## 📝 Exam Preparation Tips

### Before the Exam
1. ✅ Read through each scenario document
2. ✅ Practice explaining the flow out loud
3. ✅ Review the class diagrams
4. ✅ Memorize the key property wrappers
5. ✅ Prepare answers to common questions

### During the Exam
1. 🎯 Start with high-level overview, then dive into details
2. 🎯 Use terms like "View Layer", "ViewModel Layer", "Service Layer"
3. 🎯 Mention design patterns when relevant
4. 🎯 Explain WHY, not just WHAT
5. 🎯 Draw diagrams if asked about architecture

### Key Phrases to Use
- "Data flows unidirectionally..."
- "The View observes the ViewModel through @Published..."
- "The Service abstracts the API details..."
- "This follows the Observer pattern..."
- "The state change triggers SwiftUI to re-render..."

---

## 🏗️ Project Structure Summary

```
SetAside/
├── SetAsideApp.swift          # Entry point, DI setup
├── Models/
│   ├── User.swift             # User, auth models
│   ├── Product.swift          # Product models
│   ├── Order.swift            # Order, OrderItem models
│   ├── CartItem.swift         # Local cart model
│   └── APIError.swift         # Error handling
├── Services/
│   ├── NetworkManager.swift   # HTTP client
│   ├── AuthService.swift      # Auth API
│   ├── ProductService.swift   # Products API
│   ├── OrderService.swift     # Orders API
│   └── UserService.swift      # User API
├── ViewModels/
│   ├── AuthViewModel.swift    # Auth state
│   ├── ProductViewModel.swift # Product list
│   ├── CartViewModel.swift    # Cart + checkout
│   ├── OrderViewModel.swift   # Customer orders
│   ├── ProfileViewModel.swift # User profile
│   ├── AdminProductViewModel.swift
│   └── AdminOrderViewModel.swift
└── Views/
    ├── Main/                  # RootView, MainTabView
    ├── Auth/                  # SignIn, SignUp
    ├── Home/                  # Home, ProductDetail
    ├── Cart/                  # Cart, Checkout
    ├── Orders/                # Orders, OrderDetail
    ├── Profile/               # Profile, EditProfile
    └── Admin/                 # AdminOrders, AdminProducts
```

---

## ✨ Good Luck on Your Exam!

Remember: The examiner wants to see that you **understand** the architecture, not just memorize it. Focus on explaining the **why** behind each decision.
