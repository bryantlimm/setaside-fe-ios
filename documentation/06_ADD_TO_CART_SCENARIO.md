# Scenario: Add to Cart

## 📋 Scenario Overview

**User Action**: User taps "Add" button on a product card  
**Platform**: iOS (Swift/SwiftUI)  
**Expected Behavior**: Add product to local cart, update cart badge, allow quantity adjustments

---

## 🔄 Complete Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  USER TAPS "ADD" BUTTON ON PRODUCT CARD                                      │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  VIEW LAYER: HomeView.swift (ProductCard)                                    │
│                                                                              │
│  Button(action: {                                                            │
│      cartViewModel.addToCart(product: product)                               │
│  }) {                                                                        │
│      Text("Add")                                                             │
│  }                                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  VIEWMODEL LAYER: CartViewModel.swift                                        │
│                                                                              │
│  func addToCart(product: Product, quantity: Int = 1) {                       │
│      if let index = items.firstIndex(where: { $0.product.id == product.id }) │
│          items[index].quantity += quantity   // Increment existing          │
│      } else {                                                                │
│          items.append(CartItem(...))         // Add new item                 │
│      }                                                                       │
│  }                                                                           │
│                                                                              │
│  @Published var items: [CartItem] = []    ← Triggers UI update              │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  MODEL LAYER: CartItem.swift (LOCAL model - no API call)                     │
│                                                                              │
│  struct CartItem {                                                           │
│      let id: UUID                                                            │
│      let product: Product                                                    │
│      var quantity: Int                                                       │
│      var specialInstructions: String?                                        │
│  }                                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  UI UPDATES (Reactive via @Published)                                        │
│                                                                              │
│  • Product card button changes to "In Cart (1)"                              │
│  • Cart badge in header updates (1)                                          │
│  • CartView shows new item                                                   │
└──────────────────────────────────────────────────────────────────────────────┘
```

**🔑 Key Point: Cart is LOCAL only - no API call until checkout!**

---

## 📍 Step-by-Step Code Flow

### STEP 1: VIEW LAYER - User Taps Add Button

**File**: `SetAside/Views/Home/HomeView.swift` (Lines 326-344)

```swift
// Inside ProductCard
Button(action: {
    cartViewModel.addToCart(product: product)
}) {
    HStack {
        if cartViewModel.isInCart(product) {
            // Show current quantity if already in cart
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
```

**What happens here:**
1. Button calls `cartViewModel.addToCart(product: product)`
2. UI dynamically shows "Add" or "In Cart (N)" based on `isInCart()`
3. Button color changes when product is in cart

---

### STEP 2: VIEWMODEL LAYER - Add Product to Cart

**File**: `SetAside/ViewModels/CartViewModel.swift` (Lines 32-48)

```swift
func addToCart(product: Product, quantity: Int = 1, specialInstructions: String? = nil) {
    // Check if product already exists in cart
    if let index = items.firstIndex(where: { $0.product.id == product.id }) {
        // UPDATE EXISTING - increment quantity
        items[index].quantity += quantity
        if let instructions = specialInstructions {
            items[index].specialInstructions = instructions
        }
    } else {
        // ADD NEW - create CartItem
        let cartItem = CartItem(
            product: product,
            quantity: quantity,
            specialInstructions: specialInstructions
        )
        items.append(cartItem)
    }
}
```

**Logic Flow:**
```
addToCart(product) called
       │
       ▼
Check: Does items contain this product.id?
       │
   ┌───┴───┐
   │       │
   YES     NO
   │       │
   ▼       ▼
Increment  Create new
quantity   CartItem &
           append
```

---

### STEP 3: MODEL LAYER - CartItem Structure

**File**: `SetAside/Models/CartItem.swift` (Lines 8-21)

```swift
struct CartItem: Identifiable, Equatable {
    let id: UUID = UUID()           // Unique identifier for SwiftUI lists
    let product: Product            // Reference to the product
    var quantity: Int               // Mutable quantity
    var specialInstructions: String?  // Optional notes
    
    // Computed property for line total
    var totalPrice: Double {
        product.price * Double(quantity)
    }
    
    // Equality based on product ID (not CartItem ID)
    static func == (lhs: CartItem, rhs: CartItem) -> Bool {
        lhs.product.id == rhs.product.id
    }
}
```

**Key Design Decisions:**
- `id: UUID` - Each CartItem has unique ID for SwiftUI's `ForEach`
- `product: Product` - Stores full product info (name, price, image)
- `var quantity` - Mutable so we can increment/decrement
- `Equatable` compares by product.id, not CartItem.id

---

### STEP 4: UI REACTIVITY - Automatic Updates

When `items` array changes, all these update automatically:

#### 4a. Cart Badge (Header)

**File**: `SetAside/Views/Home/HomeView.swift` (Lines 106-115)

```swift
// Cart Button with Badge
ZStack(alignment: .topTrailing) {
    // Cart icon...
    
    // Badge shows item count
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
```

**Computed Property:**

```swift
// CartViewModel.swift - Lines 24-26
var itemCount: Int {
    items.reduce(0) { $0 + $1.quantity }
}
```

#### 4b. Product Card Button State

```swift
// Uses helper methods in CartViewModel
func isInCart(_ product: Product) -> Bool {
    items.contains(where: { $0.product.id == product.id })
}

func getQuantity(for product: Product) -> Int {
    items.first(where: { $0.product.id == product.id })?.quantity ?? 0
}
```

#### 4c. Total Price

```swift
// CartViewModel.swift - Lines 20-22
var totalPrice: Double {
    items.reduce(0) { $0 + $1.totalPrice }
}
```

---

## 🛒 Cart Management Operations

### Remove from Cart

**File**: `SetAside/ViewModels/CartViewModel.swift` (Lines 50-52)

```swift
func removeFromCart(product: Product) {
    items.removeAll { $0.product.id == product.id }
}
```

### Remove by Index

```swift
func removeItem(at index: Int) {
    guard index < items.count else { return }
    items.remove(at: index)
}
```

### Update Quantity

```swift
func updateQuantity(for product: Product, quantity: Int) {
    if let index = items.firstIndex(where: { $0.product.id == product.id }) {
        if quantity <= 0 {
            items.remove(at: index)  // Remove if 0
        } else {
            items[index].quantity = quantity
        }
    }
}
```

### Increment/Decrement

```swift
func incrementQuantity(at index: Int) {
    guard index < items.count else { return }
    items[index].quantity += 1
}

func decrementQuantity(at index: Int) {
    guard index < items.count else { return }
    if items[index].quantity > 1 {
        items[index].quantity -= 1
    } else {
        items.remove(at: index)  // Remove if going to 0
    }
}
```

### Clear Cart

```swift
func clearCart() {
    items.removeAll()
}
```

---

## 📱 Cart View UI

**File**: `SetAside/Views/Cart/CartView.swift`

### Cart Item Row

```swift
struct CartItemRow: View {
    let item: CartItem
    var onIncrement: () -> Void
    var onDecrement: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Product Image
            AsyncImage(url: URL(string: item.product.imageUrl ?? ""))
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("$\(item.product.price, specifier: "%.2f") each")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("$\(item.totalPrice, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryGreen)
                
                // Quantity Controls
                HStack(spacing: 12) {
                    Button(action: onDecrement) {
                        Image(systemName: "minus.circle.fill")
                    }
                    
                    Text("\(item.quantity)")
                        .fontWeight(.semibold)
                    
                    Button(action: onIncrement) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            
            Spacer()
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red)
            }
        }
    }
}
```

### Cart List

```swift
ScrollView {
    LazyVStack(spacing: 12) {
        ForEach(Array(cartViewModel.items.enumerated()), id: \.element.id) { index, item in
            CartItemRow(
                item: item,
                onIncrement: { cartViewModel.incrementQuantity(at: index) },
                onDecrement: { cartViewModel.decrementQuantity(at: index) },
                onDelete: { cartViewModel.removeItem(at: index) }
            )
        }
    }
}
```

---

## 🔀 State Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      CART STATES                                │
└─────────────────────────────────────────────────────────────────┘

     ┌─────────────┐
     │    EMPTY    │
     │  items=[]   │
     │  total=$0   │
     └──────┬──────┘
            │ addToCart(product)
            ▼
     ┌─────────────┐
     │ HAS ITEMS   │
     │ items=[...] │
     │ total=$X    │
     └──────┬──────┘
            │
     ┌──────┼──────┬────────────┐
     │      │      │            │
     ▼      ▼      ▼            ▼
  addToCart  inc   dec       clearCart
  (same)   quantity quantity     │
     │      │      │            │
     ▼      ▼      ▼            ▼
  quantity  qty++  qty-- OR   EMPTY
  += 1             remove     state
```

---

## 🗂 Class Diagram

```
┌─────────────────────────────────────┐
│           ProductCard              │
├─────────────────────────────────────┤
│ @EnvironmentObject                  │
│   cartViewModel: CartViewModel      │
│ let product: Product                │
├─────────────────────────────────────┤
│ Button → addToCart()                │
└─────────────────┬───────────────────┘
                  │ calls
                  ▼
┌─────────────────────────────────────┐
│         CartViewModel              │
├─────────────────────────────────────┤
│ @Published items: [CartItem]        │
│ totalPrice: Double (computed)       │
│ itemCount: Int (computed)           │
│ isEmpty: Bool (computed)            │
├─────────────────────────────────────┤
│ func addToCart(product)             │
│ func removeFromCart(product)        │
│ func updateQuantity(product, qty)   │
│ func incrementQuantity(at: Int)     │
│ func decrementQuantity(at: Int)     │
│ func clearCart()                    │
│ func isInCart(product) -> Bool      │
│ func getQuantity(product) -> Int    │
└─────────────────┬───────────────────┘
                  │ manages
                  ▼
┌─────────────────────────────────────┐
│           CartItem                 │
├─────────────────────────────────────┤
│ let id: UUID                        │
│ let product: Product                │
│ var quantity: Int                   │
│ var specialInstructions: String?    │
│ totalPrice: Double (computed)       │
└─────────────────────────────────────┘
```

---

## 🌐 No Network Calls - Local State Only

**Important**: The Cart is entirely client-side until checkout.

| Operation | Network Call? |
|-----------|---------------|
| Add to cart | ❌ No - local only |
| Update quantity | ❌ No - local only |
| Remove from cart | ❌ No - local only |
| View cart | ❌ No - local only |
| **Checkout/Place order** | ✅ **Yes - POST /orders** |

**Why?**
- Faster user experience (no network latency)
- Works offline (until checkout)
- Simpler implementation
- Common pattern for e-commerce apps

---

## 🔁 Cart Persistence

Currently, the cart is **NOT persisted**. If the app is killed, cart contents are lost.

**Future improvement options:**
1. **UserDefaults** - Simple key-value storage
2. **Core Data** - Local database
3. **Server-side cart** - Sync with backend

---

## ❓ Key Points for Exam

### Q: Why is CartItem a struct, not a class?
> Value semantics. When we modify a CartItem in the array, Swift creates a copy, which triggers @Published to notify observers. This is how SwiftUI knows to update the UI.

### Q: Why does CartItem have its own UUID?
> SwiftUI's ForEach needs Identifiable items. Each CartItem needs a unique ID for tracking, separate from the Product ID (since the same product could theoretically have multiple cart entries with different instructions).

### Q: Why not call API when adding to cart?
> User experience. Local cart operations are instant. Calling API for every add/remove would be slow and require handling network errors for simple actions.

### Q: How do computed properties like itemCount work with @Published?
> They don't need @Published themselves. When the underlying `items` array changes (which IS @Published), any view accessing computed properties automatically re-evaluates them.

### Q: What happens to the cart after placing an order?
> `clearCart()` is called to empty the items array. See the Place Order scenario.

---

## 🗣 What to Say During Exam

> "The cart uses a local-first approach. CartViewModel maintains an array of CartItems, each containing a reference to a Product and a quantity. Adding to cart is instant because it only modifies local state - no network call is made. The @Published property wrapper on the items array triggers SwiftUI to re-render any views observing the cart, like the badge count or cart total. The cart data is only sent to the server during checkout when we create an order via POST /orders. This pattern provides a fast, responsive user experience."

---

## ⏱ Timing Estimates

| Operation | Duration |
|-----------|----------|
| Add to cart | ~1ms (local array mutation) |
| Increment quantity | ~1ms |
| UI re-render | ~5-10ms |
| Total visible update | ~10-15ms |

**Note**: These are all local operations - no network latency!
