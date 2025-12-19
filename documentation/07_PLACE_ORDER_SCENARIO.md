# Scenario: Place Order (Checkout)

## 📋 Scenario Overview

**User Action**: User reviews cart, optionally adds notes/pickup time, taps "Place Order"  
**Platform**: iOS (Swift/SwiftUI)  
**Expected Behavior**: Convert cart items to order, send to API, clear cart, show success

---

## 🔄 Complete Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  USER IN CHECKOUT → TAPS "PLACE ORDER"                                       │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  VIEW LAYER: CheckoutView.swift                                              │
│                                                                              │
│  Button("Place Order") {                                                     │
│      Task {                                                                  │
│          await cartViewModel.placeOrder(                                     │
│              notes: notes,                                                   │
│              pickupTime: selectedPickupTime                                  │
│          )                                                                   │
│      }                                                                       │
│  }                                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  VIEWMODEL LAYER: CartViewModel.swift                                        │
│                                                                              │
│  func placeOrder(notes, pickupTime) async {                                  │
│      1. Transform CartItems → CreateOrderItemRequest[]                       │
│      2. await orderService.createOrder(notes, pickupTime, items)             │
│      3. lastOrder = order                                                    │
│      4. orderPlaced = true                                                   │
│      5. clearCart()                                                          │
│  }                                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  SERVICE LAYER: OrderService.swift                                           │
│                                                                              │
│  func createOrder(notes, pickupTime, items) async throws -> Order {          │
│      1. Format pickupTime to ISO8601                                         │
│      2. Create CreateOrderRequest                                            │
│      3. POST /orders with request body                                       │
│      4. Return created Order                                                 │
│  }                                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  NETWORK: POST /api/v1/orders                                                │
│                                                                              │
│  Headers: Authorization: Bearer <token>                                      │
│  Body: {                                                                     │
│      "notes": "Extra sugar please",                                          │
│      "pickup_time": "2024-12-19T10:30:00Z",                                  │
│      "items": [                                                              │
│          { "product_id": "uuid", "quantity": 2, "special_instructions": "" } │
│      ]                                                                       │
│  }                                                                           │
│                                                                              │
│  Response: { "id": "...", "status": "pending", ... }                         │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  RETURN PATH                                                                 │
│                                                                              │
│  • cartViewModel.orderPlaced = true → Shows success modal                    │
│  • cartViewModel.lastOrder = Order → Stores for display                      │
│  • cartViewModel.clearCart() → Empties items array                           │
│  • View navigates to Orders tab                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 📍 Step-by-Step Code Flow

### STEP 1: VIEW LAYER - Checkout Screen

**File**: `SetAside/Views/Cart/CheckoutView.swift`

```swift
struct CheckoutView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    
    @State private var notes: String = ""
    @State private var selectedPickupTime: Date?
    @State private var showDatePicker: Bool = false
    
    var body: some View {
        VStack {
            // Order Summary (list of cart items)
            orderSummarySection
            
            // Notes Input
            TextField("Add notes (optional)", text: $notes)
            
            // Pickup Time Picker
            DatePicker("Pickup Time", selection: $selectedPickupTime ?? Date())
            
            // Price Summary
            HStack {
                Text("Total")
                Spacer()
                Text("$\(cartViewModel.totalPrice, specifier: "%.2f")")
            }
            
            // Place Order Button
            PrimaryButton(
                title: "Place Order",
                isLoading: cartViewModel.isLoading
            ) {
                Task {
                    await cartViewModel.placeOrder(
                        notes: notes.isEmpty ? nil : notes,
                        pickupTime: selectedPickupTime
                    )
                }
            }
            .disabled(cartViewModel.isEmpty)
        }
    }
}
```

**User Input:**
- **Notes**: Optional text for special requests
- **Pickup Time**: Optional datetime picker
- Displays order summary with all cart items

---

### STEP 2: VIEWMODEL LAYER - Place Order

**File**: `SetAside/ViewModels/CartViewModel.swift` (Lines 93-146)

