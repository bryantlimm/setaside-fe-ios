# SetAside iOS - Project Overview

## 📱 Application Purpose
**SetAside** is a food pre-ordering mobile application for iOS. It allows customers to browse products, add them to a cart, place orders with optional pickup times, and track their order status. Staff members (admin/cashier) can manage products and orders through an admin interface.

## 🎯 Main Features/Screens

### Customer Features:
1. **Authentication** - Sign In / Sign Up
2. **Home** - Browse products by category, search functionality
3. **Product Details** - View product info, add to cart
4. **Cart** - Manage cart items, adjust quantities
5. **Checkout** - Place order with notes and pickup time
6. **Orders** - View order history and track status
7. **Profile** - View/edit user profile, logout

### Staff Features (Admin/Cashier):
1. **Admin Orders** - View all orders, update status (pending → preparing → ready → pickedup → completed)
2. **Admin Products** - Create, edit, delete products
3. **Profile** - Same as customer

---

## 🛠 Technology Stack

| Component | Technology |
|-----------|------------|
| **Language** | Swift 5.x |
| **UI Framework** | SwiftUI |
| **Reactive Library** | Combine (via `@Published`, `@StateObject`, `@EnvironmentObject`) |
| **Architecture** | MVVM (Model-View-ViewModel) |
| **Networking** | URLSession with async/await |
| **Local Storage** | UserDefaults (token storage) |
| **Dependency Injection** | Environment Objects |

---

## 📁 Project Structure

```
SetAside/
├── Core/
│   ├── Components/         # Reusable UI components
│   ├── Constants/          # AppConstants (baseURL, UserDefaults keys)
│   └── Extensions/         # Swift extensions
├── Models/
│   ├── User.swift          # User, AuthResponse, LoginRequest, RegisterRequest
│   ├── Product.swift       # Product, ProductsResponse, CreateProductRequest
│   ├── Order.swift         # Order, OrderItem, CreateOrderRequest
│   ├── CartItem.swift      # CartItem (local model)
│   └── APIError.swift      # Error handling
├── Services/
│   ├── NetworkManager.swift    # Base HTTP client
│   ├── AuthService.swift       # Authentication API
│   ├── ProductService.swift    # Product API
│   ├── OrderService.swift      # Order API
│   └── UserService.swift       # User profile API
├── ViewModels/
│   ├── AuthViewModel.swift         # Authentication state
│   ├── ProductViewModel.swift      # Product listing
│   ├── CartViewModel.swift         # Cart management
│   ├── OrderViewModel.swift        # Customer orders
│   ├── ProfileViewModel.swift      # User profile
│   ├── AdminProductViewModel.swift # Admin product management
│   └── AdminOrderViewModel.swift   # Admin order management
├── Views/
│   ├── Main/               # RootView, MainTabView
│   ├── Auth/               # SignInView, SignUpView
│   ├── Home/               # HomeView, ProductDetailView
│   ├── Cart/               # CartView, CheckoutView
│   ├── Orders/             # OrdersView, OrderDetailView
│   ├── Profile/            # ProfileView, EditProfileView
│   └── Admin/              # AdminOrdersView, AdminProductListView
└── SetAsideApp.swift       # App entry point
```

---

## 🔗 API Base URL
```
https://setaside.matthewswong.tech/api/v1
```

---

## 👥 User Roles
- **Customer** - Default role, can browse products and place orders
- **Admin/Cashier (Staff)** - Can manage products and process orders

---

## 🔐 Authentication
- JWT Bearer Token stored in UserDefaults
- Token attached to all authenticated requests via `Authorization: Bearer <token>`

---

## 📖 Documentation Index

| Document | Description |
|----------|-------------|
| [01_MVVM_ARCHITECTURE.md](./01_MVVM_ARCHITECTURE.md) | MVVM pattern explanation |
| [02_APP_LAUNCH_FLOW.md](./02_APP_LAUNCH_FLOW.md) | App startup and auth check |
| [03_USER_LOGIN_SCENARIO.md](./03_USER_LOGIN_SCENARIO.md) | Login data flow |
| [04_USER_REGISTRATION_SCENARIO.md](./04_USER_REGISTRATION_SCENARIO.md) | Registration data flow |
| [05_PRODUCT_LOADING_SCENARIO.md](./05_PRODUCT_LOADING_SCENARIO.md) | Product list loading |
| [06_ADD_TO_CART_SCENARIO.md](./06_ADD_TO_CART_SCENARIO.md) | Cart management |
| [07_PLACE_ORDER_SCENARIO.md](./07_PLACE_ORDER_SCENARIO.md) | Checkout and order creation |
| [08_ORDER_TRACKING_SCENARIO.md](./08_ORDER_TRACKING_SCENARIO.md) | Order status tracking |
| [09_ADMIN_ORDER_MANAGEMENT.md](./09_ADMIN_ORDER_MANAGEMENT.md) | Staff order processing |
| [10_EXAM_QUESTIONS.md](./10_EXAM_QUESTIONS.md) | Common exam Q&A |
