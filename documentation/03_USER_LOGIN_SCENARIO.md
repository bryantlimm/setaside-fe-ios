# Scenario: User Login

## 📋 Scenario Overview

**User Action**: User enters email and password, then taps "Sign In" button  
**Platform**: iOS (Swift/SwiftUI)  
**Expected Behavior**: Validate credentials, get JWT token, navigate to main app

---

## 🔄 Complete Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  USER ENTERS EMAIL + PASSWORD → TAPS "SIGN IN"                               │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  VIEW LAYER: SignInView.swift                                                │
│                                                                              │
│  Button("Sign In") {                                                         │
│      Task {                                                                  │
│          await authViewModel.login(email: email, password: password)        │
│      }                                                                       │
│  }                                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  VIEWMODEL LAYER: AuthViewModel.swift                                        │
│                                                                              │
│  func login(email: String, password: String) async {                         │
│      isLoading = true                                                        │
│      let response = try await authService.login(email, password)            │
│      currentUser = response.user                                             │
│      isLoggedIn = true                                                       │
│  }                                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  SERVICE LAYER: AuthService.swift                                            │
│                                                                              │
│  func login(email, password) async throws -> AuthResponse {                  │
│      let request = LoginRequest(email, password)                             │
│      let response = try await networkManager.request("/auth/login", request) │
│      networkManager.setAccessToken(response.accessToken)                     │
│      UserDefaults.set(true, forKey: "isLoggedIn")                           │
│      return response                                                         │
│  }                                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  NETWORK: NetworkManager.swift                                               │
│                                                                              │
│  POST /api/v1/auth/login                                                     │
│  Body: { "email": "...", "password": "..." }                                 │
│                                                                              │
│  Response: { "access_token": "jwt...", "user": {...} }                       │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  RETURN PATH (State Updates)                                                 │
│                                                                              │
│  AuthViewModel.isLoggedIn = true                                             │
│       │                                                                      │
│       ▼                                                                      │
│  RootView observes @EnvironmentObject authViewModel                         │
│       │                                                                      │
│       ▼                                                                      │
│  RootView switches from SignInView → MainTabView                             │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 📍 Step-by-Step Code Flow

### STEP 1: VIEW LAYER - User Taps Sign In

**File**: `SetAside/Views/Auth/SignInView.swift` (Lines 109-118)

```swift
// Sign In Button
PrimaryButton(
    title: "Sign In",
    isLoading: authViewModel.isLoading    // Shows spinner while loading
) {
    hideKeyboard()                         // Dismiss keyboard
    Task {
        await authViewModel.login(email: email, password: password)
    }
}
.disabled(email.isEmpty || password.isEmpty)  // Disabled if fields empty
```

**What happens here:**
1. User taps the "Sign In" button
2. `hideKeyboard()` dismisses the keyboard
3. A new `Task` is created for async operation
4. Calls `authViewModel.login()` with email and password
5. Button shows loading spinner while `authViewModel.isLoading` is true

**⏱ Timing**: Immediate (UI thread)

---

### STEP 2: VIEWMODEL LAYER - Validate and Call Service

**File**: `SetAside/ViewModels/AuthViewModel.swift` (Lines 29-53)

```swift
func login(email: String, password: String) async {
    isLoading = true          // Step 2a: Show loading indicator
    errorMessage = nil        // Step 2b: Clear previous errors
    showError = false
    
    do {
        // Step 2c: Call AuthService
        let response = try await authService.login(email: email, password: password)
        
        // Step 2d: Update state on success
        self.currentUser = response.user
        self.isLoading = false
        self.isLoggedIn = true    // ← THIS triggers navigation!
        
        // Step 2e: Fetch full profile if not in response
        if self.currentUser == nil {
            await fetchCurrentUser()
        }
    } catch let error as APIError {
        // Step 2f: Handle API errors
        self.isLoading = false
        self.errorMessage = error.errorDescription
        self.showError = true
    } catch {
        // Step 2g: Handle other errors
        self.isLoading = false
        self.errorMessage = error.localizedDescription
        self.showError = true
    }
}
```

**State Changes:**

| Property | Before | During | After (Success) | After (Error) |
|----------|--------|--------|-----------------|---------------|
| `isLoading` | false | **true** | false | false |
| `errorMessage` | nil | nil | nil | "Error message" |
| `showError` | false | false | false | **true** |
| `currentUser` | nil | nil | **User** | nil |
| `isLoggedIn` | false | false | **true** | false |

---

### STEP 3: SERVICE LAYER - Make API Request

**File**: `SetAside/Services/AuthService.swift` (Lines 41-57)

