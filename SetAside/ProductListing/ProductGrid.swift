//
//  ProductGrid.swift
//  SetAside
//
//  Created by Bryant Aryadi on 11/11/25.
//

import SwiftUI

struct ProductGrid: View {
    let products = Array(repeating: "Fresh Cabbage", count: 6)
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Most Searched")
                    .font(.headline)
                Spacer()
                Button("Show All") {}
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(0..<products.count, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 8) {
                        Image("cabbage")
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)

                        Text("Fresh Cabbage")
                            .font(.headline)
                        Text("$5.00/kg")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Button(action: {}) {
                            Text("ADD TO CART")
                                .font(.footnote)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color("LightGreen"))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
            }
        }
    }
}
