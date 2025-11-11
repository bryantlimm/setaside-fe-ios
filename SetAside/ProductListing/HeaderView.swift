//
//  HeaderView.swift
//  SetAside
//
//  Created by Bryant Aryadi on 11/11/25.
//

import SwiftUI

struct HeaderView: View {
    var username: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello,")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text(username)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            Spacer()
            Button(action: {}) {
                Image("cart")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .background(Color(red: 0, green: 0, blue: 0, opacity: 0.2))
                    .cornerRadius(12)
                    .padding(12)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(red: 0.38, green: 0.51, blue: 0.39))
    }
}

#Preview {
    HeaderView(username: "Name")
}
