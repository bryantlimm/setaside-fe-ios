# Scenario: App Launch Flow

## 📋 Scenario Overview

**User Action**: User opens the SetAside app  
**Platform**: iOS (Swift/SwiftUI)  
**Expected Behavior**: App checks authentication state and navigates to appropriate screen

---

## 🔄 Complete Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     APP LAUNCH                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   SetAsideApp.swift                             │
│                                                                 │
│   @StateObject var authViewModel = AuthViewModel()              │
│   @StateObject var cartViewModel = CartViewModel()              │
│                                                                 │
│   WindowGroup {                                                 │
│       RootView()                                                │
│           .environmentObject(authViewModel)                     │
│           .environmentObject(cartViewModel)                     │
│   }                                                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   AuthViewModel.init()                          │
│                                                                 │
│   1. Check UserDefaults for isLoggedIn                          │
│   2. If logged in, fetch current user profile                   │
│   3. Set isLoggedIn state                                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     RootView.swift                              │
│                                                                 │
│   if authViewModel.isLoggedIn {                                 │
│       MainTabView()         // Go to main app                   │
│   } else {                                                      │
│       SignInView()          // Go to login                      │
│   }                                                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📍 Step-by-Step Code Flow

### Step 1: App Entry Point

**File**: `SetAside/SetAsideApp.swift` (Lines 10-22)

```swift
@main
struct SetAsideApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var cartViewModel = CartViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(cartViewModel)
        }
    }
}
```

**What happens here:**
1. `@main` marks this as the app entry point
2. `@StateObject` creates ONE instance of `AuthViewModel` that persists for app lifetime
3. `@StateObject` creates ONE instance of `CartViewModel` that persists for app lifetime
4. Both ViewModels are injected into the environment for ALL child views

**⏱ Timing**: This happens during app initialization (~0.1 seconds)

---

### Step 2: AuthViewModel Initialization

**File**: `SetAside/ViewModels/AuthViewModel.swift` (Lines 10-27)

```swift
@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    private let authService = AuthService.shared
    
    init() {
        // Check if user was previously logged in
        isLoggedIn = authService.isLoggedIn
        
        if isLoggedIn {
            // Fetch user profile if token exists
            Task { @MainActor in
                await fetchCurrentUser()
            }
        }
    }
}
```

**What happens here:**
1. Creates @Published properties for UI binding
2. Gets reference to `AuthService.shared` singleton
3. Checks `UserDefaults` for existing login state via `authService.isLoggedIn`
4. If previously logged in, kicks off async task to fetch user profile

---

### Step 3: Check Stored Login State

**File**: `SetAside/Services/AuthService.swift` (Lines 73-76)

```swift
var isLoggedIn: Bool {
    return UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.isLoggedIn)
}
```

**What happens here:**
- Reads boolean from `UserDefaults` with key `"isLoggedIn"`
- Returns `true` if user was logged in before (token saved)
- Returns `false` if fresh install or user logged out

---

### Step 4: Fetch Current User (If Logged In)

**File**: `SetAside/ViewModels/AuthViewModel.swift` (Lines 86-97)

```swift
func fetchCurrentUser() async {
    do {
        currentUser = try await authService.getCurrentUser()
    } catch let error as APIError {
        if case .unauthorized = error {
            logout()  // Token expired, force re-login
        }
        errorMessage = error.errorDescription
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

**API Call Chain:**

```
AuthViewModel.fetchCurrentUser()
        │
        ▼
AuthService.getCurrentUser()
        │
        ▼
NetworkManager.request(endpoint: "/auth/me")
        │
        ▼
┌──────────────────────────────────┐
│  GET /api/v1/auth/me             │
│  Authorization: Bearer <token>   │
└──────────────────────────────────┘
        │
        ▼
