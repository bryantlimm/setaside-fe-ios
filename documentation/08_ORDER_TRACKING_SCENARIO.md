# Scenario: Order Tracking (Customer)

## 📋 Scenario Overview

**User Action**: Customer navigates to Orders tab to view their order history and status  
**Platform**: iOS (Swift/SwiftUI)  
**Expected Behavior**: Fetch orders from API, display status, allow viewing order details

---

## 🔄 Complete Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  USER TAPS "ORDERS" TAB                                                      │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  VIEW LAYER: OrdersView.swift                                                │
│                                                                              │
│  OrderViewModel.init() {                                                     │
│      Task {                                                                  │
│          await fetchOrders(refresh: true)                                    │
│      }                                                                       │
│  }                                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  VIEWMODEL LAYER: OrderViewModel.swift                                       │
│                                                                              │
│  func fetchOrders(refresh: Bool) async {                                     │
│      isLoading = true                                                        │
│      orders = try await orderService.getOrders(page, limit, status)          │
│  }                                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  SERVICE LAYER: OrderService.swift                                           │
│                                                                              │
│  func getOrders(page, limit, status) async throws -> [Order] {               │
│      GET /orders?page=1&limit=20                                             │
│      return response.allOrders                                               │
│  }                                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  UI DISPLAYS ORDER LIST                                                      │
│                                                                              │
│  • Order cards with status badges (Pending, Preparing, Ready)                │
│  • Tap order → OrderDetailView                                               │
│  • Pull to refresh                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 📍 Step-by-Step Code Flow

### STEP 1: VIEW LAYER - Orders Tab Initialization

**File**: `SetAside/Views/Orders/OrdersView.swift`

```swift
struct OrdersView: View {
    @StateObject private var orderViewModel = OrderViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var selectedOrder: Order?
    @State private var showOrderDetail: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if orderViewModel.isLoading && orderViewModel.orders.isEmpty {
                    // Loading state
                    ProgressView()
                } else if orderViewModel.orders.isEmpty {
                    // Empty state
                    EmptyStateView(
                        icon: "bag",
                        title: "No Orders Yet",
                        message: "Your orders will appear here"
                    )
                } else {
                    // Order list
                    orderListContent
                }
            }
            .navigationTitle("My Orders")
            .refreshable {
                await orderViewModel.fetchOrders(refresh: true)
            }
        }
    }
}
```

**What happens here:**
1. Creates `OrderViewModel` with `@StateObject` 
2. ViewModel's `init()` automatically fetches orders
3. View shows loading → orders list or empty state

---

### STEP 2: VIEWMODEL LAYER - Initialization and Fetch

**File**: `SetAside/ViewModels/OrderViewModel.swift` (Lines 10-80)

```swift
@MainActor
class OrderViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var selectedOrder: Order?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var selectedStatus: String?
    
    private let orderService = OrderService.shared
    private var currentPage = 1
    private var hasMoreOrders = true
    
    init() {
        Task {
            await fetchOrders(refresh: true)  // Auto-load on init
        }
    }
    
    func fetchOrders(refresh: Bool = false) async {
        guard !isLoading else { return }
        
        if refresh {
            currentPage = 1
            hasMoreOrders = true
        }
        
        guard hasMoreOrders else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedOrders = try await orderService.getOrders(
                page: currentPage,
                limit: 20,
                status: selectedStatus   // Optional status filter
            )
            
            #if DEBUG
            print("📋 Fetched \(fetchedOrders.count) orders")
            for order in fetchedOrders {
                print("📦 Order \(order.id.prefix(8)): \(order.items?.count ?? 0) items")
            }
            #endif
            
            if refresh {
                orders = fetchedOrders
            } else {
                orders.append(contentsOf: fetchedOrders)
            }
            
            hasMoreOrders = fetchedOrders.count == 20
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
}
```

---

### STEP 3: SERVICE LAYER - Get Orders API

**File**: `SetAside/Services/OrderService.swift` (Lines 36-49)

```swift
func getOrders(page: Int = 1, limit: Int = 20, status: String? = nil) async throws -> [Order] {
    var endpoint = "/orders?page=\(page)&limit=\(limit)"
    
    if let status = status {
        endpoint += "&status=\(status)"
    }
    
    let response: OrdersResponse = try await networkManager.request(
        endpoint: endpoint,
        method: "GET"
        // requiresAuth: true (default)
    )
    
    return response.allOrders
}
```

**HTTP Request:**
```
GET /api/v1/orders?page=1&limit=20
Authorization: Bearer <token>
```

---

### STEP 4: MODEL LAYER - Orders Response

**File**: `SetAside/Models/Order.swift` (Lines 180-192)

