# Scenario: Admin Order Management

## 📋 Scenario Overview

**User Action**: Staff (admin/cashier) views all orders and updates their status  
**Platform**: iOS (Swift/SwiftUI)  
**Expected Behavior**: View all orders, update status through workflow (pending → preparing → ready → pickedup → completed)

---

## 🔄 Complete Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  STAFF USER OPENS APP → MainTabView detects isStaff = true                   │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  VIEW LAYER: AdminOrdersView.swift                                           │
│                                                                              │
│  Shows different tabs: "Active" / "Completed"                                │
│  Each order card has action button to advance status                         │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  VIEWMODEL LAYER: AdminOrderViewModel.swift                                  │
│                                                                              │
│  func loadAllOrders() async                                                  │
│  func updateOrderStatus(orderId, newStatus) async                            │
│  func getNextStatus(currentStatus) -> String?                                │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  SERVICE LAYER: OrderService.swift                                           │
│                                                                              │
│  func getAllOrders() async throws -> [Order]                                 │
│  func updateOrderStatus(id, status) async throws -> Order                    │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  NETWORK CALLS                                                               │
│                                                                              │
│  GET /orders?limit=1000     (get all orders)                                 │
│  PATCH /orders/{id}/status  (update status)                                  │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔐 Staff Role Detection

**File**: `SetAside/Views/Main/MainTabView.swift` (Lines 16-20)

```swift
// Check if user is admin or cashier (staff)
private var isStaff: Bool {
    guard let role = authViewModel.currentUser?.role else { return false }
    return role == "admin" || role == "cashier"
}
```

**Tab Layout:**
```swift
if isStaff {
    // Staff tabs: Orders, Products, Profile
    switch selectedTab {
    case 0: AdminOrdersView()
    case 1: AdminProductListView()
    case 2: ProfileView()
    default: AdminOrdersView()
    }
} else {
    // Customer tabs: Home, Orders, Profile
    switch selectedTab {
    case 0: HomeView()
    case 1: OrdersView()
    case 2: ProfileView()
    default: HomeView()
    }
}
```

---

## 📍 Step-by-Step Code Flow

### STEP 1: VIEWMODEL INITIALIZATION

**File**: `SetAside/ViewModels/AdminOrderViewModel.swift` (Lines 9-52)

```swift
@MainActor
class AdminOrderViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var selectedStatus: String = "all"
    @Published var showCompletionModal = false
    @Published var completedOrderId: String?
    
    // Full 5-stage flow
    let orderStatuses = ["pending", "preparing", "ready", "pickedup", "completed"]
    
    private let orderService = OrderService.shared
    
    // Computed filtered orders
    var filteredOrders: [Order] {
        if selectedStatus == "all" {
            return orders.filter { $0.status != "completed" }  // Active only
        }
        if selectedStatus == "completed" {
            return orders.filter { $0.status == "completed" }
        }
        return orders.filter { $0.status == selectedStatus }
    }
    
    // Status-specific computed properties
    var pendingOrders: [Order] {
        orders.filter { $0.status == "pending" }
    }
    
    var preparingOrders: [Order] {
        orders.filter { $0.status == "preparing" }
    }
    
    var readyOrders: [Order] {
        orders.filter { $0.status == "ready" }
    }
    
    var pickedUpOrders: [Order] {
        orders.filter { $0.status == "pickedup" }
    }
    
    var completedOrders: [Order] {
        orders.filter { $0.status == "completed" }
    }
}
```

---

### STEP 2: LOAD ALL ORDERS

**File**: `SetAside/ViewModels/AdminOrderViewModel.swift` (Lines 54-90)

```swift
func loadAllOrders() async {
    isLoading = true
    errorMessage = nil
    
    do {
        orders = try await orderService.getAllOrders()
        
        #if DEBUG
        print("📋 Loaded \(orders.count) orders")
        for order in orders {
            print("📦 Order \(order.id.prefix(8)): \(order.items?.count ?? 0) items")
        }
        #endif
        
        // Sort by created date, newest first
        orders.sort { ($0.createdAt ?? "") > ($1.createdAt ?? "") }
        
    } catch let error as APIError {
        errorMessage = error.localizedDescription
    } catch {
        errorMessage = error.localizedDescription
    }
    
    isLoading = false
}
```