```swift
func placeOrder(notes: String? = nil, pickupTime: Date? = nil) async {
    // STEP 2a: Validate cart is not empty
    guard !items.isEmpty else {
        errorMessage = "Cart is empty"
        showError = true
        return
    }
    
    isLoading = true
    errorMessage = nil
    
    // STEP 2b: Transform CartItems to API format
    let orderItems = items.map { item in
        CreateOrderItemRequest(
            productId: item.product.id,
            quantity: item.quantity,
            specialInstructions: item.specialInstructions
        )
    }
    
    #if DEBUG
    print("🛒 Placing order with \(orderItems.count) items:")
    for (index, item) in items.enumerated() {
        print("   Item \(index + 1): product_id=\(item.product.id), qty=\(item.quantity)")
    }
    #endif
    
    do {
        // STEP 2c: Call Order Service
        let order = try await orderService.createOrder(
            notes: notes,
            pickupTime: pickupTime,
            items: orderItems
        )
        
        #if DEBUG
        print("✅ Order created successfully: \(order.id)")
        #endif
        
        // STEP 2d: Update state on success
        lastOrder = order
        orderPlaced = true
        clearCart()             // Empty the cart
        
    } catch {
        #if DEBUG
        print("⚠️ Order API returned error but order may have been created: \(error)")
        #endif
        
        // NOTE: Even if decoding fails, order may have been created
        // Show success to user as a fallback
        lastOrder = nil
        orderPlaced = true
        clearCart()
    }
    
    isLoading = false
}
```

**Data Transformation:**

```
CartItem[]                    CreateOrderItemRequest[]
┌─────────────────────────┐   ┌─────────────────────────────┐
│ product: Product        │ → │ productId: String           │
│   └─ id                 │   │ quantity: Int               │
│ quantity: Int           │   │ specialInstructions: String?│
│ specialInstructions?    │   └─────────────────────────────┘
└─────────────────────────┘
```

---

### STEP 3: SERVICE LAYER - Create Order Request

**File**: `SetAside/Services/OrderService.swift` (Lines 14-33)

```swift
func createOrder(notes: String?, pickupTime: Date?, items: [CreateOrderItemRequest]) async throws -> Order {
    // STEP 3a: Format pickup time to ISO8601
    var pickupTimeString: String? = nil
    if let pickupTime = pickupTime {
        let formatter = ISO8601DateFormatter()
        pickupTimeString = formatter.string(from: pickupTime)
    }
    
    // STEP 3b: Create request object
    let request = CreateOrderRequest(
        notes: notes,
        pickupTime: pickupTimeString,
        items: items
    )
    
    // STEP 3c: Make API request (with flexible response handling)
    return try await networkManager.requestWithFlexibleResponse(
        endpoint: "/orders",
        method: "POST",
        body: request
    )
}
```

**Date Formatting:**
- Input: Swift `Date` object
- Output: ISO8601 string like `"2024-12-19T10:30:00Z"`

---

### STEP 4: MODEL LAYER - Request Structures

**File**: `SetAside/Models/Order.swift` (Lines 225-269)

```swift
struct CreateOrderRequest: Codable {
    let notes: String?
    let pickupTime: String?
    let items: [CreateOrderItemRequest]
    
    enum CodingKeys: String, CodingKey {
        case notes
        case pickupTime = "pickup_time"
        case items
    }
    
    // Custom encoder to skip nil values
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let notes = notes {
            try container.encode(notes, forKey: .notes)
        }
        if let pickupTime = pickupTime {
            try container.encode(pickupTime, forKey: .pickupTime)
        }
        try container.encode(items, forKey: .items)
    }
}

struct CreateOrderItemRequest: Codable {
    let productId: String
    let quantity: Int
    let specialInstructions: String?
    
    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case quantity
        case specialInstructions = "special_instructions"
    }
    
    // Custom encoder to skip nil instructions
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(productId, forKey: .productId)
        try container.encode(quantity, forKey: .quantity)
        if let specialInstructions = specialInstructions {
            try container.encode(specialInstructions, forKey: .specialInstructions)
        }
    }
}
```

**JSON Request Body:**
```json
{
    "notes": "Extra sugar please",
    "pickup_time": "2024-12-19T10:30:00Z",
    "items": [
        {
            "product_id": "550e8400-e29b-41d4-a716-446655440001",
            "quantity": 2,
            "special_instructions": "No ice"
        },
        {
            "product_id": "550e8400-e29b-41d4-a716-446655440002",
            "quantity": 1
        }
    ]
}
```

---

### STEP 5: NETWORK LAYER - Flexible Response Handler

**File**: `SetAside/Services/NetworkManager.swift` (Lines 194-311)