```swift
struct OrdersResponse: Codable {
    let data: [Order]?
    let orders: [Order]?
    let items: [Order]?
    let meta: OrdersMeta?
    let total: Int?
    let page: Int?
    let limit: Int?
    
    var allOrders: [Order] {
        return data ?? orders ?? items ?? []
    }
}
```

**API Response:**
```json
{
    "data": [
        {
            "id": "uuid-1",
            "status": "pending",
            "total_amount": 15.50,
            "notes": "Extra sugar",
            "pickup_time": "2024-12-19T10:30:00Z",
            "created_at": "2024-12-19T09:00:00Z",
            "items": [
                {
                    "id": "item-uuid-1",
                    "quantity": 2,
                    "unit_price": 4.50,
                    "product": {
                        "id": "prod-uuid-1",
                        "name": "Cappuccino",
                        "price": 4.50
                    }
                }
            ]
        }
    ],
    "total": 5,
    "page": 1,
    "limit": 20
}
```

---

### STEP 5: VIEW LAYER - Display Orders

```swift
private var orderListContent: some View {
    ScrollView {
        LazyVStack(spacing: 16) {
            ForEach(orderViewModel.orders) { order in
                OrderCard(order: order)
                    .onTapGesture {
                        selectedOrder = order
                        showOrderDetail = true
                    }
                    .onAppear {
                        orderViewModel.loadMoreIfNeeded(currentOrder: order)
                    }
            }
        }
        .padding()
    }
}
```

### Order Card Component

```swift
struct OrderCard: View {
    let order: Order
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Order ID + Status Badge
            HStack {
                Text("Order #\(order.id.prefix(8))...")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                OrderStatusBadge(status: order.status)
            }
            
            // Order date
            Text(order.formattedDate)
                .font(.caption)
                .foregroundColor(.gray)
            
            Divider()
            
            // Items summary
            if let items = order.items {
                ForEach(items.prefix(2)) { item in
                    HStack {
                        Text("\(item.quantity)x")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(item.displayName)
                            .font(.subheadline)
                        Spacer()
                        Text("$\(item.totalPrice, specifier: "%.2f")")
                            .font(.subheadline)
                    }
                }
                
                if items.count > 2 {
                    Text("+ \(items.count - 2) more items")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            // Total
            HStack {
                Text("Total")
                    .fontWeight(.semibold)
                Spacer()
                Text("$\(order.totalAmount ?? 0, specifier: "%.2f")")
                    .fontWeight(.bold)
                    .foregroundColor(.primaryGreen)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
}
```

---

## 🏷 Order Status Flow

### Status Values

```swift
// AppConstants.swift
enum OrderStatus: String, CaseIterable {
    case pending = "pending"       // Just placed
    case preparing = "preparing"   // Being made
    case ready = "ready"          // Ready for pickup
    case pickedUp = "pickedup"    // Customer picked up
    case completed = "completed"   // Finalized
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .preparing: return "Preparing"
        case .ready: return "Ready for Pickup"
        case .pickedUp: return "Picked Up"
        case .completed: return "Picked Up"
        }
    }
    
    var iconName: String {
        switch self {
        case .pending: return "clock.fill"
        case .preparing: return "flame.fill"
        case .ready: return "checkmark.circle.fill"
        case .pickedUp: return "bag.fill"
        case .completed: return "bag.fill"
        }
    }
}
```

### Status Flow Diagram

```
┌─────────┐    ┌───────────┐    ┌─────────┐    ┌──────────┐    ┌───────────┐
│ PENDING │ →  │ PREPARING │ →  │  READY  │ →  │ PICKEDUP │ →  │ COMPLETED │
│ 🕐      │    │ 🔥        │    │ ✓       │    │ 🛍        │    │ ✅        │
└─────────┘    └───────────┘    └─────────┘    └──────────┘    └───────────┘
    ↑
Customer places order

        Staff starts            Staff marks         Customer         Staff 
        preparing               as ready            picks up         completes
```

---

## 🔍 View Order Details

### Fetch Order Details

**File**: `SetAside/ViewModels/OrderViewModel.swift` (Lines 82-97)

```swift
func fetchOrderDetails(orderId: String) async {
    isLoading = true
    errorMessage = nil
    
    do {
        selectedOrder = try await orderService.getOrder(id: orderId)
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

**API Call:**
```
GET /api/v1/orders/{orderId}
Authorization: Bearer <token>
```

### Order Detail View

```swift
struct OrderDetailView: View {
    let order: Order
    @StateObject private var orderViewModel = OrderViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Status Section
                statusSection
                
                // Order Info
                orderInfoSection
                
                // Items List
                itemsSection
                
                // Price Summary
                priceSummarySection
                
                // Pickup Time (if set)
                if let pickupTime = order.pickupTime {
                    pickupTimeSection
                }
                