**Service Layer:**

**File**: `SetAside/Services/OrderService.swift` (Lines 51-69)

```swift
func getAllOrders(page: Int = 1, limit: Int = 1000) async throws -> [Order] {
    let endpoint = "/orders?page=\(page)&limit=\(limit)"
    
    #if DEBUG
    print("🔍 Fetching all orders: \(endpoint)")
    #endif
    
    let response: OrdersResponse = try await networkManager.request(
        endpoint: endpoint,
        method: "GET"
    )
    
    return response.allOrders
}
```

**Note**: Staff sees ALL orders, not just their own. The API returns all orders when called by admin/cashier role.

---

### STEP 3: STATUS WORKFLOW LOGIC

**File**: `SetAside/ViewModels/AdminOrderViewModel.swift` (Lines 114-151)

```swift
func getNextStatus(currentStatus: String) -> String? {
    switch currentStatus {
    case "pending": return "preparing"      // Start Preparing
    case "preparing": return "ready"        // Order is Ready
    case "ready": return "pickedup"        // Customer Picked Up
    case "pickedup": return "completed"    // Complete Order
    default: return nil                     // completed is final
    }
}

func getButtonLabel(for status: String) -> String {
    switch status {
    case "pending": return "Start Preparing"
    case "preparing": return "Order is Ready"
    case "ready": return "Customer Picked Up"
    case "pickedup": return "Complete Order"
    default: return ""
    }
}

func getButtonIcon(for status: String) -> String {
    switch status {
    case "pending": return "flame.fill"
    case "preparing": return "checkmark.circle.fill"
    case "ready": return "bag.fill"
    case "pickedup": return "checkmark.seal.fill"
    default: return "checkmark"
    }
}

func getButtonColor(for status: String) -> String {
    switch status {
    case "pending": return "orange"
    case "preparing": return "blue"
    case "ready": return "purple"
    case "pickedup": return "green"
    default: return "gray"
    }
}
```

