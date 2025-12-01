//
//  SetAsideApp.swift
//  SetAside
//
//  Created by Bryant Aryadi on 11/11/25.
//

import SwiftUI

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