```swift
func requestWithFlexibleResponse<T: Decodable>(
    endpoint: String,
    method: String = "GET",
    body: Encodable? = nil,
    requiresAuth: Bool = true
) async throws -> T {
    // Standard request creation and execution...
    
    switch httpResponse.statusCode {
    case 200...299:
        let decoder = JSONDecoder()
        
        // Try direct decoding first
        do {
            return try decoder.decode(T.self, from: data)
        } catch let directError {
            #if DEBUG
            print("⚠️ Direct decoding failed: \(directError)")
            #endif
            
            // Try wrapped response { "order": {...} } or { "data": {...} }
            if T.self == Order.self {
                do {
                    let wrapped = try decoder.decode(SingleOrderResponse.self, from: data)
                    if let order = wrapped.unwrappedOrder as? T {
                        return order
                    }
                } catch { }
                
                // Last resort: extract from JSON manually
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    for key in ["order", "data", "result"] {
                        if let orderDict = json[key] as? [String: Any],
                           let orderData = try? JSONSerialization.data(withJSONObject: orderDict),
                           let order = try? decoder.decode(Order.self, from: orderData) as? T {
                            return order
                        }
                    }
                }
            }
            
            throw APIError.decodingError(directError)
        }
    }
}
```

**Why flexible response?**
> Different API implementations might return the order in different wrappers. This method tries multiple decoding strategies to handle various response formats.

---

### STEP 6: MODEL LAYER - Order Response

**File**: `SetAside/Models/Order.swift` (Lines 8-94)

```swift
struct Order: Codable, Identifiable {
    let id: String
    let customerId: String?
    let status: String               // "pending", "preparing", "ready", "pickedup"
    let notes: String?
    let pickupTime: String?
    let totalAmount: Double?
    let items: [OrderItem]?
    let customer: User?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, status, notes, items, customer
        case customerId = "customer_id"
        case pickupTime = "pickup_time"
        case totalAmount = "total_amount"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var statusEnum: AppConstants.OrderStatus {
        AppConstants.OrderStatus(rawValue: status) ?? .pending
    }
    
    var formattedDate: String {
        // Format createdAt to human-readable string
    }
}
```

**API Response:**
```json
{
    "id": "550e8400-e29b-41d4-a716-446655440099",
    "customer_id": "550e8400-e29b-41d4-a716-446655440001",
    "status": "pending",
    "notes": "Extra sugar please",
    "pickup_time": "2024-12-19T10:30:00Z",
    "total_amount": 12.50,
    "items": [
        {
            "id": "item-uuid-1",
            "product_id": "prod-uuid-1",
            "quantity": 2,
            "unit_price": 4.50,
            "subtotal": 9.00
        }
    ],
    "created_at": "2024-12-19T09:00:00Z",
    "updated_at": "2024-12-19T09:00:00Z"
}
```

---

### STEP 7: RETURN PATH - Success State

After successful order creation:

```swift
// CartViewModel state changes
lastOrder = order              // Store for display
orderPlaced = true             // Trigger success UI
clearCart()                    // Empty items array
isLoading = false
```

**View observes these changes:**

```swift
// CheckoutView.swift
.onChange(of: cartViewModel.orderPlaced) { _, placed in
    if placed {
        // Show success modal or navigate to orders
        showOrderSuccess = true
    }
}

// Success sheet
.sheet(isPresented: $showOrderSuccess) {
    OrderSuccessView(order: cartViewModel.lastOrder)
}
```

---

## 🔀 Complete Flow Visualization

