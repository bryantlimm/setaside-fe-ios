//
//  BottomNavbar.swift
//  SetAside
//
//  Created by Bryant Aryadi on 11/11/25.
//

import SwiftUI

struct BottomNavBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack {
            Spacer()
            NavBarItem(image: "home", index: 0, selectedTab: $selectedTab)
            Spacer()
            NavBarItem(image: "location", index: 1, selectedTab: $selectedTab)
            Spacer()
            NavBarItem(image: "receipt", index: 2, selectedTab: $selectedTab)
            Spacer()
            NavBarItem(image: "account", index: 3, selectedTab: $selectedTab)
            Spacer()
        }
        .padding(.vertical, 10)
        .background(Color.white.shadow(radius: 2))
    }
}

struct NavBarItem: View {
    let image: String
    let index: Int
    @Binding var selectedTab: Int

    var body: some View {
        Button(action: {
            selectedTab = index
        }) {
            Image(image)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(selectedTab == index ? .white : .gray)
                .padding(12)
                .background(
                    selectedTab == index
                    ? Color(hex: "618264") // ✅ custom green background
                    : Color.clear
                )
                .cornerRadius(12)
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
    }
}

// Helper for hex colors
//extension Color {
//    init(hex: String) {
//        let scanner = Scanner(string: hex)
//        var rgbValue: UInt64 = 0
//        scanner.scanHexInt64(&rgbValue)
//        let r = Double((rgbValue >> 16) & 0xFF) / 255.0
//        let g = Double((rgbValue >> 8) & 0xFF) / 255.0
//        let b = Double(rgbValue & 0xFF) / 255.0
//        self.init(red: r, green: g, blue: b)
//    }
//}

#Preview {
    BottomNavBar(selectedTab: .constant(0))
}
