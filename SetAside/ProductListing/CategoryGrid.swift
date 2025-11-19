//
//  CategoryGrid.swift
//  SetAside
//
//  Created by Bryant Aryadi on 11/11/25.
//

import SwiftUI

struct Category: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
}

struct CategoryGrid: View {
    // Sample data - replace with API data later
    let categories = [
        Category(name: "Fresh Vegetables", imageName: "veggies"),
        Category(name: "Premium Meat", imageName: "meat"),
        Category(name: "Tasty Snacks", imageName: "snacks"),
        Category(name: "21+ Products", imageName: "21"),
        Category(name: "Hygiene Essentials", imageName: "hygiene"),
        Category(name: "Home Care", imageName: "homecare"),
        Category(name: "Electronics", imageName: "electronics"),
        Category(name: "Other Items", imageName: "others")
    ]

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Categories")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(categories) { category in
                    CategoryCard(category: category)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct CategoryCard: View {
    let category: Category
    
    var body: some View {
        VStack(spacing: 0) {
            // Text section
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 4)
            .frame(height: 45, alignment: .top)
            
            Spacer(minLength: 0)
            
            // Image section - bottom right (no gap)
            HStack {
                Spacer()
                Image(category.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 55, height: 55)
            }
        }
        .frame(width: 85, height: 100)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.85, green: 0.93, blue: 0.85),
                    Color(red: 0.82, green: 0.91, blue: 0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    CategoryGrid()
        .padding()
}
