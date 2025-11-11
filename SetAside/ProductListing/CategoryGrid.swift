//
//  CategoryGrid.swift
//  SetAside
//
//  Created by Bryant Aryadi on 11/11/25.
//

import SwiftUI

struct CategoryGrid: View {
    let categories = [
        ("Veggies", "veggies"),
        ("Meat", "meat"),
        ("Snacks", "snacks"),
        ("21+ Products", "21"),
        ("Hygiene Products", "hygiene"),
        ("Homecare", "homecare"),
        ("Electronics", "electronics"),
        ("Others", "others")
    ]

    // 4 columns layout
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(.headline)
                .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(categories, id: \.0) { category in
                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.0)
                                .font(.caption.bold())
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        .padding()
                        
                        VStack {
                            Image(category.1)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 50)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .frame(width: 85, height: 100) // ✅ uniform card size
                    .background(Color(red: 0.82, green: 0.91, blue: 0.82))
                    .cornerRadius(12)
                    
                }
            }
        }
    }
}

#Preview {
    CategoryGrid()
}