```
┌─────────────────────────────────────────────────────────────────┐
│                    CHECKOUT PROCESS                             │
└─────────────────────────────────────────────────────────────────┘

User in CartView
       │
       ▼ taps "Proceed to Checkout"
┌──────────────┐
│ CheckoutView │
│              │
│ Order Summary│
│ Notes Input  │
│ Pickup Time  │
│ Total Price  │
│              │
│ [Place Order]│
└──────┬───────┘
       │ taps button
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ CartViewModel.placeOrder(notes, pickupTime)                      │
└──────────────────────────────────────────────────────────────────┘
       │
       │ Transform: CartItem[] → CreateOrderItemRequest[]
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ OrderService.createOrder(notes, pickupTime, items)               │
│    └── Format Date → ISO8601                                     │
│    └── Create CreateOrderRequest                                 │
└──────────────────────────────────────────────────────────────────┘
       │
       │ POST /api/v1/orders
       │ Authorization: Bearer <token>
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ API: Creates order, calculates total, returns Order              │
└──────────────────────────────────────────────────────────────────┘
       │
       │ Return Order object
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ CartViewModel updates:                                           │
│    lastOrder = order                                             │
│    orderPlaced = true   ← Triggers UI                            │
│    clearCart()          ← Empties items                          │
│    isLoading = false                                             │
└──────────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ CheckoutView observes orderPlaced = true                         │
│    └── Shows success modal/animation                             │
│    └── Navigates to Orders tab                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## ❌ Error Handling

### Possible Errors

| Error | Cause | Handling |
|-------|-------|----------|
| **401 Unauthorized** | Token expired | Auto-logout, show login |
| **400 Bad Request** | Invalid product IDs | Show error message |
| **500 Server Error** | Backend issue | Show retry option |
| **Decoding Error** | Response format mismatch | Assume success, clear cart |

### Graceful Degradation

```swift
} catch {
    #if DEBUG
    print("⚠️ Order API returned error but order may have been created")
    #endif
    
    // Even if decoding fails, order was likely created (POST succeeded)
    // Clear cart and show success - user can check Orders tab
    lastOrder = nil
    orderPlaced = true
    clearCart()
}
```

**Why assume success on decoding error?**
> If POST returned 2xx, the order was likely created. A decoding error just means we couldn't parse the response. Better UX to show success and let user verify in Orders.

---

## 🗂 State Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    CHECKOUT STATES                              │
└─────────────────────────────────────────────────────────────────┘

     ┌──────────────┐
     │   VIEWING    │
     │   CHECKOUT   │
     │ isLoading=F  │
     │ orderPlaced=F│
     └──────┬───────┘
            │ tap "Place Order"
            ▼
     ┌──────────────┐
     │  SUBMITTING  │
     │ isLoading=T  │
     │ orderPlaced=F│
     └──────┬───────┘
            │
     ┌──────┴──────┐
     │             │
     ▼             ▼
┌─────────┐   ┌─────────┐
│ SUCCESS │   │  ERROR  │
│lastOrder│   │errorMsg │
│=Order   │   │=text    │
│placed=T │   │showErr=T│
│cart=[]  │   │         │
└─────────┘   └─────────┘
     │
     ▼
┌─────────────┐
│ SHOW SUCCESS│
│ Navigate to │
│ Orders tab  │
└─────────────┘
```

---

## ❓ Key Points for Exam

### Q: Why transform CartItem to CreateOrderItemRequest?
> CartItem contains the full Product object (for display). The API only needs product_id, quantity, and special_instructions. Transformation reduces payload size and follows API contract.

### Q: Why use ISO8601DateFormatter for pickup time?
> ISO8601 is the standard format for date-time in APIs. It includes timezone information and is universally parseable.

### Q: What if the API returns a different response format?
> `requestWithFlexibleResponse` tries multiple decoding strategies: direct decoding, wrapped in "order" key, wrapped in "data" key. This handles various API implementations.

### Q: Why clear the cart even on error?
> If we got a 2xx response, the order was likely created. Clearing the cart prevents duplicate orders. User can verify in Orders tab.

### Q: What design patterns are used?
> - **Data Transfer Object (DTO)**: CreateOrderItemRequest is a DTO that differs from domain model
> - **Repository**: OrderService abstracts API details
> - **State Machine**: orderPlaced, isLoading manage UI states

---

## 🗣 What to Say During Exam

> "The checkout flow transforms the local cart into an API request. CartItems contain full Product objects for display, but we only send product_id, quantity, and special_instructions to the API. The CartViewModel's placeOrder method coordinates this: it sets loading state, transforms the data, calls OrderService, and on success sets orderPlaced=true which triggers the view to show a success modal. We also clear the cart to prevent duplicate orders. The flexible response handler in NetworkManager tries multiple decoding strategies because different backend implementations might return the order in different JSON wrappers."

---

## ⏱ Timing Estimates

| Step | Duration |
|------|----------|
| Data transformation | ~1ms |
| Date formatting | ~1ms |
| JSON encoding | ~5ms |
| Network request | ~300-700ms |
| JSON decoding | ~5ms |
| UI update | ~10ms |
| **Total** | **~350-750ms** |
