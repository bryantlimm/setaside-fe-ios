# Scenario: User Registration

## 📋 Scenario Overview

**User Action**: User fills in registration form (email, password, name, phone) and taps "Sign Up"  
**Platform**: iOS (Swift/SwiftUI)  
**Expected Behavior**: Create new account, get JWT token, navigate to main app

---

## 🔄 Complete Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  USER FILLS FORM → TAPS "SIGN UP"                                           │
│  (email, password, full name, phone)                                         │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  VIEW LAYER: SignUpView.swift                                                │
│                                                                              │
│  Button("Sign Up") {                                                         │
│      Task {                                                                  │
│          await authViewModel.register(                                       │
│              email: email,                                                   │
│              password: password,                                             │
│              fullName: fullName,                                             │
│              phone: phone.isEmpty ? nil : phone                              │
│          )                                                                   │
│      }                                                                       │
│  }                                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  VIEWMODEL LAYER: AuthViewModel.swift                                        │
│                                                                              │
│  func register(email, password, fullName, phone) async {                     │
│      isLoading = true                                                        │
│      let response = try await authService.register(...)                      │
│      currentUser = response.user                                             │
│      isLoggedIn = true                                                       │
│  }                                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  SERVICE LAYER: AuthService.swift                                            │
│                                                                              │
│  func register(email, password, fullName, phone) async throws {              │
│      let request = RegisterRequest(...)                                      │
│      let response = try await networkManager.request("/auth/register", ...)  │
│      networkManager.setAccessToken(response.accessToken)                     │
│      return response                                                         │
│  }                                                                           │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  NETWORK: POST /api/v1/auth/register                                         │
│                                                                              │
│  Body: { "email": "...", "password": "...", "full_name": "...", "phone": "..."}│
│                                                                              │
│  Response: { "access_token": "jwt...", "user": {...} }                       │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 📍 Step-by-Step Code Flow

### STEP 1: VIEW LAYER - User Taps Sign Up

**File**: `SetAside/Views/Auth/SignUpView.swift`

```swift
struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var fullName: String = ""
    @State private var phone: String = ""
    
    // Form fields and validation...
    
    // Sign Up Button
    PrimaryButton(
        title: "Sign Up",
        isLoading: authViewModel.isLoading
    ) {
        hideKeyboard()
        Task {
            await authViewModel.register(
                email: email,
                password: password,
                fullName: fullName,
                phone: phone.isEmpty ? nil : phone  // Optional phone
            )
        }
    }
    .disabled(!isFormValid)  // Client-side validation
}

// Form validation
var isFormValid: Bool {
    !email.isEmpty &&
    !password.isEmpty &&
    password == confirmPassword &&  // Passwords must match
    !fullName.isEmpty &&
    password.count >= 6  // Minimum password length
}
```

**What happens here:**
1. Form captures: email, password, confirmPassword, fullName, phone
2. Client-side validation ensures fields are filled correctly
3. Phone is made optional (nil if empty)
4. Calls `authViewModel.register()` with all form data

---

### STEP 2: VIEWMODEL LAYER - Call Registration Service

**File**: `SetAside/ViewModels/AuthViewModel.swift` (Lines 55-84)

```swift
func register(email: String, password: String, fullName: String, phone: String?) async {
    isLoading = true          // Show loading spinner
    errorMessage = nil        // Clear previous errors
    showError = false
    
    do {
        let response = try await authService.register(
            email: email,
            password: password,
            fullName: fullName,
            phone: phone
        )
        
        // SUCCESS PATH
        self.currentUser = response.user
        self.isLoading = false
        self.isLoggedIn = true    // Triggers navigation to MainTabView
        
        // Fetch full user profile if not included in response
        if self.currentUser == nil {
            await fetchCurrentUser()
        }
        
    } catch let error as APIError {
        // ERROR PATH
        self.isLoading = false
        self.errorMessage = error.errorDescription
        self.showError = true
    } catch {
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

### STEP 3: SERVICE LAYER - Create Registration Request

**File**: `SetAside/Services/AuthService.swift` (Lines 14-39)

```swift
func register(email: String, password: String, fullName: String, phone: String?) async throws -> AuthResponse {
    // Step 3a: Create request object
    let request = RegisterRequest(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone
    )
    
    #if DEBUG
    print("📝 Registering user: \(email), fullName: \(fullName), phone: \(phone ?? "nil")")
    #endif
    
    // Step 3b: Make API request
    let response: AuthResponse = try await networkManager.request(
        endpoint: "/auth/register",
        method: "POST",
        body: request,
        requiresAuth: false    // Registration doesn't need auth
    )
    
    // Step 3c: Save token for future requests
    networkManager.setAccessToken(response.accessToken)
    UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.isLoggedIn)
    
    return response
}
```

---

### STEP 4: MODEL LAYER - Request Structure with Custom Encoding

**File**: `SetAside/Models/User.swift` (Lines 45-68)

```swift
struct RegisterRequest: Codable {
    let email: String
    let password: String
    let fullName: String
    let phone: String?
    
    enum CodingKeys: String, CodingKey {
        case email
        case password
        case fullName = "full_name"  // Map to snake_case for API
        case phone
    }
    