                // Notes (if any)
                if let notes = order.notes, !notes.isEmpty {
                    notesSection
                }
            }
            .padding()
        }
        .navigationTitle("Order Details")
    }
    
    private var statusSection: some View {
        VStack(alignment: .center, spacing: 16) {
            // Status icon
            Image(systemName: order.statusEnum.iconName)
                .font(.system(size: 60))
                .foregroundColor(statusColor)
            
            // Status text
            Text(order.statusEnum.displayName)
                .font(.title2)
                .fontWeight(.bold)
            
            // Status description
            Text(statusDescription)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.lightGreen.opacity(0.3))
        .cornerRadius(16)
    }
}
```

---

## 🔄 Status Filter

### Filter by Status

**File**: `SetAside/ViewModels/OrderViewModel.swift` (Lines 99-104)

```swift
func filterByStatus(_ status: String?) {
    selectedStatus = status
    Task {
        await fetchOrders(refresh: true)
    }
}
```

### View Implementation

```swift
// Filter chips in OrdersView
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 8) {
        // All orders
        StatusFilterChip(
            title: "All",
            isSelected: orderViewModel.selectedStatus == nil,
            action: { orderViewModel.filterByStatus(nil) }
        )
        
        // Status filters
        ForEach(["pending", "preparing", "ready", "pickedup"], id: \.self) { status in
            StatusFilterChip(
                title: status.capitalized,
                isSelected: orderViewModel.selectedStatus == status,
                action: { orderViewModel.filterByStatus(status) }
            )
        }
    }
}
```

---

## ↻ Pull-to-Refresh

```swift
.refreshable {
    await orderViewModel.fetchOrders(refresh: true)
}
```

**What happens:**
1. User pulls down on orders list
2. SwiftUI shows refresh indicator
3. `fetchOrders(refresh: true)` resets page and fetches fresh data
4. View re-renders with updated orders

---

## 📊 Computed Order Properties

**File**: `SetAside/ViewModels/OrderViewModel.swift` (Lines 171-191)

```swift
// Filter orders by status (computed)
var pendingOrders: [Order] {
    orders.filter { $0.status == "pending" }
}

var preparingOrders: [Order] {
    orders.filter { $0.status == "preparing" }
}

var readyOrders: [Order] {
    orders.filter { $0.status == "ready" }
}

var completedOrders: [Order] {
    orders.filter { $0.status == "pickedup" }
}

var activeOrders: [Order] {
    orders.filter { $0.status != "pickedup" }
}
```

---

## 🗂 State Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    ORDER TRACKING STATES                        │
└─────────────────────────────────────────────────────────────────┘

     ┌─────────────┐
     │   LOADING   │
     │ orders=[]   │
     │ isLoading=T │
     └──────┬──────┘
            │
     ┌──────┴──────┐
     │             │
     ▼             ▼
┌─────────┐   ┌─────────┐
│ HAS     │   │  EMPTY  │
│ ORDERS  │   │  STATE  │
│ orders= │   │ orders= │
│ [....]  │   │ []      │
└────┬────┘   └─────────┘
     │
     │ tap order
     ▼
┌─────────────┐
│   DETAIL    │
│   VIEW      │
│selectedOrder│
│  = Order    │
└─────────────┘
     │
     │ back button
     ▼
┌─────────────┐
│   LIST      │
│   VIEW      │
└─────────────┘
```

---

## ❓ Key Points for Exam

### Q: Why use @StateObject in OrdersView instead of @EnvironmentObject?
> OrdersView owns its OrderViewModel - it creates and manages its lifecycle. Unlike CartViewModel (shared across app), OrderViewModel is specific to this screen.

### Q: How does the customer know when their order is ready?
> They manually pull-to-refresh the orders list. A production app might add push notifications for status changes.

### Q: What's the difference between selectedOrder and orders array?
> `orders` is the list for the main view. `selectedOrder` stores the specific order being viewed in detail (after tapping). This separation keeps the UI logic clean.

### Q: Why does Order have computed properties like statusEnum?
> API returns status as a String. `statusEnum` converts it to the enum for type-safety and to access computed properties like `displayName` and `iconName`.

---

## 🗣 What to Say During Exam

> "The customer order tracking follows the same MVVM pattern. OrdersView creates an OrderViewModel which auto-fetches orders on init. The view displays order cards with status badges. Tapping an order navigates to OrderDetailView with the full order info. The status is stored as a String in the API response but converted to an enum using a computed property for type-safety. Pull-to-refresh calls fetchOrders with refresh=true to reset pagination and get the latest data."

---

## ⏱ Timing Estimates

| Operation | Duration |
|-----------|----------|
| ViewModel init | ~1ms |
| API call (orders) | ~200-400ms |
| UI rendering | ~50ms |
| Fetch order details | ~200-400ms |
| Pull-to-refresh | ~200-400ms |