### Status Flow Visualization

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ORDER STATUS WORKFLOW                                │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ PENDING  │────▶│PREPARING │────▶│  READY   │────▶│ PICKEDUP │────▶│COMPLETED │
│          │     │          │     │          │     │          │     │          │
│ 🟠 Orange│     │ 🔵 Blue  │     │ 🟣 Purple│     │ 🟢 Green │     │ ⚪ Gray  │
│          │     │          │     │          │     │          │     │          │
│ [Start   │     │ [Order   │     │ [Customer│     │ [Complete│     │  (Final) │
│ Preparing│     │ is Ready]│     │ Picked Up│     │  Order]  │     │          │
└──────────┘     └──────────┘     └──────────┘     └──────────┘     └──────────┘
     ↑                ↑                 ↑               ↑
     │                │                 │               │
   Staff          Staff             Staff           Staff
   taps           taps              taps            taps
   button         button            button          button
```

---

### STEP 4: UPDATE ORDER STATUS

**File**: `SetAside/ViewModels/AdminOrderViewModel.swift` (Lines 92-112)

```swift
func updateOrderStatus(orderId: String, newStatus: String) async -> Bool {
    isLoading = true
    errorMessage = nil
    successMessage = nil
    
    do {
        let _ = try await orderService.updateOrderStatus(id: orderId, status: newStatus)
        successMessage = "Order status updated to \(newStatus)"
        await loadAllOrders()  // Refresh list
        isLoading = false
        return true
    } catch let error as APIError {
        errorMessage = error.localizedDescription
        isLoading = false
        return false
    } catch {
        errorMessage = error.localizedDescription
        isLoading = false
        return false
    }
}
```

**Service Layer:**

**File**: `SetAside/Services/OrderService.swift` (Lines 119-128)

```swift
func updateOrderStatus(id: String, status: String) async throws -> Order {
    let request = UpdateOrderStatusRequest(status: status)
    
    return try await networkManager.request(
        endpoint: "/orders/\(id)/status",
        method: "PATCH",
        body: request
    )
}
```

**Request Model:**

```swift
struct UpdateOrderStatusRequest: Codable {
    let status: String
}
```

**HTTP Request:**
```
PATCH /api/v1/orders/{orderId}/status
Authorization: Bearer <token>
Content-Type: application/json

{
    "status": "preparing"
}
```

---

### STEP 5: VIEW LAYER - Admin Orders UI

**File**: `SetAside/Views/Admin/AdminOrdersView.swift`

```swift
struct AdminOrdersView: View {
    @StateObject private var viewModel = AdminOrderViewModel()
    
    @State private var selectedTab: Int = 0  // 0=Active, 1=Completed
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Selector: Active / Completed
                Picker("Order Type", selection: $selectedTab) {
                    Text("Active (\(viewModel.orders.filter { $0.status != "completed" }.count))")
                        .tag(0)
                    Text("Completed (\(viewModel.completedOrders.count))")
                        .tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Status Filter (for Active tab)
                if selectedTab == 0 {
                    statusFilterSection
                }
                
                // Order List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredOrders) { order in
                            AdminOrderCard(order: order, viewModel: viewModel)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Orders")
            .task {
                await viewModel.loadAllOrders()
            }
            .refreshable {
                await viewModel.loadAllOrders()
            }
        }
    }
}
```

---

### STEP 6: ORDER ACTION CARD

```swift
struct AdminOrderCard: View {
    let order: Order
    @ObservedObject var viewModel: AdminOrderViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Order ID + Status
            HStack {
                Text("Order #\(order.id.prefix(8))...")
                    .font(.headline)
                
                Spacer()
                
                // Status Badge
                Text(order.status.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            // Customer info
            if let customer = order.customer {
                HStack {
                    Image(systemName: "person.fill")
                    Text(customer.fullName)
                }
                .font(.subheadline)
                .foregroundColor(.gray)
            }
            
            // Order items
            if let items = order.items {
                ForEach(items) { item in
                    HStack {
                        Text("\(item.quantity)x")
                            .foregroundColor(.gray)
                        Text(item.displayName)
                        Spacer()
                        Text("$\(item.totalPrice, specifier: "%.2f")")
                    }
                    .font(.subheadline)
                }
            }
            
            Divider()
            
            // Total + Action Button
            HStack {
                VStack(alignment: .leading) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$\(order.totalAmount ?? 0, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                // ACTION BUTTON - Advance to next status
                if let nextStatus = viewModel.getNextStatus(currentStatus: order.status) {
                    Button(action: {
                        Task {
                            await viewModel.updateOrderStatus(
                                orderId: order.id,
                                newStatus: nextStatus
                            )
                        }
                    }) {
                        HStack {
                            Image(systemName: viewModel.getButtonIcon(for: order.status))
                            Text(viewModel.getButtonLabel(for: order.status))
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(buttonColor)
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
    
    var buttonColor: Color {
        switch order.status {
        case "pending": return .orange
        case "preparing": return .blue
        case "ready": return .purple
        case "pickedup": return .green
        default: return .gray
        }
    }
}
```

---

## 🔀 Complete Flow: Update Status

```
Staff views order card with status "pending"
       │
       ▼ taps "Start Preparing" button
┌──────────────────────────────────────────────────────────────────┐
│ Button Action triggers Task {                                    │
│     await viewModel.updateOrderStatus(orderId, "preparing")     │
│ }                                                                │
└──────────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ AdminOrderViewModel.updateOrderStatus()                          │
│    isLoading = true                                              │
│    try await orderService.updateOrderStatus(id, status)          │
└──────────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ OrderService.updateOrderStatus()                                 │
│    PATCH /orders/{id}/status                                     │
│    Body: { "status": "preparing" }                               │
└──────────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ API Response: Order object with updated status                   │
└──────────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ AdminOrderViewModel:                                             │
│    successMessage = "Order status updated to preparing"          │
│    await loadAllOrders()  // Refresh list                        │
│    isLoading = false                                             │
└──────────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ UI Updates:                                                      │
│    - Order card now shows "PREPARING" badge                      │
│    - Button changes to "Order is Ready" (blue)                   │
│    - Order may move to different filter section                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 🎉 Order Completion Modal

**File**: `SetAside/ViewModels/AdminOrderViewModel.swift` (Lines 168-190)

```swift
func markOrderCompleted(orderId: String) async -> Bool {
    isLoading = true
    
    do {
        let _ = try await orderService.updateOrderStatus(id: orderId, status: "completed")
        completedOrderId = orderId
        showCompletionModal = true    // Trigger celebration modal
        await loadAllOrders()
        isLoading = false
        return true
    } catch {
        errorMessage = "Failed to complete order"
        isLoading = false
        return false
    }
}

func dismissCompletionModal() {
    showCompletionModal = false
    completedOrderId = nil
}
```

**Modal UI:**
```swift
.sheet(isPresented: $viewModel.showCompletionModal) {
    VStack(spacing: 24) {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 80))
            .foregroundColor(.green)
        
        Text("Order Completed!")
            .font(.title)
            .fontWeight(.bold)
        
        Text("Order #\(viewModel.completedOrderId?.prefix(8) ?? "")... has been successfully completed.")
            .multilineTextAlignment(.center)
            .foregroundColor(.gray)
        
        Button("Done") {
            viewModel.dismissCompletionModal()
        }
        .buttonStyle(.borderedProminent)
    }
    .padding(32)
}
```

---

## 🗂 State Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    ADMIN ORDER MANAGEMENT                       │
└─────────────────────────────────────────────────────────────────┘

     ┌─────────────┐
     │   LOADING   │
     │ orders=[]   │
     └──────┬──────┘
            │
            ▼
     ┌─────────────┐
     │   LOADED    │
     │ orders=[...]│
     │ Grouped by  │
     │ status      │
     └──────┬──────┘
            │
            │ tap action button
            ▼
     ┌─────────────┐
     │  UPDATING   │
     │ isLoading=T │
     └──────┬──────┘
            │
     ┌──────┴──────┐
     │             │
     ▼             ▼
┌─────────┐   ┌─────────┐
│ SUCCESS │   │  ERROR  │
│ refresh │   │ show    │
│ list    │   │ message │
└─────────┘   └─────────┘
     │
     │ if status = "completed"
     ▼
┌─────────────┐
│ COMPLETION  │
│   MODAL     │
└─────────────┘
```

---

## ❓ Key Points for Exam

### Q: How does the app know the user is staff?
> After login, `AuthViewModel.currentUser.role` contains "admin" or "cashier". `MainTabView` checks `isStaff` computed property to show different tab layouts.

### Q: Why use computed properties for filtered orders?
> Computed properties like `pendingOrders` automatically update when the `orders` array changes. No need for manual synchronization.

### Q: What's the status workflow?
> pending → preparing → ready → pickedup → completed. Each stage has a specific action button that advances to the next status.

### Q: Why refresh the entire list after status update?
> To ensure consistency. Other orders might have been updated by other staff members. A single order update is also returned, but full refresh is safer.

### Q: What design patterns are used?
> - **State Machine**: Order status follows defined transitions
> - **Strategy**: Different button labels/colors per status
> - **Observer**: @Published for reactive UI updates

---

## 🗣 What to Say During Exam

> "The admin order management system detects staff roles through the user object after login. Staff see a different tab layout with AdminOrdersView. Orders flow through five statuses: pending, preparing, ready, pickedup, and completed. Each order card has an action button that advances to the next status. The ViewModel provides helper methods like getNextStatus() and getButtonLabel() that return the appropriate values for each status. When staff taps the button, we PATCH the order status to the API, then refresh the entire order list to ensure consistency."

---

## ⏱ Timing Estimates

| Operation | Duration |
|-----------|----------|
| Load all orders | ~300-600ms |
| Update status | ~200-400ms |
| Refresh after update | ~300-600ms |
| UI re-render | ~50ms |
| **Total (status update)** | **~500-1000ms** |