    // CUSTOM ENCODER - Only include phone if it has a value
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(email, forKey: .email)
        try container.encode(password, forKey: .password)
        try container.encode(fullName, forKey: .fullName)
        
        // Conditional encoding - skip if nil or empty
        if let phone = phone, !phone.isEmpty {
            try container.encode(phone, forKey: .phone)
        }
    }
}
```

**Why custom encode()?**
> The API may reject requests with empty phone fields. Custom encoding ensures we only send `phone` if it has a value, making it truly optional.

**JSON Output (with phone):**
```json
{
    "email": "user@example.com",
    "password": "password123",
    "full_name": "John Doe",
    "phone": "+1234567890"
}
```

**JSON Output (without phone):**
```json
{
    "email": "user@example.com",
    "password": "password123",
    "full_name": "John Doe"
}
```

---

### STEP 5: NETWORK LAYER - HTTP Request

The request flows through `NetworkManager.request()` the same way as login.

**HTTP Request:**
```
POST /api/v1/auth/register HTTP/1.1
Host: setaside.matthewswong.tech
Content-Type: application/json

{
    "email": "newuser@example.com",
    "password": "securepassword",
    "full_name": "New User",
    "phone": "+1234567890"
}
```

**HTTP Response (201 Created):**
```json
{
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "token_type": "bearer",
    "user": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "email": "newuser@example.com",
        "full_name": "New User",
        "phone": "+1234567890",
        "role": "customer",
        "created_at": "2024-12-19T00:00:00Z",
        "updated_at": "2024-12-19T00:00:00Z"
    }
}
```

---

### STEP 6: RETURN PATH - Same as Login

```
NetworkManager returns AuthResponse
       │
       ▼
AuthService saves token + returns AuthResponse
       │
       ▼
AuthViewModel sets:
   • currentUser = response.user
   • isLoggedIn = true  ← TRIGGERS RE-RENDER
       │
       ▼
RootView observes change
       │
       ▼
MainTabView displays (user is now logged in)
```

---

## ❌ Error Handling Flow

### Common Registration Errors

| Error | API Response | User Message |
|-------|--------------|--------------|
| Email already exists | 400: "Email already registered" | "Email already registered" |
| Invalid email format | 400: "Invalid email format" | "Invalid email format" |
| Weak password | 400: "Password too weak" | "Password too weak" |
| Server error | 500: Internal Server Error | "Server error. Please try again later." |

### Error Display in View

```swift
// SignUpView.swift
.alert("Error", isPresented: $showErrorAlert) {
    Button("OK", role: .cancel) { }
} message: {
    Text(errorMessage)
}
.onReceive(authViewModel.$showError) { newValue in
    if newValue {
        errorMessage = authViewModel.errorMessage ?? "An error occurred"
        showErrorAlert = true
        authViewModel.clearError()
    }
}
```

---

## 🔀 Navigation Flow

```
SignInView
    │
    ├── "Sign up here" button
    │
    ▼
SignUpView (via NavigationDestination)
    │
    ├── Success → RootView detects isLoggedIn = true → MainTabView
    │
    └── Cancel/Back → NavigationStack pops → SignInView
```

**File**: `SignInView.swift` (Lines 59-61)
```swift
.navigationDestination(isPresented: $showSignUp) {
    SignUpView()
}
```

---

## 🔐 Form Validation Details

### Client-Side Validation (Before API Call)

```swift
var isFormValid: Bool {
    !email.isEmpty &&
    email.contains("@") &&          // Basic email format check
    !password.isEmpty &&
    password.count >= 6 &&          // Minimum password length
    password == confirmPassword &&  // Passwords match
    !fullName.isEmpty
}
```

### Server-Side Validation (API Response)

The API performs additional validation:
- Email uniqueness check
- Email format validation
- Password strength requirements
- Required field validation

---

## 🗣 What to Say During Exam

> "The registration flow follows the same MVVM pattern as login. The View captures user input through @State properties and validates the form before enabling the submit button. When submitted, it calls the AuthViewModel's register method, which sets loading state and calls the AuthService. The RegisterRequest uses a custom encode() method to conditionally include the optional phone field. On success, the token is saved and isLoggedIn is set to true, which triggers SwiftUI to re-render RootView and navigate to MainTabView."

---

## ❓ Key Points for Exam

### Q: Why use custom encode() for RegisterRequest?
> To conditionally exclude the phone field when it's nil or empty. Some APIs reject empty strings, so custom encoding gives us control over what's sent.

### Q: How is form validation implemented?
> Two levels: Client-side uses computed property `isFormValid` to disable the button. Server-side validation catches additional issues like duplicate emails.

### Q: What's the difference between @State and @Published?
> @State is for View-local state (form fields). @Published is for ViewModel state that needs to trigger View updates across the app.

### Q: Why does registration automatically log the user in?
> The API returns a token on successful registration, so we save it and set isLoggedIn = true. This provides a seamless experience - users don't need to log in separately.

---

## ⏱ Timing Estimates

| Step | Duration |
|------|----------|
| Form validation | ~1ms |
| UI updates (isLoading = true) | ~5ms |
| Network request | ~300-700ms |
| Token save | ~1ms |
| Navigation animation | ~300ms |
| **Total (success path)** | **~600-1000ms** |