```swift
func login(email: String, password: String) async throws -> AuthResponse {
    // Step 3a: Create request body
    let request = LoginRequest(email: email, password: password)
    
    // Step 3b: Make network request
    let response: AuthResponse = try await networkManager.request(
        endpoint: "/auth/login",
        method: "POST",
        body: request,
        requiresAuth: false    // Login doesn't need auth header
    )
    
    // Step 3c: Save token for future requests
    networkManager.setAccessToken(response.accessToken)
    
    // Step 3d: Mark user as logged in
    UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.isLoggedIn)
    
    return response
}
```

**What happens here:**
1. Creates `LoginRequest` struct with email/password
2. Calls `NetworkManager.request()` with POST to `/auth/login`
3. On success, saves JWT token via `setAccessToken()`
4. Saves `isLoggedIn = true` to UserDefaults for persistence
5. Returns `AuthResponse` with token and user

---

### STEP 4: MODEL LAYER - Request/Response Structures

**File**: `SetAside/Models/User.swift` (Lines 40-43, 28-38)

```swift
// Request Body
struct LoginRequest: Codable {
    let email: String
    let password: String
}

// Response Body
struct AuthResponse: Codable {
    let accessToken: String
    let tokenType: String?
    let user: User?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"   // Map snake_case
        case tokenType = "token_type"
        case user
    }
}
```

**JSON Request:**
```json
{
    "email": "user@example.com",
    "password": "password123"
}
```

**JSON Response:**
```json
{
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "token_type": "bearer",
    "user": {
        "id": "uuid-here",
        "email": "user@example.com",
        "full_name": "John Doe",
        "phone": "+1234567890",
        "role": "customer",
        "created_at": "2024-01-01T00:00:00Z"
    }
}
```

---

### STEP 5: NETWORK LAYER - HTTP Request Execution

**File**: `SetAside/Services/NetworkManager.swift` (Lines 61-147)

```swift
func request<T: Decodable>(
    endpoint: String,
    method: String = "GET",
    body: Encodable? = nil,
    requiresAuth: Bool = true
) async throws -> T {
    
    // Step 5a: Encode request body to JSON
    var bodyData: Data? = nil
    if let body = body {
        let encoder = JSONEncoder()
        bodyData = try encoder.encode(body)
    }
    
    // Step 5b: Create URLRequest
    let request = try createRequest(
        endpoint: endpoint,
        method: method,
        body: bodyData,
        requiresAuth: requiresAuth
    )
    
    #if DEBUG
    print("🌐 API Request: \(method) \(baseURL)\(endpoint)")
    #endif
    
    // Step 5c: Execute HTTP request
    let (data, response) = try await session.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIError.invalidResponse
    }
    
    // Step 5d: Handle response by status code
    switch httpResponse.statusCode {
    case 200...299:
        // Success - decode response
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
        
    case 401:
        // Unauthorized
        clearToken()
        throw APIError.unauthorized
        
    case 404:
        throw APIError.notFound
        
    case 500...599:
        throw APIError.serverError
        
    default:
        let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
        throw APIError.httpError(
            statusCode: httpResponse.statusCode,
            message: errorResponse?.errorMessage ?? "Request failed"
        )
    }
}
```

**HTTP Request Details:**
```
POST /api/v1/auth/login HTTP/1.1
Host: setaside.matthewswong.tech
Content-Type: application/json

{"email":"user@example.com","password":"password123"}
```

---

### STEP 6: RETURN PATH - State Updates

After successful login, the flow returns through the layers:

```
NetworkManager returns AuthResponse
       │
       ▼
AuthService saves token + returns AuthResponse
       │
       ▼
AuthViewModel sets:
   • currentUser = response.user
   • isLoading = false
   • isLoggedIn = true  ← TRIGGERS RE-RENDER
       │
       ▼
RootView observes isLoggedIn change (@Published + @EnvironmentObject)
       │
       ▼
RootView re-evaluates body:
   • if authViewModel.isLoggedIn → MainTabView()
       │
       ▼
User sees MainTabView (Home screen)
```

---

### STEP 7: UI RESPONSE - Navigation Change

**File**: `SetAside/Views/Main/RootView.swift` (Lines 11-18)

```swift
var body: some View {
    Group {
        if authViewModel.isLoggedIn {
            MainTabView()          // ← NOW SHOWS THIS
        } else {
            SignInView()
        }
    }
    .animation(.easeInOut, value: authViewModel.isLoggedIn)  // Smooth transition
}
```