Response: User object
```

---

### Step 5: Root Navigation Decision

**File**: `SetAside/Views/Main/RootView.swift` (Lines 8-21)

```swift
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isLoggedIn {
                MainTabView()
            } else {
                SignInView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isLoggedIn)
    }
}
```

**What happens here:**
1. Reads `isLoggedIn` from `authViewModel` via Environment
2. If `true` → Shows `MainTabView` (main app with tabs)
3. If `false` → Shows `SignInView` (login screen)
4. Animates transitions when login state changes

---

### Step 6A: User is NOT Logged In → SignInView

**File**: `SetAside/Views/Auth/SignInView.swift`

```swift
struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        // Login form UI
    }
}
```

**User sees:**
- Welcome back message
- Email input field
- Password input field
- Sign In button
- Link to Sign Up

---

### Step 6B: User IS Logged In → MainTabView

**File**: `SetAside/Views/Main/MainTabView.swift` (Lines 8-70)

```swift
struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var cartViewModel: CartViewModel
    @StateObject private var productViewModel = ProductViewModel()
    
    @State private var selectedTab = 0
    
    // Check if user is admin or cashier (staff)
    private var isStaff: Bool {
        guard let role = authViewModel.currentUser?.role else { return false }
        return role == "admin" || role == "cashier"
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
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
            
            // Bottom Tab Bar
            bottomNavBar
        }
    }
}
```

**What happens here:**
1. Creates local `ProductViewModel` with `@StateObject`
2. Checks user role from `authViewModel.currentUser?.role`
3. Shows different tab layouts based on role:
   - **Staff**: Orders → Products → Profile
   - **Customer**: Home → Orders → Profile

---

## 🔀 Complete Flow Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                    APP LAUNCH FLOW                              │
└─────────────────────────────────────────────────────────────────┘

1. iOS launches SetAsideApp
   └── Creates AuthViewModel (@StateObject)
       └── AuthViewModel.init() runs
           ├── Reads isLoggedIn from UserDefaults
           │
           ├─── [isLoggedIn = FALSE] ──────────────────────┐
           │                                               │
           └─── [isLoggedIn = TRUE] ─────────────────┐     │
                                                     │     │
2. RootView renders                                  │     │
   └── Reads authViewModel.isLoggedIn                │     │
                                                     │     │
       ┌────────────────────────────────────────────┘     │
       │                                                   │
       ▼                                                   ▼
┌──────────────┐                                ┌──────────────┐
│ MainTabView  │                                │  SignInView  │
│              │                                │              │
│ isStaff?     │                                │ Email input  │
│ ├─ YES       │                                │ Password     │
│ │  AdminOrdersView                            │ Login button │
│ │  AdminProductsView                          │              │
│ │  ProfileView                                │              │
│ │                                             │              │
│ └─ NO                                         │              │
│    HomeView                                   │              │
│    OrdersView                                 │              │
│    ProfileView                                │              │
└──────────────┘                                └──────────────┘

3. AuthViewModel.fetchCurrentUser() runs async (if logged in)
   └── GET /auth/me
       ├── Success: currentUser = User object
       └── 401 Error: logout() → RootView switches to SignInView
```

---

## ❓ Key Points for Exam

### Q: Why use @StateObject in SetAsideApp?
> @StateObject creates and OWNS the ViewModel instance. It persists for the entire app lifecycle, ensuring all child views share the same instance.

### Q: Why not create ViewModels directly in each View?
> That would create NEW instances on every render. Using @StateObject once and @EnvironmentObject in children ensures single source of truth.

### Q: What happens if the token is expired?
> When `fetchCurrentUser()` gets a 401 response, it catches the `unauthorized` error and calls `logout()`, which clears the token and sets `isLoggedIn = false`. RootView reactively switches to SignInView.

### Q: Why is AuthViewModel marked with @MainActor?
> @MainActor ensures all @Published property updates happen on the main thread, which is required for UI updates in SwiftUI.

---

## 🐛 Error Handling Cases

| Scenario | Handling |
|----------|----------|
| Fresh install (no token) | `isLoggedIn = false` → SignInView |
| Valid token exists | `isLoggedIn = true` → MainTabView + fetch profile |
| Token expired (401) | `logout()` → Clear token → SignInView |
| Network error on profile fetch | Show error but stay logged in (optional re-fetch) |

---

## ⏱ Timing Estimates

| Operation | Duration |
|-----------|----------|
| App initialization | ~100ms |
| UserDefaults read | ~1ms |
| API call (fetch user) | ~200-500ms |
| View rendering | ~50ms |

**Total cold start**: ~300-600ms (depends on network)
