//
//  Columns.swift
//  SetAsideApp
//
//  Created by Bryant Aryadi on 24/09/25.
//

import SwiftUI

struct Columns: View {
    var label: String
    var iconName: String
    
    @State private var text: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                
                TextField(label, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.vertical, 8)
            }
            .padding(.horizontal, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
            )
        }
    }
}

#Preview {
    VStack {
        Columns(label: "Email", iconName: "EmailIcon")
        Columns(label: "Password", iconName: "PasswordIcon")
    }
    .padding()
}