**SwiftUI Reactivity:**
1. `authViewModel.isLoggedIn` is `@Published`
2. RootView has `@EnvironmentObject var authViewModel`
3. When `isLoggedIn` changes, SwiftUI automatically re-renders
4. The `.animation()` modifier provides smooth fade transition

---

## ❌ Error Handling Flow

### If Login Fails (e.g., wrong password):

**API Response (400 Bad Request):**
```json
{
    "detail": "Incorrect email or password"
}
```

**Error Handling Path:**

```swift
// In NetworkManager - line 131-146
default:
    let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
    throw APIError.httpError(
        statusCode: httpResponse.statusCode,
        message: errorResponse?.errorMessage ?? "Request failed"
    )
```

```swift
// In AuthViewModel - line 44-52
} catch let error as APIError {
    self.isLoading = false
    self.errorMessage = error.errorDescription   // "Incorrect email or password"
    self.showError = true
}
```

**SignInView Error Display:**

```swift
// SignInView.swift - Lines 62-75
.alert("Error", isPresented: $showErrorAlert) {
    Button("OK", role: .cancel) { }
} message: {
    Text(errorMessage)  // "Incorrect email or password"
}
.onReceive(authViewModel.$showError) { newValue in
    if newValue {
        errorMessage = authViewModel.errorMessage ?? "An error occurred"
        showErrorAlert = true
        authViewModel.clearError()  // Reset for next attempt
    }
}
```

---

## 🗂 Class Diagram

```
┌─────────────────────────────────────┐
│           SignInView               │
├─────────────────────────────────────┤
│ @EnvironmentObject                  │
│   authViewModel: AuthViewModel      │
│ @State email: String                │
│ @State password: String             │
├─────────────────────────────────────┤
│ Button(action:) → login()           │
└─────────────────┬───────────────────┘
                  │ calls
                  ▼
┌─────────────────────────────────────┐
│         AuthViewModel              │
├─────────────────────────────────────┤
│ @Published isLoggedIn: Bool         │
│ @Published currentUser: User?       │
│ @Published isLoading: Bool          │
│ @Published errorMessage: String?    │
│ @Published showError: Bool          │
│ authService: AuthService            │
├─────────────────────────────────────┤
│ func login(email, password) async   │
│ func logout()                       │
│ func clearError()                   │
└─────────────────┬───────────────────┘
                  │ calls
                  ▼
┌─────────────────────────────────────┐
│          AuthService               │
├─────────────────────────────────────┤
│ static shared: AuthService          │
│ networkManager: NetworkManager      │
├─────────────────────────────────────┤
│ func login(email, password):        │
│     AuthResponse                    │
│ func register(...): AuthResponse    │
│ func getCurrentUser(): User         │
│ func logout()                       │
└─────────────────┬───────────────────┘
                  │ calls
                  ▼
┌─────────────────────────────────────┐
│        NetworkManager              │
├─────────────────────────────────────┤
│ static shared: NetworkManager       │
│ accessToken: String?                │
│ session: URLSession                 │
├─────────────────────────────────────┤
│ func request<T>(): T                │
│ func setAccessToken(token)          │
│ func clearToken()                   │
└─────────────────────────────────────┘
```

---

## ❓ Key Points for Exam

### Q: Why use Task {} when calling login?
> Task {} creates an async context from a synchronous Button action. Without it, we can't use `await`. The Task runs on the current actor (main thread due to @MainActor).

### Q: How does the UI know to navigate after login?
> `isLoggedIn` is an @Published property in AuthViewModel. RootView accesses it via @EnvironmentObject. When it changes to true, SwiftUI automatically re-renders RootView and shows MainTabView.

### Q: What's the Singleton pattern used for?
> AuthService.shared ensures ONE instance exists app-wide. This prevents duplicate network connections and ensures consistent state.

### Q: Why save to UserDefaults?
> Persistence. When the app is killed and relaunched, we check UserDefaults to restore login state without requiring re-authentication.

### Q: What design patterns are used?
> - **MVVM**: Separates View (SignInView) from business logic (AuthViewModel)
> - **Singleton**: AuthService.shared, NetworkManager.shared
> - **Repository**: AuthService abstracts API details from ViewModel
> - **Observer**: @Published + @EnvironmentObject for reactive updates

---

## ⏱ Timing Estimates

| Step | Duration |
|------|----------|
| Button tap to Task creation | ~1ms |
| UI updates (isLoading = true) | ~5ms |
| Network request (POST /auth/login) | ~200-500ms |
| Token save to UserDefaults | ~1ms |
| UI updates (isLoggedIn = true) | ~5ms |
| View transition animation | ~300ms |
| **Total (success path)** | **~500-800ms** |
