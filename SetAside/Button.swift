//
//  Button.swift
//  SetAsideApp
//
//  Created by Bryant Aryadi on 24/09/25.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

struct CustomButton: View {
    var title: String
    
    var body: some View {
        Button(action: {
            print("\(title) tapped")
        }) {
            Text(title)
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#618264"))
                .cornerRadius(12)
        }
    }
}

#Preview {
    CustomButton(title: "Sign Up")
        .padding()
}
